using System.Text;
using Lucy.AuthService.Contracts;
using Lucy.AuthService.Contracts.Wallet;
using Lucy.AuthService.Data;
using Lucy.AuthService.Data.Wallet;
using Lucy.AuthService.Options;
using Lucy.AuthService.Services;
using Lucy.AuthService.Services.Wallet;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

builder.Services
    .AddOptions<JwtOptions>()
    .Bind(builder.Configuration.GetSection(JwtOptions.SectionName))
    .ValidateDataAnnotations()
    .Validate(options => Encoding.UTF8.GetByteCount(options.Secret) >= 32, "JWT secret must be at least 32 bytes.")
    .ValidateOnStart();

var jwtOptions = builder.Configuration
    .GetSection(JwtOptions.SectionName)
    .Get<JwtOptions>() ?? throw new InvalidOperationException("Missing JWT configuration.");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtOptions.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.Secret)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<IUserRepository, SqlUserRepository>();
builder.Services.AddScoped<IAnonymousRoomRepository, SqlAnonymousRoomRepository>();
builder.Services.AddScoped<IWalletRepository, SqlWalletRepository>();
builder.Services.AddScoped<IWalletTransactionRepository, SqlWalletTransactionRepository>();
builder.Services.AddScoped<IWalletLedgerRepository, SqlWalletLedgerRepository>();
builder.Services.AddScoped<IAuditLogRepository, SqlAuditLogRepository>();
builder.Services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
builder.Services.AddSingleton<IPersonaGenerator, RandomPersonaGenerator>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAnonymousRoomAccessService, AnonymousRoomAccessService>();
builder.Services.AddScoped<IWalletService, WalletService>();

builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (Exception exception)
    {
        var logger = context.RequestServices.GetRequiredService<ILoggerFactory>()
            .CreateLogger("GlobalExceptionAudit");
        logger.LogError(exception, "Unhandled exception while processing {Path}", context.Request.Path);

        try
        {
            var auditLogs = context.RequestServices.GetRequiredService<IAuditLogRepository>();
            await auditLogs.CreateStandaloneAsync(
                "UNHANDLED_EXCEPTION",
                TryGetAuthenticatedUserId(context, out var userId) ? userId : null,
                null,
                "ERROR",
                exception.Message,
                System.Text.Json.JsonSerializer.Serialize(new
                {
                    path = context.Request.Path.Value,
                    method = context.Request.Method,
                    exception = exception.GetType().Name
                }),
                context.Connection.RemoteIpAddress?.ToString(),
                context.Request.Headers.UserAgent.ToString(),
                context.RequestAborted);
        }
        catch (Exception auditException)
        {
            logger.LogError(auditException, "Failed to write unhandled exception audit log.");
        }

        if (!context.Response.HasStarted)
        {
            context.Response.Clear();
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            await context.Response.WriteAsJsonAsync(new { error = "Unexpected server error." });
        }
    }
});

app.UseAuthentication();
app.UseAuthorization();

var auth = app.MapGroup("/api/auth");

auth.MapPost("/login", async (
        LoginRequest request,
        IAuthService authService,
        CancellationToken cancellationToken) =>
    {
        var result = await authService.LoginAsync(request, cancellationToken);
        return result is null
            ? Results.Unauthorized()
            : Results.Ok(result);
    })
    .AllowAnonymous()
    .WithName("Login")
    .Produces<LoginResponse>()
    .Produces(StatusCodes.Status401Unauthorized);

auth.MapPost("/anonymous-room-access", async (
        HttpContext httpContext,
        AnonymousRoomAccessRequest request,
        IAnonymousRoomAccessService anonymousRoomAccessService,
        CancellationToken cancellationToken) =>
    {
        if (string.IsNullOrWhiteSpace(request.ChannelName))
        {
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["channelName"] = ["channelName is required."]
            });
        }

        var userIdClaim = httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
            ?? httpContext.User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;

        if (!int.TryParse(userIdClaim, out var userId))
        {
            return Results.Unauthorized();
        }

        var result = await anonymousRoomAccessService.EnterAnonymousRoomAsync(userId, request, cancellationToken);
        return result.Status switch
        {
            AnonymousRoomAccessStatus.Success => Results.Ok(result.Payload),
            AnonymousRoomAccessStatus.NotAnonymousEligible => Results.Forbid(),
            AnonymousRoomAccessStatus.UserNotFound => Results.NotFound(),
            _ => Results.BadRequest()
        };
    })
    .RequireAuthorization()
    .WithName("AnonymousRoomAccess")
    .Produces<AnonymousRoomAccessResponse>()
    .ProducesValidationProblem()
    .Produces(StatusCodes.Status401Unauthorized)
    .Produces(StatusCodes.Status403Forbidden)
    .Produces(StatusCodes.Status404NotFound);

var wallet = app.MapGroup("/api/wallet")
    .RequireAuthorization();

wallet.MapGet("/balance", async (
        HttpContext httpContext,
        IWalletService walletService,
        CancellationToken cancellationToken) =>
    {
        if (!TryGetAuthenticatedUserId(httpContext, out var userId))
        {
            return Results.Unauthorized();
        }

        var result = await walletService.GetBalanceAsync(userId, cancellationToken);
        return ToHttpResult(result);
    })
    .WithName("GetWalletBalance")
    .Produces<WalletBalanceResponse>()
    .Produces(StatusCodes.Status401Unauthorized)
    .Produces(StatusCodes.Status404NotFound);

wallet.MapPost("/deposit", async (
        HttpContext httpContext,
        DepositRequest request,
        IWalletService walletService,
        CancellationToken cancellationToken) =>
    {
        if (!TryGetAuthenticatedUserId(httpContext, out var userId))
        {
            return Results.Unauthorized();
        }

        var result = await walletService.DepositAsync(
            userId,
            request,
            httpContext.Connection.RemoteIpAddress?.ToString(),
            httpContext.Request.Headers.UserAgent.ToString(),
            cancellationToken);
        return ToHttpResult(result);
    })
    .WithName("DepositWallet")
    .Produces<DepositResponse>()
    .ProducesValidationProblem()
    .Produces(StatusCodes.Status401Unauthorized)
    .Produces(StatusCodes.Status404NotFound)
    .Produces(StatusCodes.Status409Conflict);

wallet.MapPost("/gift", async (
        HttpContext httpContext,
        GiftRequest request,
        IWalletService walletService,
        CancellationToken cancellationToken) =>
    {
        if (!TryGetAuthenticatedUserId(httpContext, out var userId))
        {
            return Results.Unauthorized();
        }

        var result = await walletService.GiftAsync(
            userId,
            request,
            httpContext.Connection.RemoteIpAddress?.ToString(),
            httpContext.Request.Headers.UserAgent.ToString(),
            cancellationToken);
        return ToHttpResult(result);
    })
    .WithName("GiftWallet")
    .Produces<GiftResponse>()
    .ProducesValidationProblem()
    .Produces(StatusCodes.Status401Unauthorized)
    .Produces(StatusCodes.Status402PaymentRequired)
    .Produces(StatusCodes.Status404NotFound)
    .Produces(StatusCodes.Status409Conflict);

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "lucy-auth-service" }))
    .AllowAnonymous();

app.Run();

static bool TryGetAuthenticatedUserId(HttpContext httpContext, out int userId)
{
    var userIdClaim = httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
        ?? httpContext.User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;

    return int.TryParse(userIdClaim, out userId);
}

static IResult ToHttpResult<T>(WalletServiceResult<T> result) =>
    result.Status switch
    {
        WalletServiceStatus.Success => Results.Ok(result.Payload),
        WalletServiceStatus.ValidationError => Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["request"] = [result.ErrorMessage ?? "Invalid wallet request."]
        }),
        WalletServiceStatus.UserNotFound => Results.NotFound(new { error = result.ErrorMessage }),
        WalletServiceStatus.WalletLocked => Results.Conflict(new { error = result.ErrorMessage }),
        WalletServiceStatus.InsufficientFunds => Results.Problem(
            result.ErrorMessage,
            statusCode: StatusCodes.Status402PaymentRequired),
        WalletServiceStatus.Conflict => Results.Conflict(new { error = result.ErrorMessage }),
        _ => Results.BadRequest(new { error = result.ErrorMessage })
    };

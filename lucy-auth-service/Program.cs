using System.Threading.RateLimiting;
using Lucy.AuthService.Contracts;
using Lucy.AuthService.Contracts.Wallet;
using Lucy.AuthService.Data;
using Lucy.AuthService.Data.Wallet;
using Lucy.AuthService.Options;
using Lucy.AuthService.Services;
using Lucy.AuthService.Services.Wallet;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

builder.Services
    .AddOptions<JwtOptions>()
    .Bind(builder.Configuration.GetSection(JwtOptions.SectionName))
    .ValidateDataAnnotations()
    .Validate(options => !string.IsNullOrWhiteSpace(options.RsaPrivateKeyPem)
                         || !string.IsNullOrWhiteSpace(options.RsaPrivateKeyPath),
        "JWT RS256 private key must be configured via RsaPrivateKeyPem or RsaPrivateKeyPath.")
    .ValidateOnStart();

var jwtOptions = builder.Configuration
    .GetSection(JwtOptions.SectionName)
    .Get<JwtOptions>() ?? throw new InvalidOperationException("Missing JWT configuration.");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer();

builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddFixedWindowLimiter("auth", limiter =>
    {
        limiter.PermitLimit = 10;
        limiter.Window = TimeSpan.FromMinutes(1);
        limiter.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiter.QueueLimit = 0;
    });
});
builder.Services.AddHealthChecks();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<IUserRepository, SqlUserRepository>();
builder.Services.AddScoped<IAnonymousRoomRepository, SqlAnonymousRoomRepository>();
builder.Services.AddScoped<IWalletRepository, SqlWalletRepository>();
builder.Services.AddScoped<IWalletTransactionRepository, SqlWalletTransactionRepository>();
builder.Services.AddScoped<IWalletLedgerRepository, SqlWalletLedgerRepository>();
builder.Services.AddScoped<IAuditLogRepository, SqlAuditLogRepository>();
builder.Services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
builder.Services.AddSingleton<IPersonaGenerator, RandomPersonaGenerator>();
builder.Services.AddSingleton<IJwtKeyProvider, RsaJwtKeyProvider>();
builder.Services.AddSingleton<IConfigureOptions<JwtBearerOptions>, ConfigureJwtBearerOptions>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAnonymousRoomAccessService, AnonymousRoomAccessService>();
builder.Services.AddScoped<IWalletService, WalletService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

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
app.UseRateLimiter();

var auth = app.MapGroup("/api/auth")
    .RequireRateLimiting("auth");

auth.MapPost("/register", async (
        RegisterRequest request,
        IAuthService authService,
        CancellationToken cancellationToken) =>
    {
        var result = await authService.RegisterAsync(request, cancellationToken);
        return ToAuthHttpResult(result);
    })
    .AllowAnonymous()
    .WithName("Register")
    .Produces<RegisterResponse>()
    .ProducesValidationProblem()
    .Produces<AuthErrorResponse>(StatusCodes.Status409Conflict);

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

auth.MapGet("/me", async (
        HttpContext httpContext,
        IAuthService authService,
        CancellationToken cancellationToken) =>
    {
        if (!TryGetAuthenticatedUserId(httpContext, out var userId))
        {
            return Results.Unauthorized();
        }

        var result = await authService.GetMeAsync(userId, cancellationToken);
        return ToAuthHttpResult(result);
    })
    .RequireAuthorization()
    .WithName("GetMe")
    .Produces<MeResponse>()
    .Produces(StatusCodes.Status401Unauthorized)
    .Produces<AuthErrorResponse>(StatusCodes.Status404NotFound);

auth.MapPost("/introspect", (
        IntrospectRequest request,
        IJwtKeyProvider keyProvider) =>
    {
        var response = IntrospectToken(request, jwtOptions, keyProvider);
        return Results.Ok(response);
    })
    .AllowAnonymous()
    .WithName("IntrospectToken")
    .Produces<IntrospectResponse>();

auth.MapGet("/.well-known/jwks.json", (IJwtKeyProvider keyProvider) => Results.Ok(new
    {
        keys = new[] { keyProvider.ToJwksKey() }
    }))
    .AllowAnonymous()
    .WithName("GetAuthJwks");

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
        return ToWalletHttpResult(result);
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
        return ToWalletHttpResult(result);
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
        return ToWalletHttpResult(result);
    })
    .WithName("GiftWallet")
    .Produces<GiftResponse>()
    .ProducesValidationProblem()
    .Produces(StatusCodes.Status401Unauthorized)
    .Produces(StatusCodes.Status402PaymentRequired)
    .Produces(StatusCodes.Status404NotFound)
    .Produces(StatusCodes.Status409Conflict);

wallet.MapPost("/sepay-webhook", async (
        HttpContext httpContext,
        SepayWebhookRequest request,
        IWalletService walletService,
        CancellationToken cancellationToken) =>
    {
        // 1. Parse UserId from "Content" (e.g. "LUCY 123" => userId = 123)
        var content = request.Content?.ToUpper() ?? "";
        var match = System.Text.RegularExpressions.Regex.Match(content, @"LUCY\s*(\d+)");
        if (!match.Success)
        {
             return Results.Ok(new { message = "Ignored: Invalid transfer content syntax." });
        }
        var userId = int.Parse(match.Groups[1].Value);

        // 2. Ensure it's a deposit (in)
        if (request.TransferType != "in")
        {
             return Results.Ok(new { message = "Ignored: outgoing transfer" });
        }

        // 3. Calculate coin equivalent (e.g. 1,000 VND = 1 Coin)
        var coins = request.TransferAmount / 1000m;

        // 4. Deposit
        var depositRequest = new DepositRequest(coins, $"SEPAY_{request.Code}", "SEPAY Top-up");
        var result = await walletService.DepositAsync(
            userId, 
            depositRequest, 
            httpContext.Connection.RemoteIpAddress?.ToString(), 
            "SEPAY Webhook", 
            cancellationToken);
        
        return result.Status == WalletServiceStatus.Success 
            ? Results.Ok(new { success = true }) 
            : Results.BadRequest(new { error = "Deposit failed" });
    })
    .AllowAnonymous()
    .WithName("SepayWebhook");

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "lucy-auth-service" }))
    .AllowAnonymous();
app.MapHealthChecks("/healthz")
    .AllowAnonymous();

app.Run();

static bool TryGetAuthenticatedUserId(HttpContext httpContext, out int userId)
{
    var userIdClaim = httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
        ?? httpContext.User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;

    return int.TryParse(userIdClaim, out userId);
}

static IResult ToWalletHttpResult<T>(WalletServiceResult<T> result) =>
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

static IResult ToAuthHttpResult<T>(AuthServiceResult<T> result) =>
    result.Status switch
    {
        AuthServiceStatus.Success => Results.Ok(result.Payload),
        AuthServiceStatus.ValidationError => Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["request"] = [result.ErrorMessage ?? "Invalid auth request."]
        }),
        AuthServiceStatus.DuplicateEmail => Results.Conflict(new AuthErrorResponse(
            result.ErrorMessage ?? "Email is already registered.",
            "AUTH_DUPLICATE_EMAIL")),
        AuthServiceStatus.UserNotFound => Results.NotFound(new AuthErrorResponse(
            result.ErrorMessage ?? "User not found.",
            "AUTH_USER_NOT_FOUND")),
        _ => Results.BadRequest(new AuthErrorResponse(
            result.ErrorMessage ?? "Invalid auth request.",
            "AUTH_BAD_REQUEST"))
    };

static IntrospectResponse IntrospectToken(
    IntrospectRequest request,
    JwtOptions options,
    IJwtKeyProvider keyProvider)
{
    if (string.IsNullOrWhiteSpace(request.Token))
    {
        return new IntrospectResponse(false, null, null, null);
    }

    var handler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
    try
    {
        var principal = handler.ValidateToken(
            request.Token.Trim(),
            JwtTokenValidation.Build(options, keyProvider.ValidationKey, includeRealtimeAudience: true),
            out var validatedToken);

        if (validatedToken is not System.IdentityModel.Tokens.Jwt.JwtSecurityToken jwtToken)
        {
            return new IntrospectResponse(false, null, null, null);
        }

        var claims = principal.Claims
            .GroupBy(claim => claim.Type)
            .ToDictionary(
                group => group.Key,
                group => group.Select(claim => claim.Value).ToArray());

        claims.TryGetValue("token_use", out var tokenUseValues);
        var expiresAt = DateTimeOffset.FromUnixTimeSeconds(long.Parse(
            claims[System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Exp][0]));

        return new IntrospectResponse(
            true,
            tokenUseValues?.FirstOrDefault(),
            expiresAt,
            claims);
    }
    catch
    {
        return new IntrospectResponse(false, null, null, null);
    }
}

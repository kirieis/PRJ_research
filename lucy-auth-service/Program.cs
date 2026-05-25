using System.Text;
using Lucy.AuthService.Contracts;
using Lucy.AuthService.Data;
using Lucy.AuthService.Options;
using Lucy.AuthService.Services;
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
builder.Services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
builder.Services.AddSingleton<IPersonaGenerator, RandomPersonaGenerator>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAnonymousRoomAccessService, AnonymousRoomAccessService>();

builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

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

app.MapGet("/health", () => Results.Ok(new { status = "ok", service = "lucy-auth-service" }))
    .AllowAnonymous();

app.Run();

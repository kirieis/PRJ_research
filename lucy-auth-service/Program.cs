using System.Text;
using Lucy.AuthService.Contracts;
using Lucy.AuthService.Data;
using Lucy.AuthService.Infrastructure;
using Lucy.AuthService.Options;
using Lucy.AuthService.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.OpenApi.Models;
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
            ClockSkew = TimeSpan.FromMinutes(1),
            NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier,
            RoleClaimType = System.Security.Claims.ClaimTypes.Role
        };
        options.Events = new JwtBearerEvents
        {
            OnChallenge = async context =>
            {
                context.HandleResponse();
                await Results.Problem(
                    title: "Unauthorized.",
                    detail: "A valid Bearer token is required.",
                    statusCode: StatusCodes.Status401Unauthorized,
                    extensions: new Dictionary<string, object?> { ["code"] = "AUTH_UNAUTHORIZED" })
                    .ExecuteAsync(context.HttpContext);
            },
            OnForbidden = async context =>
            {
                await Results.Problem(
                    title: "Forbidden.",
                    detail: "The current token is not allowed to access this resource.",
                    statusCode: StatusCodes.Status403Forbidden,
                    extensions: new Dictionary<string, object?> { ["code"] = "AUTH_FORBIDDEN" })
                    .ExecuteAsync(context.HttpContext);
            }
        };
    });

builder.Services.AddAuthorization();
builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<IUserRepository, SqlUserRepository>();
builder.Services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Lucy Auth Service",
        Version = "v1",
        Description = "JWT authentication service for Lucy users."
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Paste a JWT access token. The 'Bearer' prefix is added automatically."
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

app.UseExceptionHandler(exceptionHandlerApp =>
{
    exceptionHandlerApp.Run(async context =>
    {
        var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
        var logger = context.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("GlobalException");
        logger.LogError(exception, "Unhandled exception while processing {Method} {Path}.", context.Request.Method, context.Request.Path);

        await Results.Problem(
            title: "Internal server error.",
            detail: "The server failed to process the request.",
            statusCode: StatusCodes.Status500InternalServerError,
            extensions: new Dictionary<string, object?> { ["code"] = "AUTH_INTERNAL_ERROR" })
            .ExecuteAsync(context);
    });
});

app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "Lucy Auth Service v1");
    options.RoutePrefix = "swagger";
});

app.UseAuthentication();
app.UseAuthorization();

var auth = app.MapGroup("/api/auth");

auth.MapPost("/register", async (
        RegisterRequest request,
        IAuthService authService,
        CancellationToken cancellationToken) =>
    {
        var result = await authService.RegisterAsync(request, cancellationToken);
        return result.Status switch
        {
            RegistrationStatus.Created => Results.Created("/api/auth/me", result.Response),
            RegistrationStatus.InvalidRole => AuthProblem(
                StatusCodes.Status400BadRequest,
                "Invalid role.",
                "Role must be one of: LUCY, Pro, Super.",
                "AUTH_INVALID_ROLE"),
            RegistrationStatus.EmailAlreadyExists => AuthProblem(
                StatusCodes.Status409Conflict,
                "Email already exists.",
                "The email is already registered.",
                "AUTH_EMAIL_EXISTS"),
            _ => AuthProblem(
                StatusCodes.Status500InternalServerError,
                "Registration failed.",
                "The server failed to register this user.",
                "AUTH_REGISTER_FAILED")
        };
    })
    .AllowAnonymous()
    .AddEndpointFilter<ValidationFilter<RegisterRequest>>()
    .WithName("Register")
    .WithSummary("Register a Lucy account and return a JWT access token.")
    .Produces<LoginResponse>(StatusCodes.Status201Created)
    .ProducesValidationProblem()
    .ProducesProblem(StatusCodes.Status400BadRequest)
    .ProducesProblem(StatusCodes.Status409Conflict);

auth.MapPost("/login", async (
        LoginRequest request,
        IAuthService authService,
        CancellationToken cancellationToken) =>
    {
        var result = await authService.LoginAsync(request, cancellationToken);
        return result is null
            ? AuthProblem(
                StatusCodes.Status401Unauthorized,
                "Invalid credentials.",
                "Email or password is incorrect, the account is inactive, or the role is not allowed.",
                "AUTH_INVALID_CREDENTIALS")
            : Results.Ok(result);
    })
    .AllowAnonymous()
    .AddEndpointFilter<ValidationFilter<LoginRequest>>()
    .WithName("Login")
    .WithSummary("Authenticate an existing user and return a JWT access token.")
    .Produces<LoginResponse>()
    .ProducesValidationProblem()
    .ProducesProblem(StatusCodes.Status401Unauthorized);

auth.MapGet("/me", async (
        System.Security.Claims.ClaimsPrincipal principal,
        IAuthService authService,
        CancellationToken cancellationToken) =>
    {
        var user = await authService.GetCurrentUserAsync(principal, cancellationToken);
        return user is null
            ? AuthProblem(
                StatusCodes.Status401Unauthorized,
                "Unauthorized.",
                "The access token does not match an active user.",
                "AUTH_USER_NOT_FOUND")
            : Results.Ok(user);
    })
    .RequireAuthorization()
    .WithName("Me")
    .WithSummary("Return the current authenticated user profile.")
    .Produces<AuthUserResponse>()
    .ProducesProblem(StatusCodes.Status401Unauthorized);

app.MapHealthChecks("/health")
    .AllowAnonymous();

app.MapGet("/health/details", () => Results.Ok(new
    {
        status = "ok",
        service = "lucy-auth-service",
        utcTime = DateTimeOffset.UtcNow
    }))
    .AllowAnonymous();

app.Run();

static IResult AuthProblem(int statusCode, string title, string detail, string code)
{
    return Results.Problem(
        title: title,
        detail: detail,
        statusCode: statusCode,
        extensions: new Dictionary<string, object?> { ["code"] = code });
}

using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.AutoMappings;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Serilog;
using RideSharing.API.Middlewares;
using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;

var builder = WebApplication.CreateBuilder(args);

// Initialize Firebase Admin SDK
try
{
    var firebaseConfigPath = Path.Combine(AppContext.BaseDirectory, "firebase-service-account.json");
    if (File.Exists(firebaseConfigPath))
    {
        FirebaseApp.Create(new AppOptions()
        {
            Credential = GoogleCredential.FromFile(firebaseConfigPath)
        });
        Console.WriteLine("✅ Firebase Admin SDK initialized successfully");
    }
    else
    {
        Console.WriteLine("⚠️ Warning: firebase-service-account.json not found. Firebase phone auth will not work.");
    }
}
catch (Exception ex)
{
    Console.WriteLine($"❌ Error initializing Firebase Admin SDK: {ex.Message}");
}

// Add services to the container.
var logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("logs/ridesharingapi-.log", rollingInterval: RollingInterval.Day)
    .MinimumLevel.Information() // Changed from Error to Information to see startup logs
    .CreateLogger();

builder.Logging.ClearProviders();
builder.Logging.AddSerilog(logger);

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });

// Add CORS - Allow all origins for development
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()  // Allow all origins for development
              .AllowAnyMethod()
              .AllowAnyHeader();
        // Note: AllowCredentials() cannot be used with AllowAnyOrigin()
        // If you need credentials, specify exact origins instead
    });
});

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo { Title = "RideSharing API", Version = "v1" });
    // Add JWT Authentication to Swagger
    options.AddSecurityDefinition(JwtBearerDefaults.AuthenticationScheme, new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = JwtBearerDefaults.AuthenticationScheme,
    });
    options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = JwtBearerDefaults.AuthenticationScheme
                },
                Scheme = "Auth2",
                Name = JwtBearerDefaults.AuthenticationScheme,
                In = Microsoft.OpenApi.Models.ParameterLocation.Header
            },
        new List<string>()
    }
});
});

// Register AutoMapper using the current assembly
builder.Services.AddAutoMapper(typeof(Program).Assembly);

builder.Services.AddDbContext<RideSharingDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("RideSharingConnectionString")));

builder.Services.AddDbContext<RideSharingAuthDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("RideSharingAuthConnectionString")));

// Register repositories for DI
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IAuthRepository, RideSharing.API.Repositories.Implementation.AuthRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IUserRepository, RideSharing.API.Repositories.Implementation.UserRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IRideRepository, RideSharing.API.Repositories.Implementation.RideRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IDriverRepository, RideSharing.API.Repositories.Implementation.DriverRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.INotificationRepository, RideSharing.API.Repositories.Implementation.NotificationRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.ITokenRepository, RideSharing.API.Repositories.Implementation.TokenRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IVehicleModelRepository, RideSharing.API.Repositories.Implementation.VehicleModelRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.ICouponRepository, RideSharing.API.Repositories.CouponRepository>();

// Register services
builder.Services.AddScoped<RideSharing.API.Services.Interface.IOTPService, RideSharing.API.Services.Implementation.OTPService>();
builder.Services.AddScoped<RideSharing.API.Services.Interface.IFileUploadService, RideSharing.API.Services.Implementation.FileUploadService>();
builder.Services.AddScoped<RideSharing.API.Services.Interface.ILocationService, RideSharing.API.Services.Implementation.LocationService>();
builder.Services.AddScoped<RideSharing.API.Services.Interface.ILocationTrackingService, RideSharing.API.Services.Implementation.LocationTrackingService>();
builder.Services.AddScoped<RideSharing.API.Services.Interface.IEmailService, RideSharing.API.Services.Implementation.EmailService>();
builder.Services.AddScoped<RideSharing.API.Services.Interface.IGoogleMapsService, RideSharing.API.Services.Implementation.GoogleMapsService>();

// Register HttpClient for Google Maps API
builder.Services.AddHttpClient("GoogleMaps", client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
    client.DefaultRequestHeaders.Add("User-Agent", "VanYatra-RideSharing");
});

// Register Route Distance Service - now uses database instead of hardcoded data
builder.Services.AddScoped<RideSharing.API.Services.Implementation.RouteDistanceService>();

// Register FCM Notification Service
builder.Services.AddSingleton<RideSharing.API.Services.Notification.FCMNotificationService>();

// Register Background Services
builder.Services.AddHostedService<RideSharing.API.Services.Implementation.RideAutoCancellationService>();
builder.Services.AddHostedService<RideSharing.API.Services.Implementation.BookingNoShowService>();

// Add SignalR
builder.Services.AddSignalR();

// Legacy repositories (keep for backward compatibility)
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IRoutesSchedulesRepository, RideSharing.API.Repositories.Implementation.RoutesSchedulesRepository>();
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IUserDriverRepository, RideSharing.API.Repositories.Implementation.UserDriverRepository>();
// Add Identity
builder.Services.AddIdentityCore<IdentityUser>()
    .AddRoles<IdentityRole>()
    .AddTokenProvider<DataProtectorTokenProvider<IdentityUser>>("RideSharingTokenProvider")
    .AddEntityFrameworkStores<RideSharingAuthDbContext>()
    .AddDefaultTokenProviders();

builder.Services.Configure<IdentityOptions>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
    options.User.RequireUniqueEmail = true;
    options.SignIn.RequireConfirmedEmail = false;
});

// Add Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.Authority = builder.Configuration["JwtSettings:validIssuer"];
    options.Audience = builder.Configuration["JwtSettings:validAudience"];
    options.RequireHttpsMetadata = false;
    var jwtSecret = builder.Configuration["JwtSettings:secretKey"] ?? builder.Configuration["JwtSettings:SecretKey"];
    if (string.IsNullOrWhiteSpace(jwtSecret))
    {
        throw new InvalidOperationException("JWT secret key is not configured. Set configuration key 'JwtSettings:secretKey'.");
    }
    options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["JwtSettings:validIssuer"],
        ValidAudience = builder.Configuration["JwtSettings:validAudience"],
        IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(jwtSecret)),
        // Specify the claim type for roles to match the ClaimsIdentity role claim
        RoleClaimType = System.Security.Claims.ClaimTypes.Role
    };
    // Configure SignalR-specific JWT authentication
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/tracking"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});


var app = builder.Build();

// Configure the HTTP request pipeline.
// Enable Swagger in all environments
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "RideSharing API v1");
    options.RoutePrefix = "swagger"; // Access at /swagger
});

// Automatic migrations disabled - database schema is managed manually via SQL scripts
// The database already has all necessary tables and the __EFMigrationsHistory is pre-populated
// Run automatic database migrations on startup
_ = Task.Run(async () =>
{
    await Task.Delay(2000);
    using (var scope = app.Services.CreateScope())
    {
        try
        {
            var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
            logger.LogInformation("Starting automatic database migrations...");
            
            var authDb = scope.ServiceProvider.GetRequiredService<RideSharingAuthDbContext>();
            // Skip migrations - database is already up to date
            // await authDb.Database.MigrateAsync();
            logger.LogInformation("Auth database migration skipped (already up to date)");
            
            var appDb = scope.ServiceProvider.GetRequiredService<RideSharingDbContext>();
            // Skip migrations - database is already up to date
            // await appDb.Database.MigrateAsync();
            logger.LogInformation("Application database migration skipped (already up to date)");
        }
        catch (Exception ex)
        {
            var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "Database migration failed");
            // Continue anyway - database might already be up to date
        }
    }
});

app.UseMiddleware<ExceptionHandlerMiddleware>();

// Initialize FCM service at startup (force singleton creation)
var fcmService = app.Services.GetRequiredService<RideSharing.API.Services.Notification.FCMNotificationService>();

app.UseCors("AllowAll");

// Enable static files for serving uploaded files
app.UseStaticFiles();

app.UseHttpsRedirection();

app.UseAuthentication(); // <-- must come before UseAuthorization

app.UseAuthorization();

app.MapControllers();

// Map SignalR hub
app.MapHub<RideSharing.API.Hubs.TrackingHub>("/tracking");

app.Run();

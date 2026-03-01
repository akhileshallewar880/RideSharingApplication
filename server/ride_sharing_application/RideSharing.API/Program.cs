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
// Reads Firebase:ServiceAccountKeyPath from config (Azure App Settings or appsettings.json).
// Falls back to firebase-service-account.json in the app directory.
try
{
    var configuredPath = builder.Configuration["Firebase:ServiceAccountKeyPath"] ?? "firebase-service-account.json";
    var firebaseConfigPath = Path.IsPathRooted(configuredPath)
        ? configuredPath
        : Path.Combine(AppContext.BaseDirectory, configuredPath);

    if (File.Exists(firebaseConfigPath) && new FileInfo(firebaseConfigPath).Length > 0)
    {
        FirebaseApp.Create(new AppOptions()
        {
            Credential = GoogleCredential.FromFile(firebaseConfigPath)
        });
        Console.WriteLine("✅ Firebase Admin SDK initialized successfully");
    }
    else
    {
        Console.WriteLine("⚠️ Warning: firebase-service-account.json not found or empty. Push notifications will not work.");
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

// Add CORS - Allow all origins for development and production
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(origin => true) // Allow all origins dynamically
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials(); // Allow credentials (cookies, auth headers)
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
builder.Services.AddScoped<RideSharing.API.Repositories.Interface.IVehicleTypeRepository, RideSharing.API.Repositories.Implementation.VehicleTypeRepository>();
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

// Add SignalR with camelCase JSON serialization so property names like Latitude/Longitude
// are sent as latitude/longitude to match what Flutter clients expect
builder.Services.AddSignalR()
    .AddJsonProtocol(options =>
    {
        options.PayloadSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });

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

// Run automatic database schema creation on startup
_ = Task.Run(async () =>
{
    await Task.Delay(2000);
    using (var scope = app.Services.CreateScope())
    {
        try
        {
            var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
            logger.LogInformation("Starting database schema creation...");
            
            // Get both DbContexts
            var authDb = scope.ServiceProvider.GetRequiredService<RideSharingAuthDbContext>();
            var appDb = scope.ServiceProvider.GetRequiredService<RideSharingDbContext>();
            
            // Create auth database tables if they don't exist
            await authDb.Database.EnsureCreatedAsync();
            logger.LogInformation("Auth database schema created/verified");
            
            // For application database, generate and execute CREATE TABLE scripts individually
            // This handles the case where some tables already exist
            var appDbConnection = appDb.Database.GetDbConnection();
            await appDbConnection.OpenAsync();
            
            try
            {
                // Generate the full script
                var createScript = appDb.Database.GenerateCreateScript();
                logger.LogInformation("Generated application database creation script ({0} characters)", createScript.Length);
                
                // Split by GO statements and execute each batch separately
                var batches = createScript.Split(new[] { "\r\nGO\r\n", "\nGO\n", "\r\nGO", "\nGO" }, StringSplitOptions.RemoveEmptyEntries);
                logger.LogInformation("Executing {0} SQL batches", batches.Length);
                
                int successCount = 0;
                int skipCount = 0;
                
                foreach (var batch in batches)
                {
                    if (string.IsNullOrWhiteSpace(batch)) continue;
                    
                    try
                    {
                        using var command = appDbConnection.CreateCommand();
                        command.CommandText = batch;
                        await command.ExecuteNonQueryAsync();
                        successCount++;
                    }
                    catch (Exception batchEx)
                    {
                        // Skip if table/object already exists
                        if (batchEx.Message.Contains("already an object") || 
                            batchEx.Message.Contains("already exists"))
                        {
                            skipCount++;
                        }
                        else
                        {
                            logger.LogWarning("SQL batch execution warning: {Message}", batchEx.Message);
                        }
                    }
                }
                
                logger.LogInformation("Application database schema creation completed: {0} created, {1} skipped", successCount, skipCount);

                // Apply column additions for schema migrations (ADD COLUMN IF NOT EXISTS)
                var columnMigrations = new[]
                {
                    // AddRouteStopsTimingJsonToRide - 2026-03-01
                    @"IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = 'Rides' AND COLUMN_NAME = 'RouteStopsTimingJson')
                      BEGIN
                          ALTER TABLE Rides ADD RouteStopsTimingJson NVARCHAR(MAX) NULL;
                      END",
                    // AddCityIdFieldsToRide - 2026-03-01
                    @"IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = 'Rides' AND COLUMN_NAME = 'PickupCityId')
                      BEGIN
                          ALTER TABLE Rides ADD PickupCityId UNIQUEIDENTIFIER NULL;
                      END",
                    @"IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = 'Rides' AND COLUMN_NAME = 'DropoffCityId')
                      BEGIN
                          ALTER TABLE Rides ADD DropoffCityId UNIQUEIDENTIFIER NULL;
                      END",
                    @"IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                        WHERE TABLE_NAME = 'Rides' AND COLUMN_NAME = 'IntermediateStopIds')
                      BEGIN
                          ALTER TABLE Rides ADD IntermediateStopIds NVARCHAR(MAX) NULL;
                      END"
                };

                foreach (var colMigration in columnMigrations)
                {
                    try
                    {
                        using var cmd = appDbConnection.CreateCommand();
                        cmd.CommandText = colMigration;
                        await cmd.ExecuteNonQueryAsync();
                    }
                    catch (Exception colEx)
                    {
                        logger.LogWarning("Column migration warning: {Message}", colEx.Message);
                    }
                }

                logger.LogInformation("Column migrations applied");
            }
            catch (Exception scriptEx)
            {
                logger.LogError(scriptEx, "Error during application database schema creation: {Message}", scriptEx.Message);
            }
            finally
            {
                await appDbConnection.CloseAsync();
            }

            // Seed cities if the table is empty
            var citiesSeeder = new RideSharing.API.Seeders.CitiesSeeder(
                appDb,
                scope.ServiceProvider.GetRequiredService<ILogger<RideSharing.API.Seeders.CitiesSeeder>>()
            );
            await citiesSeeder.SeedCitiesAsync();
        }
        catch (Exception ex)
        {
            var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "Database schema creation failed: {Message}", ex.Message);
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

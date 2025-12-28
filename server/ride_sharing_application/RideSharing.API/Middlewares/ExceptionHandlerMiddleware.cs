using System;

namespace RideSharing.API.Middlewares;

public class ExceptionHandlerMiddleware
{
    private readonly ILogger<ExceptionHandlerMiddleware> _logger;
    private readonly RequestDelegate _next;

    public ExceptionHandlerMiddleware(ILogger<ExceptionHandlerMiddleware> logger, RequestDelegate next)
    {
        _logger = logger;
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred.");

            context.Response.StatusCode = 500; // Internal Server Error
            context.Response.ContentType = "application/json";

            var response = new
            {
                Message = "An unexpected error occurred. Please try again later."
            };

            await context.Response.WriteAsJsonAsync(response);
        }
    }
}

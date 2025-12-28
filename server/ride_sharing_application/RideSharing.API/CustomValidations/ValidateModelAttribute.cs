using System;
using Microsoft.AspNetCore.Mvc.Filters;

namespace RideSharing.API.CustomValidations;

public class ValidateModelAttribute : ActionFilterAttribute
{
    public override void OnActionExecuting(ActionExecutingContext context)
    {
        if (!context.ModelState.IsValid)
        {
            context.HttpContext.Response.StatusCode = 400; // Bad Request
            context.Result = new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(context.ModelState);
        }
    }
}

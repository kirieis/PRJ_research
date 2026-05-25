using System.ComponentModel.DataAnnotations;

namespace Lucy.AuthService.Infrastructure;

public sealed class ValidationFilter<TRequest> : IEndpointFilter where TRequest : class
{
    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var request = context.Arguments.OfType<TRequest>().FirstOrDefault();
        if (request is null)
        {
            return await next(context);
        }

        var validationContext = new ValidationContext(request);
        var validationResults = new List<ValidationResult>();
        if (Validator.TryValidateObject(request, validationContext, validationResults, validateAllProperties: true))
        {
            return await next(context);
        }

        var errors = validationResults
            .SelectMany(result => result.MemberNames.DefaultIfEmpty(string.Empty),
                (result, memberName) => new { memberName, result.ErrorMessage })
            .GroupBy(error => ToCamelCase(error.memberName))
            .ToDictionary(
                group => group.Key,
                group => group
                    .Select(error => error.ErrorMessage ?? "Invalid value.")
                    .Distinct()
                    .ToArray());

        return Results.ValidationProblem(
            errors,
            title: "Validation failed.",
            detail: "One or more request fields are invalid.",
            statusCode: StatusCodes.Status400BadRequest);
    }

    private static string ToCamelCase(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        return char.ToLowerInvariant(value[0]) + value[1..];
    }
}

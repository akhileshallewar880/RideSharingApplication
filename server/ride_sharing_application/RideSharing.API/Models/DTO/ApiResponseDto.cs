namespace RideSharing.API.Models.DTO
{
    // Generic API Response
    public class ApiResponseDto<T>
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public T? Data { get; set; }
        public ErrorDto? Error { get; set; }

        public static ApiResponseDto<T> SuccessResponse(T data, string? message = null)
        {
            return new ApiResponseDto<T>
            {
                Success = true,
                Message = message,
                Data = data,
                Error = null
            };
        }

        public static ApiResponseDto<T> ErrorResponse(string message, string code = "ERROR")
        {
            return new ApiResponseDto<T>
            {
                Success = false,
                Message = null,
                Data = default,
                Error = new ErrorDto { Code = code, Message = message }
            };
        }
    }

    public class ApiResponseDto
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public object? Data { get; set; }
        public ErrorDto? Error { get; set; }
    }

    public class ErrorDto
    {
        public string Code { get; set; }
        public string Message { get; set; }
        public Dictionary<string, object>? Details { get; set; }
    }
    
    // Legacy support
    public record ApiResponse<T>(T Data, bool Success = true, string? Error = null);
    public record PagedResult<T>(IEnumerable<T> Items, int Page, int PageSize, long Total);
}

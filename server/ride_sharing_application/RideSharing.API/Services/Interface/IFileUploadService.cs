namespace RideSharing.API.Services.Interface
{
    public interface IFileUploadService
    {
        /// <summary>
        /// Upload a file and return the URL
        /// </summary>
        Task<string> UploadFileAsync(Stream fileStream, string fileName, string folder);

        /// <summary>
        /// Delete a file by URL
        /// </summary>
        Task<bool> DeleteFileAsync(string fileUrl);

        /// <summary>
        /// Validate file type and size
        /// </summary>
        bool ValidateFile(string fileName, long fileSize, string[] allowedExtensions, long maxSizeInBytes);
    }
}

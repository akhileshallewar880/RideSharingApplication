using RideSharing.API.Services.Interface;

namespace RideSharing.API.Services.Implementation
{
    public class FileUploadService : IFileUploadService
    {
        private readonly ILogger<FileUploadService> _logger;
        private readonly IWebHostEnvironment _environment;
        private readonly string _uploadsFolder;

        public FileUploadService(ILogger<FileUploadService> logger, IWebHostEnvironment environment)
        {
            _logger = logger;
            _environment = environment;
            _uploadsFolder = Path.Combine(_environment.ContentRootPath, "uploads");
            
            // Ensure uploads directory exists
            if (!Directory.Exists(_uploadsFolder))
            {
                Directory.CreateDirectory(_uploadsFolder);
            }
        }

        public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string folder)
        {
            try
            {
                // Create subfolder if it doesn't exist
                var targetFolder = Path.Combine(_uploadsFolder, folder);
                if (!Directory.Exists(targetFolder))
                {
                    Directory.CreateDirectory(targetFolder);
                }

                // Generate unique filename
                var fileExtension = Path.GetExtension(fileName);
                var uniqueFileName = $"{Guid.NewGuid()}{fileExtension}";
                var filePath = Path.Combine(targetFolder, uniqueFileName);

                // Save file
                using (var fileStream2 = new FileStream(filePath, FileMode.Create))
                {
                    await fileStream.CopyToAsync(fileStream2);
                }

                // Return relative URL path
                var relativeUrl = $"/uploads/{folder}/{uniqueFileName}";
                _logger.LogInformation($"File uploaded successfully: {relativeUrl}");
                
                return relativeUrl;

                // TODO: For production, use cloud storage (Azure Blob, AWS S3, etc.)
                /*
                // Example for Azure Blob Storage:
                var blobServiceClient = new BlobServiceClient(connectionString);
                var containerClient = blobServiceClient.GetBlobContainerClient(folder);
                await containerClient.CreateIfNotExistsAsync();
                
                var blobClient = containerClient.GetBlobClient(uniqueFileName);
                await blobClient.UploadAsync(fileStream, true);
                
                return blobClient.Uri.ToString();
                */
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to upload file: {fileName}");
                throw;
            }
        }

        public async Task<bool> DeleteFileAsync(string fileUrl)
        {
            try
            {
                if (string.IsNullOrEmpty(fileUrl))
                    return false;

                // Extract relative path from URL
                var relativePath = fileUrl.TrimStart('/');
                var filePath = Path.Combine(_environment.ContentRootPath, relativePath);

                if (File.Exists(filePath))
                {
                    File.Delete(filePath);
                    _logger.LogInformation($"File deleted successfully: {fileUrl}");
                    return true;
                }

                return false;

                // TODO: For production with cloud storage, implement blob deletion
                /*
                // Example for Azure Blob Storage:
                var blobClient = new BlobClient(new Uri(fileUrl));
                await blobClient.DeleteIfExistsAsync();
                return true;
                */
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to delete file: {fileUrl}");
                return false;
            }
        }

        public bool ValidateFile(string fileName, long fileSize, string[] allowedExtensions, long maxSizeInBytes)
        {
            // Check file size
            if (fileSize > maxSizeInBytes)
            {
                _logger.LogWarning($"File size {fileSize} exceeds maximum {maxSizeInBytes}");
                return false;
            }

            // Check file extension
            var fileExtension = Path.GetExtension(fileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(fileExtension))
            {
                _logger.LogWarning($"File extension {fileExtension} not allowed. Allowed: {string.Join(", ", allowedExtensions)}");
                return false;
            }

            return true;
        }
    }
}

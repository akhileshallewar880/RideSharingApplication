# Dockerfile for server directory
# Use official Python image as base (adjust version as needed)
# Use official .NET images
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
# Copy only the project files first for better layer caching
COPY ride_sharing_application/RideSharing.API/*.csproj ./ride_sharing_application/RideSharing.API/
RUN dotnet restore ./ride_sharing_application/RideSharing.API/RideSharing.API.csproj
# Copy the rest of the source code
COPY . .
WORKDIR /src/ride_sharing_application/RideSharing.API
RUN dotnet publish -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=build /app .

# Set working directory
# Expose port (adjust if your app uses a different port)
EXPOSE 80

# Command to run the .NET API (adjust as per your entrypoint DLL)
ENTRYPOINT ["dotnet", "RideSharing.API.dll"]

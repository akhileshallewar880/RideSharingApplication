# Dockerfile for server directory
# Use official Python image as base (adjust version as needed)
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=build /app .

# Set working directory
# Expose port (adjust if your app uses a different port)
EXPOSE 80

# Command to run the .NET API (adjust as per your entrypoint DLL)
ENTRYPOINT ["dotnet", "YourApi.dll"]

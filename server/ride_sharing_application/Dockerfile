# Dockerfile for .NET API
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
# Copy only the project file first for better layer caching
COPY RideSharing.API/*.csproj ./RideSharing.API/
RUN dotnet restore ./RideSharing.API/RideSharing.API.csproj
# Copy the rest of the source code
COPY . .
WORKDIR /src/RideSharing.API
RUN dotnet publish -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=build /app .

EXPOSE 80

ENTRYPOINT ["dotnet", "RideSharing.API.dll"]

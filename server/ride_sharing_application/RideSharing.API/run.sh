#!/bin/bash
cd "$(dirname "$0")"
export ASPNETCORE_ENVIRONMENT=Development
export ASPNETCORE_URLS="http://0.0.0.0:5056"
echo "Starting RideSharing API..."
echo "Working directory: $(pwd)"
echo "Listening on: http://0.0.0.0:5056"
echo "Access from network: http://192.168.88.24:5056"
dotnet bin/Debug/net8.0/RideSharing.API.dll

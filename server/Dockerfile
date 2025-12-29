# Dockerfile for server directory
# Use official Python image as base (adjust version as needed)
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements if present, else fallback to requirements.txt
COPY server/requirements.txt ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt || true

# Copy the rest of the server code
COPY server/ .

# Expose port (adjust if your app uses a different port)
EXPOSE 8000

# Set environment variables (optional)
# ENV VAR_NAME=value

# Command to run the server (adjust as per your entrypoint, e.g., app.py, main.py, etc.)
CMD ["python", "main.py"]

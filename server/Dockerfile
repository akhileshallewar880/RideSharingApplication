# Dockerfile for server directory
# Use official Python image as base (adjust version as needed)
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements.txt
COPY requirements.txt ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt || true

# Copy the rest of the server code
COPY . .

# Expose port (adjust if your app uses a different port)
EXPOSE 8000

# Set environment variables (optional)
# ENV VAR_NAME=value

# Command to run the server (adjust as per your entrypoint, e.g., app.py, main.py, etc.)
CMD ["python", "main.py"]

FROM python:3.10-slim
# Rebuilding to force cache invalidation

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port for the app
EXPOSE 8080

# Command to run the application
CMD ["python", "main.py"]



FROM python:3.10-slim

# Install PostgreSQL development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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



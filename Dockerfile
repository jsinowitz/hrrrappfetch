FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies required for psycopg2 and Python builds
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy project files into the container
COPY . /app

# Upgrade pip
RUN pip install --upgrade pip

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port for the app
EXPOSE 8080

# Command to run the application
CMD ["python", "main.py"]

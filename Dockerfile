FROM python:3.10-slim

# Set working directory
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev python3-dev gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the application code into the container
COPY . /app

# Upgrade pip
RUN pip install --upgrade pip

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt -c constraints.txt

# Expose port for the Flask app
EXPOSE 8080

# Run the application
CMD ["python", "main.py"]


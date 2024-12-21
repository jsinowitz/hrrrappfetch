FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     libpq-dev python3-dev gcc \
#     libgrib-api-dev libeccodes-dev \
#     gdal-bin libgdal-dev && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
    libeccodes-dev gdal-bin libgdal-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy application code
COPY . /app

# Install Python dependencies
COPY requirements.txt /app/requirements.txt
COPY constraints.txt /app/constraints.txt
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt -c constraints.txt

# Expose port and set default command
EXPOSE 8080
CMD ["python", "main.py"]

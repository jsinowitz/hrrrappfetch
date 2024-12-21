# FROM python:3.10-slim

# # Set working directory
# WORKDIR /app

# # Install system dependencies
# # RUN apt-get update && apt-get install -y --no-install-recommends \
# #     libpq-dev python3-dev gcc \
# #     libgrib-api-dev libeccodes-dev \
# #     gdal-bin libgdal-dev && \
# #     apt-get clean && rm -rf /var/lib/apt/lists/*
# RUN apt-get update && apt-get install -y --no-install-recommends \
#     libeccodes-dev gdal-bin libgdal-dev && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# # Copy application code
# COPY . /app

# # Install Python dependencies
# COPY requirements.txt /app/requirements.txt
# COPY constraints.txt /app/constraints.txt
# RUN pip install --upgrade pip && \
#     pip install --no-cache-dir -r requirements.txt -c constraints.txt

# # Expose port and set default command
# EXPOSE 8080
# CMD ["python", "main.py"]
# Use a base image with Python
FROM python:3.10-slim

# Set the working directory inside the container
WORKDIR /app

# Install necessary system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake \
    gfortran \
    libpng-dev \
    libjpeg-dev \
    zlib1g-dev \
    wget \
    build-essential \
    libaec-dev \
    libnetcdf-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install eccodes from source
RUN wget https://confluence.ecmwf.int/download/attachments/45757960/eccodes-2.34.1-Source.tar.gz && \
    tar -xvzf eccodes-2.34.1-Source.tar.gz && \
    cd eccodes-2.34.1-Source && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DENABLE_NETCDF=ON \
          -DENABLE_AEC=ON .. && \
    make -j$(nproc) && \
    make install && \
    cd /app && rm -rf eccodes-2.34.1-Source*

# Copy the requirements file and install Python dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . /app/

# Expose port (if required by your app)
EXPOSE 8080

# Command to run the application
CMD ["python", "app.py"]




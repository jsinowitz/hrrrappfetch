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

# Install eccodes from source step by step for debugging
RUN wget https://confluence.ecmwf.int/download/attachments/45757960/eccodes-2.34.1-Source.tar.gz && \
    tar -xvzf eccodes-2.34.1-Source.tar.gz && \
    cd eccodes-2.34.1-Source && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
          -DENABLE_NETCDF=ON \
          -DENABLE_AEC=ON .. --debug-output && \
    make VERBOSE=1 -j$(nproc)

# Check the build directory
RUN ls -l /app/eccodes-2.34.1-Source/build

# Continue installation
RUN cd /app/eccodes-2.34.1-Source/build && \
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

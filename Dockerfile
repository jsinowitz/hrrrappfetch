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
          -DNetCDF_INCLUDE_DIR=/usr/include \
          -DNetCDF_LIBRARY=/usr/lib/x86_64-linux-gnu/libnetcdf.so \
          -DENABLE_AEC=ON \
          -DAEC_LIBRARY=/usr/lib/x86_64-linux-gnu/libaec.so \
          -DAEC_INCLUDE_DIR=/usr/include/aec .. --debug-output && \
    make VERBOSE=1 -j$(nproc) && \
    make install && \
    cd /app && rm -rf eccodes-2.34.1-Source*

# Copy the requirements file and install Python dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

RUN chmod -R 755 /app
# Copy the application code
COPY . /app/

# Expose port (if required by your app)
EXPOSE 8080

# Command to run the application
CMD ["python", "app.py"]

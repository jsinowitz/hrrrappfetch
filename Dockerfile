# Use an official Python runtime as the base image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Copy all project files to the working directory
COPY . /app

# Install the necessary Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port Flask will listen on (default is 8080 for Cloud Run)
EXPOSE 8080

# Set the command to run the Flask app
CMD ["python", "main.py"]

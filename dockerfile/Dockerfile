# Use the official lightweight Python image based on Alpine Linux
FROM python:3.11-alpine

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set working directory in the container
WORKDIR /app

# Install system dependencies
RUN apk update && apk add --no-cache \
    build-base \
    mariadb-connector-c-dev \
    postgresql-dev \
    linux-headers \
    gcc \
    musl-dev \
    libffi-dev \
    python3-dev

# Install Python dependencies
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy the application files
COPY . /app

# Run create_db.py to set up the database before starting the app
CMD ["python", "create_db.py", "&&", "python", "app.py"]

# Expose the application port
EXPOSE 5000


FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install essential dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Set up Flutter environment variables
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=${FLUTTER_HOME}/bin:${PATH}

# Clone Flutter stable channel
RUN git clone https://github.com/flutter/flutter.git -b stable ${FLUTTER_HOME}

# Pre-download Flutter dependencies
RUN flutter doctor

WORKDIR /app

# Copy pubspec files first to cache flutter pub get
COPY pubspec.* ./
RUN flutter pub get

# Copy the entire app
COPY . .

# Expose the port for the web server
EXPOSE 8080

# Run the Flutter app on a web-server so it can be accessed from the host machine
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "8080"]

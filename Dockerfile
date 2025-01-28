# Stage 1: Build stage
FROM ubuntu:latest AS builder

# Install necessary packages
RUN apt update && \
    apt install -y wget openjdk-11-jdk && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Download and extract Tomcat
ADD https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.97/bin/apache-tomcat-9.0.97.tar.gz /opt/apache-tomcat-9.0.97.tar.gz

# Extract the Tomcat tarball
RUN tar -xvzf /opt/apache-tomcat-9.0.97.tar.gz -C /opt && \
    rm /opt/apache-tomcat-9.0.97.tar.gz  # Remove tarball to save space

# Stage 2: Final stage
FROM openjdk:11-jre-slim

# Set the working directory
WORKDIR /opt/

# Copy Tomcat from the builder stage
COPY --from=builder /opt/apache-tomcat-9.0.97 /opt/apache-tomcat-9.0.97

# Copy the WAR file, MySQL connector JAR, and context.xml to the appropriate directories
#COPY student.war /opt/apache-tomcat-9.0.97/webapps/
COPY mysql-connector.jar /opt/apache-tomcat-9.0.97/lib/
#COPY context.xml /opt/apache-tomcat-9.0.97/conf/context.xml

# Set permissions for Tomcat scripts
RUN chmod +x /opt/apache-tomcat-9.0.97/bin/*.sh

# Expose port 8080
EXPOSE 8080

# Run Tomcat
CMD ["/opt/apache-tomcat-9.0.97/bin/catalina.sh", "run"]

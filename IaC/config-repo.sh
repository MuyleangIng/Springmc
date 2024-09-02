#!/bin/bash

set -e

# Step 1: Create a separate Git repository for configurations
mkdir config-repo
cd config-repo
git init

# Step 2: Add sample configuration files

# application.yml (shared configuration for all services)
cat << EOF > application.yml
eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/

management:
  endpoints:
    web:
      exposure:
        include: '*'
EOF

# test-service.yml (specific configuration for test-service)
cat << EOF > test-service.yml
server:
  port: 8090

spring:
  application:
    name: test-service

message:
  greeting: Hello from Git Config Server
EOF

# test-service-dev.yml (dev profile for test-service)
cat << EOF > test-service-dev.yml
message:
  greeting: Hello from Git Config Server (Dev Environment)
EOF

# test-service-prod.yml (prod profile for test-service)
cat << EOF > test-service-prod.yml
message:
  greeting: Hello from Git Config Server (Prod Environment)
EOF

USERNAME="MuyleangIng"
TOKEN=""
REPO_NAME="your-config-repo"

# Create repository via GitHub API
curl -u $USERNAME:$TOKEN https://api.github.com/user/repos -d "{\"name\":\"$REPO_NAME\", \"private\":false}"

# Initialize Git repository
git init
git add .
git commit -m "Initial config files"

# Add remote repository and push
git remote add origin https://github.com/$USERNAME/$REPO_NAME.git
git branch -M main
git push -u origin main

cd ..

# Step 3: Update Config Server configuration
cat << EOF > config/config-server/application.yml
server:
  port: 8888

spring:
  application:
    name: config-server
  cloud:
    config:
      server:
        git:
          uri: https://github.com/your-username/your-config-repo.git
          default-label: main

eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
EOF

# Step 4: Create a simple test service
mkdir -p src/test-service
cd src/test-service

# Create build.gradle
cat << EOF > build.gradle
plugins {
    id 'org.springframework.boot' version '3.1.0'
    id 'io.spring.dependency-management' version '1.1.0'
    id 'java'
}

group = 'com.example'
version = '0.0.1-SNAPSHOT'
sourceCompatibility = '17'

repositories {
    mavenCentral()
}

ext {
    set('springCloudVersion', "2022.0.3")
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.cloud:spring-cloud-starter-config'
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

dependencyManagement {
    imports {
        mavenBom "org.springframework.cloud:spring-cloud-dependencies:\${springCloudVersion}"
    }
}

tasks.named('test') {
    useJUnitPlatform()
}
EOF

# Create main application class
mkdir -p src/main/java/com/example/testservice
cat << EOF > src/main/java/com/example/testservice/TestServiceApplication.java
package com.example.testservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@EnableDiscoveryClient
@RestController
public class TestServiceApplication {

    @Value("\${message.greeting}")
    private String greeting;

    public static void main(String[] args) {
        SpringApplication.run(TestServiceApplication.class, args);
    }

    @GetMapping("/greeting")
    public String greeting() {
        return greeting;
    }
}
EOF

# Create bootstrap.yml for test-service
mkdir -p src/main/resources
cat << EOF > src/main/resources/bootstrap.yml
spring:
  application:
    name: test-service
  cloud:
    config:
      uri: http://localhost:8888
EOF

cd ../..

echo "Config Server and Test Service have been set up successfully."
echo "Please update the Git repository URL in config/config-server/application.yml"
echo "Build and run the services in this order: Eureka Server, Config Server, Test Service"
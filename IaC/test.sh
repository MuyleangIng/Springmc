#!/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Gradle is installed
if ! command_exists gradle; then
    echo "Gradle is not installed. Please install Gradle before running this script."
    exit 1
fi

# Create project structure
mkdir -p microservices-demo
cd microservices-demo

# Create README.md
cat << EOF > README.md
# Microservices Demo

This project sets up a basic microservices infrastructure using Spring Boot and Spring Cloud.

## Services

1. Eureka Server (Discovery Service)
2. Config Server
3. API Gateway
4. User Service

## Setup

1. Ensure Java 17 and Gradle are installed on your system.
2. Run each service: \`./gradlew bootRun\`

Start the services in this order:
1. Eureka Server
2. Config Server
3. API Gateway
4. User Service

## Testing

To test the setup:

1. Check Eureka Dashboard: http://localhost:8761
2. Test User Service via API Gateway: http://localhost:8080/user-service/users

EOF

# Function to create a basic Spring Boot project
create_project() {
    local project_name=$1
    local main_class=$2
    local dependencies=$3

    mkdir -p "${project_name}"
    cd "${project_name}"

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
    ${dependencies}
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
    mkdir -p src/main/java/com/example/${project_name//-/}
    cat << EOF > src/main/java/com/example/${project_name//-/}/${main_class}.java
package com.example.${project_name//-/};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ${main_class} {
    public static void main(String[] args) {
        SpringApplication.run(${main_class}.class, args);
    }
}
EOF

    mkdir -p src/main/resources
    touch src/main/resources/application.yml

    cd ..
}

# Create Eureka Server
create_project "eureka-server" "EurekaServerApplication" "implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-server'"

# Create Config Server
create_project "config-server" "ConfigServerApplication" "implementation 'org.springframework.cloud:spring-cloud-config-server'
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'"

# Create API Gateway
create_project "api-gateway" "ApiGatewayApplication" "implementation 'org.springframework.cloud:spring-cloud-starter-gateway'
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'"

# Create User Service
create_project "user-service" "UserServiceApplication" "implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.cloud:spring-cloud-starter-netflix-eureka-client'"

# Configure Eureka Server
cat << EOF > eureka-server/src/main/resources/application.yml
server:
  port: 8761

eureka:
  client:
    register-with-eureka: false
    fetch-registry: false

spring:
  application:
    name: eureka-server
EOF

# Configure Config Server
cat << EOF > config-server/src/main/resources/application.yml
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

# Configure API Gateway
cat << EOF > api-gateway/src/main/resources/application.yml
server:
  port: 8080

spring:
  application:
    name: api-gateway
  cloud:
    gateway:
      discovery:
        locator:
          enabled: true
          lower-case-service-id: true

eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
EOF

# Configure User Service
cat << EOF > user-service/src/main/resources/application.yml
server:
  port: 8081

spring:
  application:
    name: user-service

eureka:
  client:
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
EOF

# Update main application classes
sed -i.bak '/@SpringBootApplication/a\
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;\
\
@EnableEurekaServer' eureka-server/src/main/java/com/example/eurekaserver/EurekaServerApplication.java
rm eureka-server/src/main/java/com/example/eurekaserver/EurekaServerApplication.java.bak

sed -i.bak '/@SpringBootApplication/a\
import org.springframework.cloud.config.server.EnableConfigServer;\
\
@EnableConfigServer' config-server/src/main/java/com/example/configserver/ConfigServerApplication.java
rm config-server/src/main/java/com/example/configserver/ConfigServerApplication.java.bak

# Add a simple controller to User Service
cat << EOF > user-service/src/main/java/com/example/userservice/UserController.java
package com.example.userservice;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    @GetMapping("/users")
    public String getUsers() {
        return "List of users";
    }
}
EOF

echo "Microservices infrastructure has been set up successfully."
echo "Please refer to README.md for instructions on how to run and test the services."
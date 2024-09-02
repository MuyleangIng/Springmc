# Microservices Demo

This project sets up a basic microservices infrastructure using Spring Boot and Spring Cloud.

## Services

1. Eureka Server (Discovery Service)
2. Config Server
3. API Gateway
4. User Service

## Setup

1. Ensure Java 17 and Gradle are installed on your system.
2. Run each service: `./gradlew bootRun`

Start the services in this order:
1. Eureka Server
2. Config Server
3. API Gateway
4. User Service

## Testing

To test the setup:

1. Check Eureka Dashboard: http://localhost:8761
2. Test User Service via API Gateway: http://localhost:8080/user-service/users


#!/bin/bash

# Create a new directory for the project
mkdir postgres_docker_setup
cd postgres_docker_setup

# Create docker-compose.yml file
cat << EOF > docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:14
    container_name: postgres-db
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin@123
      POSTGRES_DB: userdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
EOF

# Create init.sql file
cat << EOF > init.sql
CREATE SEQUENCE user_id_seq;

CREATE TABLE users (
    id    bigint DEFAULT nextval('user_id_seq'::regclass) NOT NULL
        CONSTRAINT user_pkey PRIMARY KEY,
    name  varchar(255) NOT NULL,
    email varchar(255) NOT NULL
);

ALTER TABLE users OWNER TO admin;
EOF

# Run Docker Compose
docker-compose up -d

echo "PostgreSQL Docker setup complete. Container is running in the background."
echo "You can connect to the database using:"
echo "Host: localhost"
echo "Port: 5432"
echo "Database: userdb"
echo "Username: admin"
echo "Password: admin@123"
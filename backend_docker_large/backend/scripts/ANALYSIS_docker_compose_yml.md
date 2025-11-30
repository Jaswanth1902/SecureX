# Detailed Analysis: docker-compose.yml

## File Information
- **Path**: `backend/docker-compose.yml`
- **Type**: Docker Orchestration
- **Format**: YAML
- **Version**: 3.8

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This file defines the infrastructure for the application. It uses Docker Compose to define and run multi-container Docker applications. Here, it orchestrates two main services:
1.  **Postgres**: The database server.
2.  **Backend**: The Node.js API server.

It handles networking (allowing the backend to talk to the DB), volumes (persisting database data), and environment configuration.

## Line-by-Line Explanation

**Line 1**: Version
```yaml
version: "3.8"
```
*   **Explanation**: Specifies the version of the Docker Compose file format. Version 3.8 is a modern version that supports advanced features like multi-stage builds and healthchecks.

**Line 3**: Services Block
```yaml
services:
```
*   **Explanation**: Starts the definition of the containers (services) that make up the application.

### Service 1: PostgreSQL

**Line 5**: Service Name
```yaml
  postgres:
```
*   **Explanation**: Defines a service named `postgres`. This name is also used as the hostname for networking.

**Line 6**: Image
```yaml
    image: postgres:15-alpine
```
*   **Explanation**: Uses the official PostgreSQL image from Docker Hub.
    *   `15`: The version of PostgreSQL.
    *   `alpine`: A lightweight Linux distribution, resulting in a smaller image size.

**Line 7**: Container Name
```yaml
    container_name: secure_print_db
```
*   **Explanation**: Assigns a specific name to the container. This makes it easier to find when running `docker ps`.

**Line 8**: Restart Policy
```yaml
    restart: unless-stopped
```
*   **Explanation**: Tells Docker to automatically restart the container if it crashes, unless it was explicitly stopped by the user.

**Line 9-12**: Environment Variables
```yaml
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-secure_print}
```
*   **Explanation**: Configures the PostgreSQL container.
    *   `${VAR:-default}` syntax: This tries to read the value from the host's `.env` file. If not found, it uses the default value (e.g., 'postgres').
    *   These variables tell the container what username, password, and database name to create upon initialization.

**Line 13-14**: Ports
```yaml
    ports:
      - "127.0.0.1:5432:5432"
```
*   **Explanation**: Maps ports from the container to the host.
    *   `127.0.0.1:5432:5432`: Maps port 5432 inside the container to port 5432 on the host's localhost interface.
    *   **Security Note**: Binding to `127.0.0.1` ensures the database is not accessible from the outside internet, only from the host machine.

**Line 15-16**: Volumes
```yaml
    volumes:
      - postgres-data:/var/lib/postgresql/data
```
*   **Explanation**:
    *   Mounts a named volume `postgres-data` to the container's data directory.
    *   **Why**: Containers are ephemeral. If you delete the container, the data inside is lost. Volumes persist the data on the host machine so it survives container restarts/deletions.

**Line 17-21**: Healthcheck
```yaml
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```
*   **Explanation**:
    *   Docker periodically runs this command to check if the database is healthy.
    *   `pg_isready`: A utility command to check the connection status of a PostgreSQL server.
    *   This is crucial for the backend service to know when the database is actually ready to accept connections.

**Line 22-23**: Networks
```yaml
    networks:
      - secure_print_network
```
*   **Explanation**: Connects the container to a custom bridge network.

### Service 2: Backend API

**Line 26**: Service Name
```yaml
  backend:
```
*   **Explanation**: Defines the backend service.

**Line 27-29**: Build Context
```yaml
    build:
      context: .
      dockerfile: Dockerfile
```
*   **Explanation**: Instead of using a pre-built image, this tells Docker to build an image from the source code.
    *   `context: .`: Use the current directory as the build context.
    *   `dockerfile: Dockerfile`: Use the file named `Dockerfile` instructions.

**Line 30**: Container Name
```yaml
    container_name: secure_print_backend
```
*   **Explanation**: Names the container `secure_print_backend`.

**Line 32-33**: Ports
```yaml
    ports:
      - "5000:5000"
```
*   **Explanation**: Maps port 5000 inside the container to port 5000 on the host. This allows you to access the API at `http://localhost:5000`.

**Line 34-61**: Environment Variables
```yaml
    environment:
      # ... (Configuration variables)
      DB_HOST: postgres
      # ...
```
*   **Explanation**: Injects environment variables into the Node.js application.
    *   `DB_HOST: postgres`: This is critical. It tells the backend to connect to the hostname `postgres`. Docker's internal DNS resolves this hostname to the IP address of the postgres container defined above.

**Line 62-64**: Volumes
```yaml
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
```
*   **Explanation**:
    *   Mounts the local `./uploads` directory to `/app/uploads` in the container. This allows uploaded files to persist on the host.
    *   Mounts `./logs` for persistent logging.

**Line 65-67**: Depends On
```yaml
    depends_on:
      postgres:
        condition: service_healthy
```
*   **Explanation**:
    *   Tells Docker to start the `postgres` service before the `backend` service.
    *   `condition: service_healthy`: Waits until the postgres healthcheck passes before starting the backend. This prevents the "Connection Refused" errors that often happen when the app starts faster than the DB.

**Line 68-73**: Healthcheck
```yaml
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:5000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"]
      # ...
```
*   **Explanation**: Runs a small Node.js script to ping the `/health` endpoint. If it returns 200 OK, the container is considered healthy.

### Networks and Volumes

**Line 77-79**: Networks Definition
```yaml
networks:
  secure_print_network:
    driver: bridge
```
*   **Explanation**: Defines the custom network. Using a custom bridge network provides automatic DNS resolution between containers (allowing us to use `postgres` as a hostname).

**Line 81-82**: Volumes Definition
```yaml
volumes:
  postgres-data:
```
*   **Explanation**: Defines the named volume for database persistence. Docker manages the storage location of this volume.

## Summary
This configuration provides a complete, self-contained environment for the application. It ensures that the database and backend are networked correctly, data is persisted, and services start in the correct order.

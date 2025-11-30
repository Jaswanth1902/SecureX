# Detailed Analysis: Dockerfile

## File Information
- **Path**: `backend/Dockerfile`
- **Type**: Docker Build Instructions
- **Base Image**: `node:18-alpine`

## Critical Instruction for AI
> [!IMPORTANT]
> **THIS IS THE MAIN BACKEND PROJECT.**
>
> When working on this project, you MUST prioritize this codebase.
> **DO NOT USE SQLITE.** This project is strictly configured for **PostgreSQL**.
> Any suggestions or code generation must align with the PostgreSQL implementation found here.

## Overview
This Dockerfile defines how to build the production container image for the backend. It uses a **Multi-Stage Build** process. This is a best practice that allows us to use a larger image with all the build tools to compile dependencies, but then copy only the necessary artifacts to a smaller, cleaner runtime image. This results in a smaller, more secure final image.

## Line-by-Line Explanation

### Stage 1: Builder

**Line 3**: Base Image
```dockerfile
FROM node:18-alpine AS builder
```
*   **Explanation**:
    *   `FROM node:18-alpine`: Starts with the official Node.js 18 image based on Alpine Linux. Alpine is extremely lightweight (approx 5MB base).
    *   `AS builder`: Names this stage "builder". We will refer to this name later.

**Line 6**: Working Directory
```dockerfile
WORKDIR /app
```
*   **Explanation**: Sets the current working directory inside the container to `/app`. All subsequent commands run here.

**Line 9**: Copy Package Files
```dockerfile
COPY package*.json ./
```
*   **Explanation**: Copies `package.json` and `package-lock.json` to the container.
    *   **Optimization**: We copy *only* these files first. This allows Docker to cache the "npm install" step. If you change your source code but not your dependencies, Docker will skip the install step and reuse the cache, making builds much faster.

**Line 12**: Install Dependencies
```dockerfile
RUN npm ci --omit=dev && npm cache clean --force
```
*   **Explanation**:
    *   `npm ci`: "Clean Install". It installs dependencies exactly as specified in `package-lock.json`. It is faster and more reliable than `npm install` for CI/CD environments.
    *   `--omit=dev`: Skips installing `devDependencies` (like jest, nodemon). We don't need testing tools in the production image.
    *   `npm cache clean --force`: Removes the npm cache to reduce the image size.

### Stage 2: Production Runtime

**Line 16**: New Base Image
```dockerfile
FROM node:18-alpine AS production
```
*   **Explanation**: Starts a fresh, clean image. This discards all the temporary files and caches from the "builder" stage.

**Line 19**: Working Directory
```dockerfile
WORKDIR /app
```
*   **Explanation**: Sets working directory in the new image.

**Line 22**: Install dumb-init
```dockerfile
RUN apk add --no-cache dumb-init
```
*   **Explanation**: Installs `dumb-init`.
    *   **Why**: Node.js is not designed to run as PID 1 (the first process in a container). It doesn't handle system signals (like SIGTERM) correctly, which can prevent the container from shutting down gracefully. `dumb-init` acts as a lightweight process supervisor that forwards signals to Node.js.

**Line 25-26**: Create User
```dockerfile
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
```
*   **Explanation**: Creates a system group and user named `nodejs`.
    *   **Security**: Running as `root` inside a container is a security risk. If an attacker breaks out of the application, they would have root privileges. Creating a dedicated user limits the blast radius.

**Line 29**: Copy Dependencies
```dockerfile
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
```
*   **Explanation**: This is the magic of multi-stage builds. We copy the `node_modules` folder *from* the "builder" stage *to* the current stage. We also change the ownership to the `nodejs` user.

**Line 32**: Copy Code
```dockerfile
COPY --chown=nodejs:nodejs . .
```
*   **Explanation**: Copies the rest of the application source code to the container.

**Line 35-36**: Create Directories
```dockerfile
RUN mkdir -p uploads logs && \
    chown -R nodejs:nodejs uploads logs
```
*   **Explanation**: Creates directories for file uploads and logs, and ensures the `nodejs` user has permission to write to them.

**Line 39-40**: Environment Variables
```dockerfile
ENV NODE_ENV=production \
    PORT=5000
```
*   **Explanation**: Sets default environment variables. `NODE_ENV=production` tells Node.js and libraries like Express to run in optimized mode (less logging, caching enabled).

**Line 43**: Expose Port
```dockerfile
EXPOSE 5000
```
*   **Explanation**: Documents that the container listens on port 5000.

**Line 46**: Switch User
```dockerfile
USER nodejs
```
*   **Explanation**: Switches the active user to `nodejs`. All subsequent commands run as this non-privileged user.

**Line 49-50**: Healthcheck
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:5000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
```
*   **Explanation**: Defines the health check command. It uses a tiny Node.js script to hit the `/health` endpoint. This avoids needing `curl` or `wget` installed in the image.

**Line 53**: Entrypoint
```dockerfile
ENTRYPOINT ["dumb-init", "--"]
```
*   **Explanation**: Sets `dumb-init` as the entrypoint. It will wrap the command specified in CMD.

**Line 56**: Command
```dockerfile
CMD ["node", "server.js"]
```
*   **Explanation**: The default command to start the application.

## Summary
This Dockerfile produces a production-ready, secure, and optimized image. It follows best practices like multi-stage builds, running as non-root, and handling signals correctly.

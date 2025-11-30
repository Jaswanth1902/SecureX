# Setup and Run Guide

## Prerequisites
- **Node.js**: v18 or higher
- **Docker**: For running the PostgreSQL database
- **PostgreSQL**: (Optional if using Docker) v15 or higher

## Environment Configuration
1. Copy `.env.example` to `.env` in the `backend` directory.
   ```bash
   cp backend/.env.example backend/.env
   ```
2. Update the `.env` file with your specific configuration (if needed).
   - `JWT_SECRET`: Generate a strong random string (min 32 chars).
   - `ENCRYPTION_KEY`: Generate a strong random string (min 32 chars).

## Running with Docker (Recommended)
1. Navigate to the `backend` directory.
   ```bash
   cd backend
   ```
2. Start the services using Docker Compose.
   ```bash
   docker-compose up -d
   ```
   This will start both the PostgreSQL database and the Backend API server.

## Running Locally (Manual)
1. **Start Database**: Ensure you have a PostgreSQL instance running.
   - Update `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD` in `.env` to match your local DB.
2. **Install Dependencies**:
   ```bash
   cd backend
   npm install
   ```
3. **Run Migrations**:
   ```bash
   npm run migrate
   ```
4. **Start Server**:
   ```bash
   npm start
   ```
   The server will start on `http://localhost:5000`.

## API Documentation
Once the server is running, you can access the health check endpoint to verify status:
`GET http://localhost:5000/health`

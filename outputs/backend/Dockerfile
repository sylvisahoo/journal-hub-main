# Use Node.js LTS version
FROM node:20-bookworm-slim AS builder

# Set working directory
WORKDIR /app

# Install build dependencies for native modules (sqlite3, bcrypt)
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Install all dependencies including devDependencies to build native modules
RUN npm ci

# Copy the rest of the source code
COPY . .

# Release stage
FROM node:20-bookworm-slim

WORKDIR /app

# Copy built code and dependencies from builder stage
COPY --from=builder /app /app

# Set production environment (but keep configurations)
ENV NODE_ENV=production
ENV PORT=5001

# Expose port
EXPOSE 5001

# Run the app
CMD ["npm", "start"]

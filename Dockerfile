# Backend Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN pnpm run build

# Verify build output exists
RUN ls -la dist/ && test -f dist/main.js

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --prod --frozen-lockfile

# Copy built application from builder
COPY --from=builder /app/dist ./dist

# Copy necessary config files
COPY --from=builder /app/nest-cli.json ./
COPY --from=builder /app/tsconfig.json ./

# Verify dist/main.js exists in production stage
RUN ls -la dist/ && test -f dist/main.js

# Expose port (Railway will override with its own PORT)
EXPOSE 2005

# Start the application
CMD ["node", "dist/main.js"]

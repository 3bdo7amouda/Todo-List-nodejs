# Use the official Node.js runtime as a parent image
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine

# Install security updates and dumb-init for proper signal handling
RUN apk --no-cache add dumb-init && \
    apk --no-cache upgrade

# Set the working directory in the container
WORKDIR /usr/src/app

# Create a non-root user to run the app
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package.json and package-lock.json (if available)
COPY --chown=nodejs:nodejs package*.json ./

# Switch to nodejs user for npm install
USER nodejs

# Install app dependencies with exact versions for reproducible builds
RUN npm ci --only=production && \
    npm cache clean --force

# Copy the rest of the application code
COPY --chown=nodejs:nodejs . .

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js || exit 1

# Expose the port the app runs on
EXPOSE 4000

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Define the command to run the application
CMD ["npm", "start"]
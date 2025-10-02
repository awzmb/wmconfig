FROM node:24-alpine AS builder

WORKDIR /app

# Install gemini-cli using npm. This installs it and all its
# dependencies into /app/node_modules
RUN npm install @google/gemini-cli@v0.6.1


FROM gcr.io/distroless/nodejs24-debian12

# Set the working directory
WORKDIR /app

# Copy the installed node_modules (which includes gemini-cli
# and all its dependencies) from the builder stage.
COPY --from=builder /app/node_modules ./node_modules

# The distroless nodejs image has its ENTRYPOINT set to ["/usr/bin/node"].
# We just need to provide the path to the main JavaScript file as the CMD.
# This file is the actual script that the 'gemini' command executes.
CMD ["/app/node_modules/@google/gemini-cli/dist/index.js"]

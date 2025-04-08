FROM cgr.dev/chainguard/node:latest AS build

WORKDIR /app

RUN npm install @dwmkerr/terminal-ai

FROM gcr.io/distroless/nodejs22-debian12

COPY --from=build /app /app
CMD ["/app/node_modules/.bin/ai"]

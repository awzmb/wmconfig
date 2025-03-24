# builder
FROM cgr.dev/chainguard/rust as build

RUN cargo install aichat

# runtime
FROM gcr.io/distroless/cc

COPY --from=build /usr/local/cargo/bin/aichat /bin/aichat

CMD ["aichat"]

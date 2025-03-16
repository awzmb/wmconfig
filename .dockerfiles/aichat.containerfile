# builder
FROM docker.io/library/rust as build

RUN cargo install aichat

# runtime
FROM gcr.io/distroless/cc

COPY --from=build /usr/local/cargo/bin/aichat /bin/aichat

CMD ["aichat"]

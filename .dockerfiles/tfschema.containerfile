FROM docker.io/golang:latest AS build

RUN git clone https://github.com/minamijoyo/tfschema.git /go/src/tfschema

WORKDIR /go/src/tfschema

RUN go clean --testcache && go test

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/tfschema main.go

FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/tfschema /usr/local/bin/tfschema

ENTRYPOINT ["/usr/local/bin/tfschema"]

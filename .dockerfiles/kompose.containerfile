FROM docker.io/golang:latest AS build

RUN git clone https://github.com/kubernetes/kompose.git /go/src/kompose

WORKDIR /go/src/kompose

RUN go clean --testcache && go test

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/kompose main.go

#FROM gcr.io/distroless/static-debian12

#COPY --from=build /go/bin/kompose /usr/local/bin

#ENTRYPOINT ["/usr/local/bin/kompose"]
ENTRYPOINT ["/go/bin/kompose"]

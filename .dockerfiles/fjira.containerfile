FROM docker.io/golang:latest AS build

RUN git clone https://github.com/mk-5/fjira.git /go/src/fjira

WORKDIR /go/src/fjira

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/fjira cmd/fjira-cli/main.go

FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/fjira /usr/local/bin/fjira

ENTRYPOINT ["/usr/local/bin/fjira"]
#ENTRYPOINT ["/go/bin/fjira"]

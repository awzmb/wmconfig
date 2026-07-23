FROM docker.io/golang:1.26.5-trixie@sha256:4ee9ffa999b4583ce281939cdff828763083610292f252279a0cee77473bd9a7 AS build

RUN git clone https://github.com/mk-5/fjira.git /go/src/fjira

WORKDIR /go/src/fjira

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/fjira cmd/fjira-cli/main.go

FROM gcr.io/distroless/static-debian13:latest@sha256:9197324ba51d9cd071af8505989365c006adf9d6d2067eada25aef00abbb5278

COPY --from=build /go/bin/fjira /usr/local/bin/fjira

ENTRYPOINT ["/usr/local/bin/fjira"]

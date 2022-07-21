FROM golang:1.18.3-alpine3.16 AS base

RUN apk add --no-cache git

WORKDIR /tmp/sample-k8s-app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

RUN go build -o ./out/sample-k8s-app .


FROM alpine:3.16

RUN apk add ca-certificates

COPY --from=base /tmp/sample-k8s-app/out/sample-k8s-app /app/sample-k8s-app
COPY --from=base /tmp/sample-k8s-app/main.html /app/main.html

EXPOSE 8080

ENTRYPOINT [ "/app/sample-k8s-app" ]
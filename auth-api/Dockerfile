# Build stage
FROM golang:1.12-alpine AS builder

# Install git & build tools
RUN apk add --no-cache git build-base

# Install dep
RUN go get -u github.com/golang/dep/cmd/dep

# Set Go env
ENV GOPATH=/go
WORKDIR /go/src/github.com/elgris/todos-api

# Copy dependency files first (para aprovechar la cache)
COPY Gopkg.toml Gopkg.lock ./

# Download dependencies
RUN dep ensure -vendor-only

# Copy the rest of the source code
COPY . .

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

#========================== Runtime ==========================#
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /go/src/github.com/elgris/todos-api/main .

EXPOSE 8000

# Env vars (mejor pasarlas al docker run en prod)
ENV AUTH_API_PORT=8000
ENV JWT_SECRET=myfancysecret

CMD ["./main"]

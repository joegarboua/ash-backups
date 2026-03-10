# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o agentyk ./

# Runtime stage
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app
COPY --from=builder /build/agentyk .
COPY --from=builder /build/web/templates ./web/templates
COPY --from=builder /build/web/static ./web/static

ENV PORT=8000
ENV TEMPLATE_DIR=/app/web/templates

EXPOSE 8000

CMD ["./agentyk"]

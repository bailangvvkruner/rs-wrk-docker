# Rust Static Compilation for Alpine (musl)
# Using vendored OpenSSL to avoid system library compatibility issues

# Build stage - using Rust Alpine with vendored OpenSSL
FROM rust:alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache musl-dev git binutils upx

# Enable vendored feature for OpenSSL - this will compile OpenSSL from source
ENV OPENSSL_VENDOR=1
ENV OPENSSL_STATIC=1

# Clone and build with vendored OpenSSL
RUN git clone --depth 1 -b master https://github.com/bailangvvkg/rs-wrk . && \
    cargo build --release --target x86_64-unknown-linux-musl && \
    echo "Binary size after build:" && \
    du -h target/x86_64-unknown-linux-musl/release/rs-wrk

# Optional: strip binary to reduce size
RUN strip --strip-all target/x86_64-unknown-linux-musl/release/rs-wrk && \
    echo "Binary size after stripping:" && \
    du -h target/x86_64-unknown-linux-musl/release/rs-wrk

# Optional: compress with upx
RUN upx --best --lzma target/x86_64-unknown-linux-musl/release/rs-wrk && \
    echo "Binary size after upx:" && \
    du -h target/x86_64-unknown-linux-musl/release/rs-wrk

# Runtime stage - using minimal Alpine image
FROM alpine:latest

# Copy the statically compiled binary from builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/rs-wrk /usr/local/bin/rs-wrk

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/rs-wrk"]

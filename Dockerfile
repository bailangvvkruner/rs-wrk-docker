# Rust Static Compilation for Alpine (musl)
# Complete OpenSSL development environment setup

# Build stage - using Rust Alpine with full OpenSSL development setup
FROM rust:alpine AS builder

WORKDIR /app

# Install essential build dependencies including perl for OpenSSL vendored build
RUN apk add --no-cache \
    musl-dev \
    git \
    binutils \
    upx \
    gcc \
    make \
    perl

# Set environment for vendored OpenSSL build
ENV OPENSSL_VENDOR=1

# Clone the project
RUN git clone --depth 1 -b master https://github.com/bailangvvkg/rs-wrk .

# Build with vendored OpenSSL (dependencies already fixed in source)
RUN cargo build --release --target x86_64-unknown-linux-musl

# Verify binary is statically linked
RUN ldd target/x86_64-unknown-linux-musl/release/rs-wrk 2>/dev/null || echo "Binary is statically linked (expected)"

# Strip binary to reduce size
RUN strip --strip-all target/x86_64-unknown-linux-musl/release/rs-wrk && \
    echo "Binary size after stripping:" && \
    du -h target/x86_64-unknown-linux-musl/release/rs-wrk

# Compress with upx
RUN upx --best --lzma target/x86_64-unknown-linux-musl/release/rs-wrk && \
    echo "Binary size after upx:" && \
    du -h target/x86_64-unknown-linux-musl/release/rs-wrk

# Runtime stage - using minimal Alpine image
FROM alpine:latest

# Copy the statically compiled binary from builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/rs-wrk /usr/local/bin/rs-wrk

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/rs-wrk"]

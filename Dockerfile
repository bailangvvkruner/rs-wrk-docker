# Rust Static Compilation using cross-rs for reliable musl builds
# cross-rs handles OpenSSL and other C library dependencies automatically

# Build stage - using cross-rs for reliable static compilation
FROM rust:alpine AS builder

# Install cross tool and dependencies
RUN apk add --no-cache musl-dev git openssl-dev openssl-libs-static
RUN cargo install cross

WORKDIR /app

# Clone the project
RUN git clone --depth 1 -b master https://github.com/bailangvvkg/rs-wrk .

# Build with cross - it will use a pre-configured Docker image for musl target
# cross handles all OpenSSL and C library compatibility issues
RUN cross build --release --target x86_64-unknown-linux-musl

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

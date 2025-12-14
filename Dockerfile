# Rust Static Compilation for Alpine (musl)
# Using specialized muslrust image for static compilation

# Build stage - using muslrust image specifically designed for static compilation
FROM clux/muslrust:stable AS builder

WORKDIR /app

# Clone and build the project (this image handles OpenSSL and other C library compatibility)
RUN git clone --depth 1 -b master https://github.com/bailangvvkg/rs-wrk .

# Build static binary for musl target
RUN cargo build --release --target x86_64-unknown-linux-musl

# Optional: strip binary to reduce size
RUN strip --strip-all /app/target/x86_64-unknown-linux-musl/release/rs-wrk

# Runtime stage - using minimal Alpine image
FROM alpine:latest

# Copy the statically compiled binary from builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/rs-wrk /usr/local/bin/rs-wrk

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/rs-wrk"]

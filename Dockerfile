# Rust Static Compilation for Alpine (musl)
# Using a proven builder image that already has OpenSSL properly configured

# Build stage - using a proven Rust+musl builder image
FROM messense/rust-musl-cross:x86_64-musl AS builder

WORKDIR /app

# Clone the project
RUN git clone --depth 1 -b master https://github.com/bailangvvkg/rs-wrk .

# Build static binary (this image already has OpenSSL properly configured for musl)
RUN cargo build --release

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

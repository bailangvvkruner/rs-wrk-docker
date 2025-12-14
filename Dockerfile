# Rust Static Compilation Docker Build
# 使用 Rust 编译静态二进制文件

# 构建阶段 - 使用 Rust Alpine 环境
FROM rust:alpine AS builder

WORKDIR /app

# 安装 musl target 和 OpenSSL 开发包（用于静态编译）
RUN set -eux && apk add --no-cache --no-scripts --virtual .build-deps \
    musl-dev \
    openssl-dev \
    openssl-libs-static \
    git \
    binutils \
    upx \
    && rustup target add x86_64-unknown-linux-musl

# 克隆仓库并构建（设置 OpenSSL 相关环境变量）
RUN git clone --depth 1 -b master https://github.com/bailangvvkg/rs-wrk . \
    && OPENSSL_STATIC=1 OPENSSL_LIB_DIR=/usr/lib OPENSSL_INCLUDE_DIR=/usr/include \
       cargo build --release --target x86_64-unknown-linux-musl \
    && echo "Binary size after build:" \
    && du -b target/x86_64-unknown-linux-musl/release/rs-wrk \
    && strip --strip-all target/x86_64-unknown-linux-musl/release/rs-wrk \
    && echo "Binary size after stripping:" \
    && du -b target/x86_64-unknown-linux-musl/release/rs-wrk \
    && upx --best --lzma target/x86_64-unknown-linux-musl/release/rs-wrk \
    && echo "Binary size after upx:" \
    && du -b target/x86_64-unknown-linux-musl/release/rs-wrk
# 运行时阶段 - 使用busybox:musl（极小的基础镜像，包含基本shell）
# FROM busybox:musl
# FROM alpine:latest
FROM scratch AS pod
# FROM hectorm/scratch:latest AS pod


# 复制CA证书（用于HTTPS请求）
# COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# 复制 rs-wrk 二进制文件
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/rs-wrk /rs-wrk

# 设置入口点
ENTRYPOINT ["/rs-wrk"]

# Rust Docker Build - 使用标准 glibc 目标以确保兼容性
# 使用 Rust 编译二进制文件

# 构建阶段 - 使用 Rust Alpine 环境
FROM rust:alpine AS builder

WORKDIR /app

# 安装构建依赖（包含 openssl-dev 以解决 OpenSSL 编译问题）
RUN set -eux && apk add --no-cache --no-scripts --virtual .build-deps \
    git \
    binutils \
    upx \
    openssl-dev

# 克隆仓库并构建（为 openssl-sys 明确指定库路径）
RUN git clone --depth 1 -b master https://github.com/bailangvvkg/rs-wrk . \
    && OPENSSL_DIR=/usr \
       OPENSSL_LIB_DIR=/usr/lib \
       OPENSSL_INCLUDE_DIR=/usr/include \
       cargo build --release \
    && echo "Binary size after build:" \
    && du -b target/release/rs-wrk \
    && strip --strip-all target/release/rs-wrk \
    && echo "Binary size after stripping:" \
    && du -b target/release/rs-wrk \
    && upx --best --lzma target/release/rs-wrk \
    && echo "Binary size after upx:" \
    && du -b target/release/rs-wrk

# 运行时阶段 - 使用 Alpine 作为基础镜像
FROM alpine:latest

# 复制 rs-wrk 二进制文件
COPY --from=builder /app/target/release/rs-wrk /usr/local/bin/rs-wrk

# 设置入口点
ENTRYPOINT ["/usr/local/bin/rs-wrk"]

FROM oraclelinux:9

ARG GRAALPY_VERSION=25.0.2
ARG TARGETARCH

# 依赖一次装完 + 清理缓存
RUN dnf install -y oraclelinux-developer-release-el9 && \
    dnf install -y \
      curl ca-certificates \
      libffi-devel boost-devel snappy-devel brotli-devel openssl-devel thrift-devel \
      llvm llvm-libs llvm-devel \
      lld lld-devel \
      clang clang-libs clang-devel \
      gcc gcc-c++ make cmake patch \
    && dnf clean all

# 下载并解压 GraalPy（按架构选择）
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64)  GRAALPY_ARCH="amd64" ;; \
      arm64)  GRAALPY_ARCH="aarch64" ;; \
      *) echo "Unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -L "https://github.com/oracle/graalpython/releases/download/graal-${GRAALPY_VERSION}/graalpy-${GRAALPY_VERSION}-linux-${GRAALPY_ARCH}.tar.gz" \
      | tar -xz -C /opt; \
    ln -s "/opt/graalpy-${GRAALPY_VERSION}-linux-${GRAALPY_ARCH}" /opt/graalpy

ENV GRAALPY_HOME=/opt/graalpy
ENV PATH="${GRAALPY_HOME}/bin:${PATH}"

RUN graalpy -m ensurepip

# 你之前用了 MAKEFLAGS="-j1" 避免 OOM/并发问题，这里保留
RUN graalpy -m pip install -U pip && \
    graalpy -m pip install numpy==2.2.4 pandas==2.2.3 -v
RUN graalpy -m pip install pyarrow==20.0.0 -v

CMD ["graalpy", "--version"]

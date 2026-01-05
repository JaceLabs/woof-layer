# Woof Layer 区块链节点 - Railway 部署版本
# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PORT=8545

# 安装必要的系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 Geth - 使用多个备用源
RUN set -ex && \
    cd /tmp && \
    # 尝试从 GitHub releases 下载（更稳定）
    wget -q -O geth.tar.gz https://github.com/ethereum/go-ethereum/releases/download/v1.13.14/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz || \
    # 如果 GitHub 失败，尝试官方源
    wget -q -O geth.tar.gz https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz || \
    # 如果都失败，使用 curl 重试
    (curl -L -o geth.tar.gz https://github.com/ethereum/go-ethereum/releases/download/v1.13.14/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz && true) && \
    tar -xzf geth.tar.gz && \
    mv geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/ && \
    rm -rf geth-* && \
    geth version

# 创建工作目录
WORKDIR /woof-layer

# 复制 genesis.json
COPY genesis.json /woof-layer/

# 创建数据目录
RUN mkdir -p /woof-layer/data

# 初始化创世块
RUN geth --datadir /woof-layer/data init /woof-layer/genesis.json

# 暴露 RPC 端口
EXPOSE 8545

# 启动 Geth 节点
CMD ["geth", \
     "--datadir", "/woof-layer/data", \
     "--http", \
     "--http.addr", "0.0.0.0", \
     "--http.port", "8545", \
     "--http.api", "eth,net,web3,personal", \
     "--http.vhosts", "*", \
     "--http.corsdomain", "*", \
     "--networkid", "88188", \
     "--verbosity", "3", \
     "--mine", \
     "--miner.threads", "1"]

# Woof Layer 区块链节点 - Railway 部署版本
# 使用官方 Ubuntu 镜像
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/usr/local/bin:$PATH" \
    GETH_DATA_DIR="/data"

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# 创建工作目录
WORKDIR /app

# 复制 genesis.json（重要：必须在这里复制）
COPY genesis.json /app/genesis.json

# 下载并安装 Geth
RUN set -ex && \
    echo "Downloading Geth..." && \
    # 尝试从 GitHub releases 下载
    wget -q -O /tmp/geth.tar.gz \
      https://github.com/ethereum/go-ethereum/releases/download/v1.13.14/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz && \
    echo "Extracting Geth..." && \
    tar -xzf /tmp/geth.tar.gz -C /tmp && \
    mv /tmp/geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/ && \
    rm -rf /tmp/geth* && \
    echo "Verifying Geth installation..." && \
    geth version

# 创建数据目录
RUN mkdir -p ${GETH_DATA_DIR}

# 初始化创世块
RUN echo "Initializing genesis block..." && \
    geth --datadir ${GETH_DATA_DIR} init /app/genesis.json && \
    echo "Genesis block initialized successfully"

# 暴露 RPC 端口
EXPOSE 8545

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8545 -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' || exit 1

# 启动脚本
CMD ["geth", \
     "--datadir", "/data", \
     "--http", \
     "--http.addr", "0.0.0.0", \
     "--http.port", "8545", \
     "--http.api", "eth,net,web3,personal,admin", \
     "--http.vhosts", "*", \
     "--http.corsdomain", "*", \
     "--networkid", "88188", \
     "--verbosity", "3", \
     "--mine", \
     "--miner.threads", "1", \
     "--allow-insecure-unlock"]

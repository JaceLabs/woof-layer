# Woof Layer 区块链节点 - Railway 部署版本
# 使用 Alpine 作为基础镜像，最小化镜像大小

FROM alpine:latest

# 安装必要的工具
RUN apk add --no-cache \
    ca-certificates \
    curl \
    wget \
    bash \
    git

# 创建工作目录
WORKDIR /app

# 复制 genesis.json
COPY genesis.json /app/genesis.json

# 创建数据目录
RUN mkdir -p /data

# 下载 Geth - 使用多个备用源和重试机制
RUN set -ex && \
    echo "Attempting to download Geth v1.13.14..." && \
    # 方式 1: 尝试从 GitHub releases 下载
    (wget -q -O /tmp/geth.tar.gz https://github.com/ethereum/go-ethereum/releases/download/v1.13.14/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz && \
     tar -xzf /tmp/geth.tar.gz -C /tmp && \
     mv /tmp/geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/ && \
     rm -rf /tmp/geth*) || \
    # 方式 2: 如果失败，使用 curl 重试
    (curl -L -o /tmp/geth.tar.gz https://github.com/ethereum/go-ethereum/releases/download/v1.13.14/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz && \
     tar -xzf /tmp/geth.tar.gz -C /tmp && \
     mv /tmp/geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/ && \
     rm -rf /tmp/geth*) || \
    # 方式 3: 如果都失败，从官方源下载
    (wget -q -O /tmp/geth.tar.gz https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz && \
     tar -xzf /tmp/geth.tar.gz -C /tmp && \
     mv /tmp/geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/ && \
     rm -rf /tmp/geth*) || \
    # 方式 4: 最后的手段 - 使用 curl 从官方源
    (curl -L -o /tmp/geth.tar.gz https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.14-2bd6bd01.tar.gz && \
     tar -xzf /tmp/geth.tar.gz -C /tmp && \
     mv /tmp/geth-linux-amd64-1.13.14-2bd6bd01/geth /usr/local/bin/ && \
     rm -rf /tmp/geth*)

# 验证 Geth 安装
RUN echo "Verifying Geth installation..." && \
    geth version && \
    which geth

# 初始化创世块
RUN echo "Initializing genesis block..." && \
    geth --datadir /data init /app/genesis.json && \
    echo "Genesis block initialized successfully"

# 暴露 RPC 端口
EXPOSE 8545

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8545 -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' || exit 1

# 启动 Geth 节点
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

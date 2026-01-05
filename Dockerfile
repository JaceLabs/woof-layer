# Woof Layer 区块链节点 - Railway 部署版本
# 使用多阶段构建：第一阶段编译 Geth，第二阶段运行节点

# ============================================================================
# 第一阶段：编译 Geth
# ============================================================================
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git make gcc musl-dev linux-headers

WORKDIR /go/src

# 克隆 Geth 仓库并编译
RUN git clone --depth 1 --branch v1.13.14 https://github.com/ethereum/go-ethereum.git && \
    cd go-ethereum && \
    make geth && \
    cp build/bin/geth /geth

# ============================================================================
# 第二阶段：运行时镜像
# ============================================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/usr/local/bin:$PATH" \
    GETH_DATA_DIR="/data"

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# 从第一阶段复制编译好的 Geth
COPY --from=builder /geth /usr/local/bin/geth

# 验证 Geth 安装
RUN geth version

# 创建工作目录
WORKDIR /app

# 复制 genesis.json
COPY genesis.json /app/genesis.json

# 创建数据目录
RUN mkdir -p ${GETH_DATA_DIR}

# 初始化创世块
RUN geth --datadir ${GETH_DATA_DIR} init /app/genesis.json

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

#!/bin/bash

# Woof Layer 主网节点启动脚本

# 节点数据目录
DATADIR="./woof_node/data"
# 创世文件路径
GENESIS_FILE="./genesis.json"
# 节点账户地址 (矿工/受益人地址)
MINER_ADDRESS="YOUR_ADDRESS_HERE"
# 账户密码文件路径
PASSWORD_FILE="./woof_node/password.txt"
# 网络ID
NETWORK_ID=88188
# RPC 端口
RPC_PORT=8545
# Gas Price (0.2 Gwei)
GAS_PRICE="200000000"
# 日志文件
LOG_FILE="./woof_node/node.log"

# 检查 geth 是否已安装
if ! command -v geth &> /dev/null
then
    echo "geth 未找到，请确保 geth 已安装并添加到 PATH。"
    exit 1
fi

# 检查数据目录是否存在，如果不存在则进行初始化
if [ ! -d "$DATADIR" ]; then
    echo "数据目录 $DATADIR 不存在，正在初始化..."
    mkdir -p "$DATADIR"
    geth --datadir "$DATADIR" init "$GENESIS_FILE"
    echo "初始化完成。请确保您的账户私钥已导入到 $DATADIR/keystore 目录下。"
fi

echo "正在启动 Woof Layer 节点..."

# 启动 Geth 节点
# --nodiscover --maxpeers 0: 确保节点不会连接到以太坊主网或测试网，只在本地运行
# --mine: 开启挖矿
# --miner.etherbase: 设置挖矿收益地址
# --unlock --password --allow-insecure-unlock: 解锁矿工账户
# --miner.gasprice: 设置最低 Gas Price
# --clique.period 5: 设置出块时间为 5 秒
nohup geth --datadir "$DATADIR" \
  --networkid "$NETWORK_ID" \
  --http --http.addr 0.0.0.0 --http.port "$RPC_PORT" --http.api eth,net,web3,personal,miner,clique \
  --http.corsdomain "*" \
  --mine --miner.etherbase "$MINER_ADDRESS" \
  --unlock "$MINER_ADDRESS" --password "$PASSWORD_FILE" --allow-insecure-unlock \
  --nodiscover --maxpeers 0 \
  --miner.gasprice "$GAS_PRICE" \
  > "$LOG_FILE" 2>&1 &

echo "Woof Layer 节点已在后台启动。日志文件：$LOG_FILE"
echo "您可以使用 'tail -f $LOG_FILE' 查看日志。"
echo "RPC 地址：http://<您的服务器IP>:$RPC_PORT"
echo "Chain ID: $NETWORK_ID"

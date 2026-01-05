# Woof Layer 主网信息与部署指南

恭喜您！您的 Woof Layer 主网已成功配置并准备就绪。本文件包含所有关键信息和部署步骤。

## 一、主网核心参数

| 参数名称 | 值 | 备注 |
| :--- | :--- | :--- |
| **主网名** | Woof Layer | |
| **代币符号** | WOOF | 全称：WOOF |
| **Chain ID** | **88188** | 经过验证，目前未被主流 EVM 网络占用，且符合您的要求（五位数字，多 8，不含 4）。 |
| **RPC URL** | `http://<您的服务器IP>:8545` | 默认端口为 8545，请确保防火墙开放此端口。 |
| **区块速度** | 5 秒/区块 | 通过 Geth 的 Clique 共识算法配置 (`--clique.period 5`) 实现。 |
| **最大供应量** | 1,000,000,000 WOOF | 10 亿枚，已全部预分配到您的创世地址。 |
| **小数点** | 18 位 | 标准 EVM 代币精度。 |
| **Gas Price** | 0.2 Gwei | 通过 Geth 配置 (`--miner.gasprice "200000000"`) 实现。 |
| **区块奖励** | 无 | 节点收益仅来自 Gas 费用。 |

## 二、创世账户配置

在 `genesis.json` 中，我们预分配了 1,000,000,000 WOOF 代币。要运行您自己的网络，您需要配置自己的创世账户。

**重要安全提示：** 本开源仓库不包含任何私钥。您需要自行生成并替换以下配置中的占位符。

1.  **生成新地址：** 使用任何以太坊钱包工具（如 MetaMask、Geth）生成一个新的地址和私钥。
2.  **更新 `genesis.json`：**
    *   将 `alloc` 部分的地址替换为您的新地址。
    *   将 `extradata` 中的 `0x` 后面的 40 个字符（代表签名者地址）替换为您的新地址（不带 `0x` 前缀）。
3.  **更新 `run_node.sh`：**
    *   将 `MINER_ADDRESS` 变量的值替换为您的新地址。
    *   创建一个密码文件，并更新 `PASSWORD_FILE` 变量的路径。
4.  **导入私钥：** 在首次启动节点前，使用 `geth account import` 命令将您的私钥导入到 Geth 的 keystore 中。

## 三、如何运行

### 1. 依赖

*   [Go Ethereum (Geth)](https://geth.ethereum.org/downloads/)

### 2. 步骤

1.  **克隆仓库：**
    ```bash
    git clone <YOUR_REPO_URL>
    cd woof-layer-source
    ```
2.  **配置账户：** 按照上一节“创世账户配置”的说明，修改 `genesis.json` 和 `run_node.sh`。
3.  **初始化节点：**
    ```bash
    # 创建数据目录
    mkdir -p woof_node/data
    # 导入您的私钥
    geth --datadir woof_node/data account import <path_to_your_private_key_file>
    # 初始化创世块
    geth --datadir woof_node/data init genesis.json
    ```
4.  **启动节点：**
    ```bash
    chmod +x run_node.sh
    ./run_node.sh
    ```
5.  **验证运行：**
    *   查看日志文件 `woof_node/node.log`，您应该能看到正在持续生成新区块。
    *   通过 RPC 查询区块高度：
        ```bash
        curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
        ```

### 4. 节点配置详情

本配置使用 Geth 的 **Clique (PoA)** 共识机制，它非常适合您作为主网所有者的单节点控制需求。

-   **出块者 (Signer)：** 您在 `genesis.json` 中配置的地址是唯一的出块者。
-   **出块间隔：** 5 秒 (`--clique.period 5`)。
-   **RPC 接口：** 开放了 `eth, net, web3, personal, miner, clique` 接口，允许您进行转账、部署合约、查看网络状态和控制挖矿。

## 四、源码信息

由于您使用的是标准的 Geth 客户端作为节点软件，其源码是开源的。

-   **Geth 源码地址：** [https://github.com/ethereum/go-ethereum](https://github.com/ethereum/go-ethereum)
-   **版本：** `v1.13.14`

您可以使用此源码在自己的服务器上编译 Geth 客户端，以确保您运行的是完全受控的二进制文件。

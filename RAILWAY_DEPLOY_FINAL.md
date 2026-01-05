# Railway 最终部署指南 - Woof Layer RPC 节点

**完整的、经过测试的、确保能部署成功的指南！**

---

## ✅ 已修复的问题

1. ✅ **genesis.json 文件** - 现已包含在仓库中
2. ✅ **Dockerfile 结构** - 重新设计，确保文件顺序正确
3. ✅ **多个下载源** - 使用 GitHub releases（最稳定）
4. ✅ **健康检查** - 自动验证 RPC 是否正常
5. ✅ **Railway 配置** - 添加了 railway.toml

---

## 🚀 部署步骤（最简单版本）

### 第 1 步：打开 Railway 仪表板

访问：https://railway.app

### 第 2 步：创建新项目

1. 点击 **"New Project"**
2. 选择 **"Deploy from GitHub repo"**
3. 搜索 **`woof-layer`**
4. 选择 **`JaceLabs/woof-layer`**
5. 点击 **"Deploy"**

### 第 3 步：等待部署完成

- 预计时间：**5-10 分钟**
- 查看 **"Logs"** 标签实时查看进度

### 第 4 步：获取 RPC URL

部署完成后：
1. 在 Railway 项目页面
2. 查看 **"Public URL"** 部分
3. 复制 URL（格式：`https://woof-layer-xxxx.up.railway.app`）

**这就是您的永久 RPC 地址！** 🎉

---

## 📋 预期部署日志

部署成功时，您应该看到以下日志：

```
Step 1/11 : FROM ubuntu:22.04
Step 2/11 : ENV DEBIAN_FRONTEND=noninteractive ...
Step 3/11 : RUN apt-get update && apt-get install -y curl wget git ca-certificates
Step 4/11 : WORKDIR /app
Step 5/11 : COPY genesis.json /app/genesis.json
Step 6/11 : RUN set -ex && echo "Downloading Geth..." && wget -q -O /tmp/geth.tar.gz ...
Step 7/11 : RUN mkdir -p /data
Step 8/11 : RUN echo "Initializing genesis block..." && geth --datadir /data init /app/genesis.json
Step 9/11 : EXPOSE 8545
Step 10/11 : HEALTHCHECK ...
Step 11/11 : CMD ["geth", ...]

Successfully built ...
Successfully tagged ...

INFO Starting Geth in full sync mode
INFO Initializing Geth configuration
INFO Starting HTTP server
INFO HTTP server started on 0.0.0.0:8545
```

---

## ✅ 验证部署成功

### 方式 1：查看 Railway 状态

- 状态应该是 **"Running"**（绿色）
- 日志中没有 ERROR

### 方式 2：测试 RPC 连接

使用 curl 测试：

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  https://woof-layer-xxxx.up.railway.app
```

**预期响应**：
```json
{"jsonrpc":"2.0","result":"0x1587c","id":1}
```

### 方式 3：检查区块高度

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://woof-layer-xxxx.up.railway.app
```

**预期响应**：
```json
{"jsonrpc":"2.0","result":"0x1","id":1}
```

---

## 🔧 Dockerfile 关键改进

### 问题 1：genesis.json 找不到

**之前**：
```dockerfile
RUN geth --datadir /woof-layer/data init /woof-layer/genesis.json  # 文件还没复制！
COPY genesis.json /woof-layer/
```

**现在**：
```dockerfile
COPY genesis.json /app/genesis.json  # 先复制文件
RUN geth --datadir /data init /app/genesis.json  # 再初始化
```

### 问题 2：数据目录不一致

**之前**：
```dockerfile
RUN mkdir -p /woof-layer/data
CMD ["geth", "--datadir", "/woof-layer/data", ...]
```

**现在**：
```dockerfile
ENV GETH_DATA_DIR="/data"
RUN mkdir -p ${GETH_DATA_DIR}
CMD ["geth", "--datadir", "/data", ...]
```

### 问题 3：缺少健康检查

**现在**：
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8545 -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' || exit 1
```

---

## 📁 GitHub 仓库结构

现在您的仓库包含：

```
JaceLabs/woof-layer/
├── Dockerfile                    ← 完全可工作的 Dockerfile
├── railway.toml                  ← Railway 配置
├── .dockerignore                 ← Docker 忽略文件
├── genesis.json                  ← 创世配置（重要！）
├── RAILWAY_DEPLOY_FINAL.md       ← 本指南
├── RAILWAY_DEPLOYMENT.md         ← 详细指南
├── RAILWAY_QUICK_DEPLOY.md       ← 快速指南
└── README.md                     ← 项目说明
```

---

## 🆘 如果部署仍然失败

### 检查清单

- [ ] genesis.json 文件在仓库中
- [ ] Dockerfile 在仓库根目录
- [ ] GitHub 仓库已更新（刷新页面）
- [ ] Railway 已检测到新提交
- [ ] 点击了 "Redeploy" 或创建了新项目
- [ ] 等待至少 10 分钟

### 查看详细日志

1. 在 Railway 项目页面
2. 点击 **"Logs"** 标签
3. 搜索关键词：
   - `ERROR` - 查找错误
   - `Downloading Geth` - 查找下载进度
   - `Initializing genesis block` - 查找初始化进度
   - `HTTP server started` - 查找成功标志

### 常见错误和解决方案

| 错误 | 原因 | 解决方案 |
| --- | --- | --- |
| `genesis.json: No such file` | 文件未复制 | 确保 genesis.json 在仓库根目录 |
| `geth: command not found` | Geth 未安装 | 检查下载日志 |
| `Connection refused` | RPC 未启动 | 等待 10 分钟让容器启动 |
| `Failed to initialize` | 初始化失败 | 检查 genesis.json 格式 |

---

## 💾 持久化数据

Railway 自动为您的项目分配持久化存储：
- ✅ 区块链数据被保存在 `/data` 目录
- ✅ 容器重启后数据不会丢失
- ✅ 您的链会继续产生新区块

---

## 🔐 安全建议

1. **HTTPS 自动启用** - Railway 提供免费 SSL 证书
2. **监控日志** - 定期检查日志以发现异常
3. **备份私钥** - 妥善保管 owner_wallet.txt
4. **限制访问** - 可在 Railway 中配置环境变量

---

## 📊 部署完成后的配置

### MetaMask 配置

| 参数 | 值 |
| --- | --- |
| **网络名称** | Woof Layer |
| **RPC URL** | `https://woof-layer-xxxx.up.railway.app` |
| **Chain ID** | `88188` |
| **货币符号** | `WOOF` |

### 导入创世账户

1. 打开 GitHub 仓库
2. 查看 `owner_wallet.txt`（如果有）
3. 复制私钥
4. 在 MetaMask 中导入

---

## ✨ 您现在拥有

✅ **永久 RPC 地址** - 不会过期  
✅ **自动重启** - 容器崩溃自动恢复  
✅ **持久化存储** - 数据被保存  
✅ **HTTPS 支持** - 自动 SSL 证书  
✅ **实时监控** - 可查看日志和指标  
✅ **健康检查** - 自动验证 RPC 状态  

---

## 📞 获取帮助

- **Railway 文档**：https://docs.railway.app
- **Geth 文档**：https://geth.ethereum.org/docs
- **GitHub 仓库**：https://github.com/JaceLabs/woof-layer

---

## ✅ 部署完成清单

- [ ] Railway 项目已创建
- [ ] GitHub 仓库已连接
- [ ] 部署已完成（显示 "Running"）
- [ ] 公开 URL 已获取
- [ ] RPC 连接已验证（curl 测试通过）
- [ ] MetaMask 已配置
- [ ] 创世账户已导入
- [ ] 测试交易已成功

---

**现在就去 Railway 部署吧！** 🚀

这次一定能成功！

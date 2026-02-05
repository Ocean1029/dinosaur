# Backend API

## 🚀 快速启动

### 启动服务器（不需要数据库）

```bash
npm install
npm run dev
```

服务器会在 `http://localhost:3000` 启动。

**注意：** 服务器已配置为监听所有网络接口（`0.0.0.0`），允许从 iPhone 访问。

### 使用脚本启动（推荐）

```bash
bash scripts/start-nfc-server.sh
```

---

## 📡 API 端点

### Health Check

```
GET /api/health
```

### NFC 端点

#### GET - URL 方式（NFC tag 写入 URL）

```
GET /api/nfc?id=station_001
```

#### POST - App 方式（Flutter App 发送）

```
POST /api/nfc/read
Content-Type: application/json

{
  "nfcId": "station_001",
  "tagType": "NTAG213",
  "timestamp": "2024-01-15T10:30:45.123Z",
  "deviceInfo": {
    "platform": "iOS",
    "model": "iPhone 15 Pro",
    "osVersion": "17.0"
  }
}
```

---

## 📝 文档

- **API 文档：** `http://localhost:3000/api/docs`
- **OpenAPI 规范：** `http://localhost:3000/docs.json`

---

## 🔧 网络配置

服务器默认监听 `0.0.0.0:3000`，允许从同一网络中的其他设备访问。

**获取 Mac IP 地址：**
```bash
bash scripts/get-vm-ip.sh
```

**测试连接（从 iPhone）：**
在 Safari 中访问：`http://你的Mac IP:3000/api/health`

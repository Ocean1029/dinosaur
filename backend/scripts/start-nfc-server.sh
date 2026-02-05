#!/bin/bash

# 啟動 NFC 測試伺服器（不需要資料庫）
# 這個腳本只啟動後端伺服器，用於 NFC 測試

set -e

# 獲取腳本所在目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"

# 切換到 backend 目錄
cd "$BACKEND_DIR"

echo "🚀 啟動 NFC 測試伺服器..."
echo "📝 注意：此模式不需要資料庫，只用於 NFC 測試"
echo ""

# 檢查是否已安裝依賴
if [ ! -d "node_modules" ]; then
    echo "📦 安裝依賴中..."
    npm install
    echo ""
fi

# 使用端口 3000（預設）
PORT=3000
export PORT

echo "✅ 伺服器將在 http://localhost:$PORT 啟動"
echo "📱 NFC 端點："
echo "   - GET  http://localhost:$PORT/api/nfc?id=station_001"
echo "   - POST http://localhost:$PORT/api/nfc/read"
echo ""
echo "按 Ctrl+C 停止伺服器"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PORT=$PORT npm run dev


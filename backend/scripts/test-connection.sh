#!/bin/bash

# 测试 iPhone 到 Mac 的连接

MAC_IP=${1:-"172.20.10.3"}
PORT=${2:-"3001"}

echo "🧪 测试连接..."
echo "Mac IP: $MAC_IP"
echo "Port: $PORT"
echo ""

# 测试本地连接
echo "1️⃣ 测试本地连接 (localhost:$PORT)..."
if curl -s http://localhost:$PORT/api/health > /dev/null 2>&1; then
    echo "✅ 本地连接成功"
    curl -s http://localhost:$PORT/api/health | head -3
else
    echo "❌ 本地连接失败 - 服务器可能未启动"
fi

echo ""
echo "2️⃣ 测试网络连接 ($MAC_IP:$PORT)..."
if curl -s http://$MAC_IP:$PORT/api/health > /dev/null 2>&1; then
    echo "✅ 网络连接成功"
    curl -s http://$MAC_IP:$PORT/api/health | head -3
else
    echo "❌ 网络连接失败"
    echo ""
    echo "可能的原因："
    echo "1. 服务器未启动"
    echo "2. 防火墙阻止连接"
    echo "3. iPhone 和 Mac 不在同一网络"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 在 iPhone Safari 中测试："
echo "   http://$MAC_IP:$PORT/api/health"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


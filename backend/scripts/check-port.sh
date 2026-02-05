#!/bin/bash

# 检查端口占用情况

PORT=${1:-3000}

echo "🔍 检查端口 $PORT 占用情况..."
echo ""

# 检查端口占用
if lsof -i :$PORT > /dev/null 2>&1; then
    echo "⚠️  端口 $PORT 已被占用："
    echo ""
    lsof -i :$PORT
    echo ""
    echo "💡 解决方案："
    echo "   1. 停止占用端口的服务（例如 Docker/OrbStack 容器）"
    echo "   2. 或者使用其他端口启动服务器（设置 PORT 环境变量）"
    echo ""
    echo "   例如："
    echo "   PORT=3001 npm run dev"
    exit 1
else
    echo "✅ 端口 $PORT 可用"
    exit 0
fi


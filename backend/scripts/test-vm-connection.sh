#!/bin/bash

# 測試 VM 連接腳本
# 用於確認 iPhone 可以訪問 VM 的伺服器

VM_IP=${1:-"192.168.1.100"}
PORT=${2:-"3000"}

echo "🧪 測試 VM 連接..."
echo "目標: http://$VM_IP:$PORT"
echo ""

# 測試健康檢查端點
HEALTH_URL="http://$VM_IP:$PORT/api/health"

echo "📡 測試健康檢查端點..."
if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$HEALTH_URL" 2>&1)
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ 連接成功！"
        echo ""
        echo "📄 回應內容："
        echo "$BODY" | head -20
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ VM 伺服器可以正常訪問！"
        echo ""
        echo "📱 在 iPhone 的 Safari 中打開："
        echo "   $HEALTH_URL"
        echo ""
        echo "📱 在 Flutter App 中使用："
        echo "   const String API_BASE_URL = 'http://$VM_IP:$PORT';"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo "❌ 連接失敗！HTTP 狀態碼: $HTTP_CODE"
        echo ""
        echo "🐛 疑難排解："
        echo "1. 確認後端伺服器正在運行："
        echo "   cd backend && npm run dev"
        echo ""
        echo "2. 確認 IP 地址正確："
        echo "   bash scripts/get-vm-ip.sh"
        echo ""
        echo "3. 確認防火牆允許連接："
        echo "   sudo pfctl -d  # macOS（測試用）"
        echo ""
        echo "4. 確認 iPhone 和 VM 在同一個網路中"
    fi
elif command -v wget &> /dev/null; then
    if wget -q -O - "$HEALTH_URL" > /dev/null 2>&1; then
        echo "✅ 連接成功！"
        echo ""
        echo "📱 在 iPhone 的 Safari 中打開："
        echo "   $HEALTH_URL"
    else
        echo "❌ 連接失敗！"
        echo "請檢查伺服器是否正在運行"
    fi
else
    echo "❌ 找不到 curl 或 wget"
    echo "請手動在瀏覽器中打開："
    echo "   $HEALTH_URL"
fi


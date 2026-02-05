#!/bin/bash

# 獲取 VM 的 IP 地址腳本
# 用於 USB Passthrough 測試

echo "🔍 正在查找 VM 的 IP 地址..."
echo ""

# macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 檢測到 macOS 系統"
    echo ""
    
    # 嘗試獲取主要網路介面的 IP
    WIFI_IP=$(ipconfig getifaddr en0 2>/dev/null)
    ETHERNET_IP=$(ipconfig getifaddr en1 2>/dev/null)
    
    if [ -n "$WIFI_IP" ]; then
        echo "✅ WiFi (en0) IP 地址: $WIFI_IP"
    fi
    
    if [ -n "$ETHERNET_IP" ]; then
        echo "✅ 有線網路 (en1) IP 地址: $ETHERNET_IP"
    fi
    
    if [ -z "$WIFI_IP" ] && [ -z "$ETHERNET_IP" ]; then
        echo "⚠️  無法自動檢測 IP 地址"
        echo ""
        echo "請手動執行以下命令："
        echo "  ifconfig | grep 'inet ' | grep -v 127.0.0.1"
    fi
    
    echo ""
    echo "📋 所有網路介面："
    ifconfig | grep -E "^[a-z]|inet " | grep -B1 "inet " | grep -v "127.0.0.1"
    
# Linux
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 檢測到 Linux 系統"
    echo ""
    
    echo "📋 所有網路介面 IP 地址："
    ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1"
    
    echo ""
    echo "或使用以下命令查看詳細資訊："
    echo "  ip addr show"
    
# Windows (Git Bash)
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "🪟 檢測到 Windows 系統（Git Bash）"
    echo ""
    echo "請在 PowerShell 或 CMD 中執行："
    echo "  ipconfig | findstr IPv4"
else
    echo "❓ 無法識別系統類型"
    echo "請手動執行以下命令："
    echo "  ifconfig | grep 'inet ' | grep -v 127.0.0.1"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 使用說明："
echo ""
echo "1. 記下上面的 IP 地址（通常是 192.168.x.x 或 10.x.x.x）"
echo "2. 在 iPhone 的 Safari 中測試連接："
echo "   http://你的IP:3000/api/health"
echo "3. 如果看到 JSON 回應，表示連接成功！"
echo "4. 在 Flutter App 中使用這個 IP 作為 API 基礎 URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


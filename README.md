## Dinosaur 專案說明

這是一個由 **Flutter App + Node.js Backend API** 組成的專案，主要用於整合 NFC 閱讀、活動點位與徽章系統，提供活動參與者在手機上查看活動進度、獎勵與統計資訊。

目前專案已經完成：

- **前端（Flutter）**
  - 基本專案結構與資源管理（`assets/`、`lib/gen/` 等）
  - 首頁 / 活動細節 / 徽章細節 / 統計頁面等畫面結構（`lib/page/home`、`activity_detail`、`badge_detail`、`stats`）
  - 初步的資料模型與假資料（`lib/model/`、`lib/page/home/mock_data.dart`）
- **後端（Node.js + Express + Prisma）**
  - 基本 API 伺服器骨架（`backend/src`）
  - NFC 閱讀相關 API 端點，例如：
    - `GET /api/health`
    - `GET /api/nfc?id=station_001`
    - `POST /api/nfc/read`
  - 開發腳本與網路設定（支援從同一網路的 iPhone 直接連線）

> ⚠️ 注意：目前後端的資料庫與實際 NFC 裝置串接仍在開發中，部分功能使用 mock data 或暫時邏輯實作。

---

## 專案結構概覽

大致目錄結構如下（僅列出與開發較相關的部分）：

- **Flutter App**
  - `lib/main.dart`：應用程式進入點
  - `lib/page/`：主要頁面與對應的 controller / view
    - `home/`：首頁、活動列表 / 點位顯示等
    - `activity_detail/`：單一活動詳情
    - `badge_detail/`：徽章詳情與分享畫面
    - `stats/`：統計資訊相關畫面
  - `lib/model/`：資料模型與使用者資料
  - `lib/service/`：與後端溝通或帳號相關 service
  - `assets/`：圖檔、SVG、mock data 等靜態資源

- **Backend API（Node.js）**
  - `backend/src/index.ts`：後端服務進入點
  - `backend/src/routes/`：各功能路由定義
  - `backend/src/controllers/`：對應業務邏輯
  - `backend/src/schemas/`：請求/回應驗證 schema
  - `backend/prisma/schema.prisma`：資料庫 schema（尚在演進中）
  - `backend/README.md`：後端啟動與 API 詳細說明

---

## 開發環境

- Flutter（請依照本機安裝版本，建議使用 `flutter --version` 確認）
- Dart
- Node.js（建議 18+）
- npm

---

## 如何啟動 Flutter App

在專案根目錄：

```bash
flutter pub get
flutter run
```

可以選擇模擬器或實體裝置執行（iOS / Android 皆可）。

---

## 如何啟動 Backend API

在 `backend/` 目錄下：

```bash
cd backend
npm install
npm run dev
```

伺服器預設會在 `http://localhost:3000` 啟動，並監聽 `0.0.0.0`，可以從同一網路的 iPhone 連線測試。  
更多細節（例如使用腳本啟動、NFC 端點說明、網路設定）請參考 `backend/README.md`。

---

## 目前進度與下一步

**目前進度**

- 建立前端頁面骨架與基本 UI 結構
- 整理主要資料模型與假資料
- 建立後端 API 伺服器與主要 NFC 相關端點

**下一步規劃（建議）**

- 串接實際資料庫（Prisma + 真實資料表結構）
- 串接真實 NFC 裝置與實機測試流程
- 完成前端與後端的實際 API 串接（取代 mock data）
- 加入錯誤處理、狀態顯示與基本追蹤/記錄

---

## 開發者備註

- 若要在實體 iPhone 測試，請確認 Mac 與手機在同一 Wi‑Fi 網路，並依照 `backend/README.md` 內的說明取得 IP 與測試連線。
- 若有新增 Flutter 套件或 Node 套件，請記得同步更新 `pubspec.yaml` 與 `backend/package.json`。

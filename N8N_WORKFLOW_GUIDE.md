# n8n Zeabur 架構執行方針

## 架構總覽

```
Webhook / 排程觸發
  → N8N 主服務（接收、分派）
  → Redis Queue
  → Worker（執行 workflow、ffmpeg、Python、JS）
  → Runners（輔助 JS/Python 執行）
```

---

## 服務清單

| 服務 | 功能 | 規格 |
|------|------|------|
| N8N | 主服務、Webhook、UI | queue mode |
| Worker | 執行所有 workflow | 2 CPU / 4GB RAM |
| Runners | JS / Python runner | n8nio/runners:stable |
| Redis | 任務佇列 | - |
| PostgreSQL | 資料持久化 | - |

---

## Volume 說明

| Volume ID | 掛載路徑 | 用途 |
|-----------|---------|------|
| data | /root/.n8n | n8n 設定、binary data |
| temp-videos | /data/temp-videos | 影片暫存（處理後需刪除） |

---

## 影片處理 Workflow 執行方針

### 流程設計

```
1. 觸發（Webhook 傳入 Google Drive File ID）
2. Google Drive → 取得下載 URL
3. HTTP Request → 下載影片到 /data/temp-videos/{uuid}.mp4
4. Execute Command → ffmpeg 抽取音軌
   ffmpeg -i /data/temp-videos/{uuid}.mp4 -vn -ar 44100 -ac 2 -b:a 128k /data/temp-videos/{uuid}.mp3
5. Execute Command → ffmpeg 切成 10 分鐘片段
   ffmpeg -i /data/temp-videos/{uuid}.mp3 -f segment -segment_time 600 -c copy /data/temp-videos/{uuid}_%03d.mp3
6. Split In Batches → 逐片處理
7. HTTP Request → OpenAI Whisper API（每片 < 25MB）
8. Code 節點（JS）→ 合併所有逐字稿
9. Google Drive → 上傳結果 .txt
10. Execute Command → 清除暫存檔
    rm -rf /data/temp-videos/{uuid}*
11. Respond to Webhook → 回傳完成
```

### 重要限制

| 項目 | 限制 |
|------|------|
| OpenAI Whisper 單檔上限 | 25 MB |
| Worker 最長執行時間 | 3600 秒（1 小時） |
| Worker 記憶體上限 | 4096 MB |
| 影片暫存路徑 | /data/temp-videos |

### 注意事項

- **每次處理完務必刪除暫存檔**，避免 Volume 空間耗盡
- 2GB 影片禁止直接存入記憶體，必須先寫到 `/data/temp-videos`
- ffmpeg 切片建議以 10 分鐘為單位，確保每片 < 25MB
- 音訊格式建議輸出 MP3 128kbps，平衡品質與檔案大小

---

## Code 節點使用方針

| 語言 | 狀態 | 用途建議 |
|------|------|---------|
| JavaScript | ✅ | 資料整理、字串處理、API 回應解析 |
| Python | ✅ | 數學運算、資料分析、文字處理 |

---

## Workflow 開發規範

### 命名規則
- Webhook URL：`/webhook/{功能名稱}`
- Workflow 名稱：`[品牌] 功能描述`，例如：`[XUEMI] 影片轉逐字稿`

### 錯誤處理
- 每個 workflow 必須有 Error Trigger 節點
- 錯誤發生時通知（Slack / Email / Line Notify）
- 暫存檔清除邏輯放在 Error 分支也要執行

### 測試原則
- 先在 n8n 編輯器手動測試（走 Runners）
- 確認無誤後 Activate，正式走 Worker

---

## 未來擴充方向

| 功能 | 說明 | 需要做的事 |
|------|------|----------|
| Python 套件安裝 | 如 pandas、numpy | 更新 Dockerfile 加 pip install |
| GPU 加速 | 影片處理加速 | 需要更換 Zeabur 機器類型 |
| 多 Worker 擴展 | 同時處理多支影片 | Zeabur 水平擴展 Worker 服務 |

---

## Dockerfile 管理

- Repo：`https://github.com/xuecu/n8n-worker`
- 每次更新 Dockerfile push 到 main，Zeabur 自動重新 build
- 目前安裝：ffmpeg、Python 3.11

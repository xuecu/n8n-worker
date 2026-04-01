FROM n8nio/n8n:latest

# ffmpeg
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /usr/local/bin/ffmpeg
COPY --from=mwader/static-ffmpeg:latest /ffprobe /usr/local/bin/ffprobe

# Python + 套件（在 python image 裡先裝好，再整包複製）
FROM python:3.11-slim AS python-builder
RUN pip install --no-cache-dir \
    pandas numpy requests beautifulsoup4 \
    matplotlib pillow pypdf cryptography

# 最終 image
FROM n8nio/n8n:latest

# ffmpeg（重複一次，因為 FROM 會重置 stage）
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /usr/local/bin/ffmpeg
COPY --from=mwader/static-ffmpeg:latest /ffprobe /usr/local/bin/ffprobe

# ImageMagick
COPY --from=dpokidov/imagemagick:latest-bookworm /usr/local/bin/magick /usr/local/bin/magick

# Python 執行檔 + lib + 已安裝的套件
COPY --from=python-builder /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python-builder /usr/local/bin/python3.11 /usr/local/bin/python3.11
COPY --from=python-builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
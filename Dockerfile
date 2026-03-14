FROM n8nio/n8n:latest

# ffmpeg
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /usr/local/bin/ffmpeg
COPY --from=mwader/static-ffmpeg:latest /ffprobe /usr/local/bin/ffprobe

# Python
COPY --from=python:3.11-slim /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python:3.11-slim /usr/local/lib/python3.11 /usr/local/lib/python3.11

# Python 套件
RUN pip install pandas numpy requests beautifulsoup4 matplotlib pillow pypdf cryptography

# ImageMagick
COPY --from=dpokidov/imagemagick:latest-bookworm /usr/local/bin/magick /usr/local/bin/magick

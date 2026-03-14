FROM n8nio/n8n:latest
COPY --from=mwader/static-ffmpeg:latest /ffmpeg /usr/local/bin/ffmpeg
COPY --from=mwader/static-ffmpeg:latest /ffprobe /usr/local/bin/ffprobe
COPY --from=python:3.11-slim /usr/local/bin/python3 /usr/local/bin/python3
COPY --from=python:3.11-slim /usr/local/lib/python3.11 /usr/local/lib/python3.11

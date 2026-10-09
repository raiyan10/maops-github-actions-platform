# syntax=docker/dockerfile:1
FROM python:3.13-slim

ARG APP_BUILD_ID=local-dev

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src \
    APP_BUILD_ID=${APP_BUILD_ID} \
    PORT=8080

WORKDIR /app
RUN useradd --system --uid 10001 --no-create-home app
COPY src/ ./src/

USER 10001
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import os, urllib.request; urllib.request.urlopen(f\"http://127.0.0.1:{os.environ['PORT']}/healthz\", timeout=2)"]

CMD ["python", "-m", "maops_p5_app"]

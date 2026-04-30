# syntax=docker/dockerfile:1.7

############################
# Stage 1 - build wheels   #
############################
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /build

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml requirements.txt README.md ./
COPY ghunt ./ghunt
COPY main.py ./main.py

RUN pip install --upgrade pip build \
    && pip wheel --wheel-dir /wheels -r requirements.txt \
    && pip wheel --wheel-dir /wheels --no-deps .

############################
# Stage 2 - runtime image  #
############################
FROM python:3.11-slim AS runtime

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    GHUNT_HOME=/app

WORKDIR /app

RUN useradd --create-home --uid 1000 ghunt

COPY --from=builder /wheels /wheels

RUN pip install --no-index --find-links=/wheels ghunt \
    && rm -rf /wheels

USER ghunt

ENTRYPOINT ["ghunt"]
CMD ["--help"]

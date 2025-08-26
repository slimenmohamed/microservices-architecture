#!/usr/bin/env bash
set -euo pipefail

# Renders Mermaid diagrams to SVG using a Dockerized mermaid-cli
# Requirements: Docker installed and running
# Usage: ./scripts/render-diagrams.sh

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DOCS_DIR="$ROOT/docs"

ARCH_IN="$DOCS_DIR/architecture.mmd"
ARCH_OUT="$DOCS_DIR/architecture.svg"
COMM_IN="$DOCS_DIR/communication.mmd"
COMM_OUT="$DOCS_DIR/communication.svg"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required to render diagrams" >&2
  exit 1
fi

if [ ! -f "$COMM_IN" ]; then
  echo "ERROR: missing $COMM_IN" >&2
  exit 1
fi

if [ ! -f "$ARCH_IN" ]; then
  echo "ERROR: missing $ARCH_IN" >&2
  exit 1
fi

# Use minlag/mermaid-cli to render
# Map docs dir into /data to keep paths simple

# Render communication diagram
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$DOCS_DIR":/data \
  minlag/mermaid-cli:latest \
  -i /data/communication.mmd \
  -o /data/communication.svg

# Render architecture diagram
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$DOCS_DIR":/data \
  minlag/mermaid-cli:latest \
  -i /data/architecture.mmd \
  -o /data/architecture.svg

echo "✅ Generated $COMM_OUT"
echo "✅ Generated $ARCH_OUT"

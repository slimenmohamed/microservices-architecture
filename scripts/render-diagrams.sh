#!/usr/bin/env bash
set -euo pipefail

# Renders Mermaid diagrams to SVG using a Dockerized mermaid-cli
# Requirements: Docker installed and running
# Usage: ./scripts/render-diagrams.sh

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DOCS_DIR="$ROOT/docs"

INPUT="$DOCS_DIR/communication.mmd"
OUTPUT="$DOCS_DIR/communication.svg"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required to render diagrams" >&2
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "ERROR: missing $INPUT" >&2
  exit 1
fi

# Use minlag/mermaid-cli to render
# Map docs dir into /data to keep paths simple

docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "$DOCS_DIR":/data \
  minlag/mermaid-cli:latest \
  -i /data/communication.mmd \
  -o /data/communication.svg

echo "✅ Generated $OUTPUT"

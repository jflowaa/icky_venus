#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"
cd "$APP_DIR"

. "$ROOT/versions.env"
. "$ROOT/scripts/lib/container.sh"

TAG="${TAG:-local-$(date +%Y%m%d-%H%M%S)}"
IMAGE="icky_venus"
PROJECT="icky-venus"
LOCAL_HOST="icky-venus.localhost"
DOCKERFILE="Dockerfile"

case "$(uname -m)" in
  arm64|aarch64) platform=linux/arm64 ;;
  *) platform=linux/amd64 ;;
esac

container_available || { echo "error: container engine is not running" >&2; exit 1; }
container_network_exists edge >/dev/null 2>&1   || { echo "error: platform networks missing; run ./scripts/setup.sh local first" >&2; exit 1; }

if [ ! -f deployment/env/app.env ]; then
  cp deployment/env/app.env.example deployment/env/app.env
fi

printf 'IMAGE_TAG=%s\n' "$TAG" > deployment/.env

echo "==> building $IMAGE:$TAG ($platform)"
container_build "$platform" -f "$APP_DIR/$DOCKERFILE" -t "$IMAGE:$TAG" "$APP_DIR"

cd "$APP_DIR/deployment"
engine="$(container_engine)"
if [ "$engine" = podman ]; then
  command -v podman-compose >/dev/null 2>&1 \
    || { echo "error: podman-compose not found" >&2; exit 1; }
  compose=(podman-compose -p "$PROJECT" -f compose.yaml)
else
  compose=(docker compose -p "$PROJECT" -f compose.yaml)
fi

"${compose[@]}" up -d --remove-orphans

"${compose[@]}" ps

echo "==> smoke test http://$LOCAL_HOST:8080/"
for _ in $(seq 1 20); do
  if curl -fsS "http://$LOCAL_HOST:8080/" >/dev/null 2>&1; then
    echo "    OK"
    exit 0
  fi
  sleep 2
done
echo "error: http://$LOCAL_HOST:8080/ did not answer" >&2
exit 1

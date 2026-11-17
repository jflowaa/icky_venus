#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$APP_DIR/.." && pwd)"
cd "$APP_DIR"

. "$ROOT/versions.env"
. "$ROOT/scripts/lib/container.sh"

OVH_HOST="${OVH_HOST:-ovh}"
TAG="${TAG:-ovh-$(date +%Y%m%d-%H%M%S)}"
IMAGE="icky_venus"
PROJECT="icky-venus"
HOST="icky-venus.jack-develops.com"
DOCKERFILE="Dockerfile"

container_available || { echo "error: container engine is not running" >&2; exit 1; }
ssh -T -o BatchMode=yes "$OVH_HOST" 'sudo -n podman info >/dev/null'   || { echo "error: cannot reach Podman on $OVH_HOST" >&2; exit 1; }

echo "==> building $IMAGE:$TAG (linux/amd64)"
container_build linux/amd64 -f "$APP_DIR/$DOCKERFILE" -t "$IMAGE:$TAG" "$APP_DIR"

echo "==> shipping $IMAGE:$TAG to $OVH_HOST"
container_export "$IMAGE:$TAG" | ssh -T "$OVH_HOST" 'sudo -n podman load'

echo "==> converging /srv/apps/$PROJECT"
ssh -T "$OVH_HOST" "sudo -n bash -s" <<REMOTE
set -euo pipefail
cd /srv/apps/$PROJECT
sed -i '/^IMAGE_TAG=/d' .env
printf 'IMAGE_TAG=%s\n' '$TAG' >> .env
chmod 600 .env
if grep -q '^  migrate:' compose.yaml; then
  podman-compose --profile tools -p '$PROJECT' run --rm migrate </dev/null
fi
podman-compose -p '$PROJECT' up -d --remove-orphans
podman-compose -p '$PROJECT' ps
REMOTE

scp -q "$APP_DIR/deployment/systemd/app-$PROJECT-compose.service"   "$OVH_HOST:/tmp/app-$PROJECT-compose.service"
ssh -T "$OVH_HOST" "sudo -n install -m 644 /tmp/app-$PROJECT-compose.service /etc/systemd/system/app-$PROJECT-compose.service && rm -f /tmp/app-$PROJECT-compose.service && sudo -n systemctl daemon-reload && sudo -n systemctl enable --now app-$PROJECT-compose.service >/dev/null"

echo "==> smoke test https://$HOST/"
for _ in $(seq 1 20); do
  if curl -fsSI "https://$HOST/" >/dev/null 2>&1; then
    echo "    OK"
    exit 0
  fi
  sleep 3
done
echo "error: https://$HOST/ did not answer" >&2
exit 1

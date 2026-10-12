#!/usr/bin/env bash
set -euo pipefail
TAG="$1"
cd /opt/rest-api
PREV="$(cat current_tag 2>/dev/null || true)"
echo "Deploying $TAG (previous: ${PREV:-none})"
export TAG
docker compose pull api
docker compose up -d db
docker compose run --rm api node dist/db/migrate.js
docker compose up -d api
ok=0
for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:3000/health >/dev/null; then ok=1; break; fi
  sleep 2
done
if [ "$ok" -eq 1 ]; then
  echo "$TAG" > current_tag
  echo "Deploy OK: $TAG"
else
  echo "Health check FAILED for $TAG"
  docker compose logs --tail 50 api || true
  if [ -n "$PREV" ]; then
    echo "Rolling back to $PREV"
    export TAG="$PREV"
    docker compose up -d api
  fi
  exit 1
fi

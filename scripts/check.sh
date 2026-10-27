#!/bin/sh
# Checks that need Docker. Run from the repo root: sh scripts/check.sh
set -eu

# Use the same Prometheus image the compose file pins, so rules are checked against the deployed version.
PROM_IMAGE=$(sed -n 's/^ *image: *\(prom\/prometheus:[^ ]*\).*/\1/p' docker-compose.yml)
[ -n "$PROM_IMAGE" ] || { echo "could not read prometheus image from docker-compose.yml" >&2; exit 1; }

echo "== promtool check rules ($PROM_IMAGE)"
docker run --rm --network none -v "$PWD/prometheus/rules":/rules:ro --entrypoint promtool "$PROM_IMAGE" \
  check rules /rules/walrus_node_alerts.yml /rules/walrus_aggregator_alerts.yml /rules/walrus_publisher_alerts.yml

for f in docker-compose.yml docker-compose.macos.yml; do
  echo "== docker compose config $f"
  docker compose --env-file .env.tmp -f "$f" config -q
done
echo "All checks passed."

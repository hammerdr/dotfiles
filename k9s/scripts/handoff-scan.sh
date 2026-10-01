#!/bin/bash
# Live ring-wide handoff view from Datadog (discovery.rebalancer.waiting gauge, 10s resolution).
# Only `waiting` keeps pod_name/kube_namespace tags in Datadog; in_flight/success/stale/failed are
# tag-limited to service-level tags, so per-pod detail beyond waiting needs the pod's cardiograph /health.
# Credentials: read-only Datadog key via Keysmith (cached, 8h TTL).
# usage: handoff-scan.sh <namespace> [interval_seconds] [--once]
set -e
NS="${1:-discord-push}"; INTERVAL="${2:-10}"; ONCE="${3:-}"
DD_SITE="${DD_SITE:-us5.datadoghq.com}"
for c in keysmith curl jq column; do command -v "$c" >/dev/null || { echo "missing $c"; exit 1; }; done

creds=$(keysmith get datadog --scope-level read-only --format json 2>/dev/null | jq -r '.value')
DD_API_KEY=$(echo "$creds" | jq -r '.api_key')
DD_APP_KEY=$(echo "$creds" | jq -r '.app_key')
unset creds
if [ -z "$DD_API_KEY" ] || [ "$DD_API_KEY" = "null" ]; then
  echo "keysmith: no datadog credential (try: keysmith login)"; exit 1
fi

Q="max:discovery.rebalancer.waiting{kube_namespace:${NS}} by {pod_name}"

render() {
  local now resp
  now=$(date +%s)
  resp=$(curl -s --max-time 10 -G "https://api.${DD_SITE}/api/v1/query" \
    -H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
    --data-urlencode "from=$((now - 180))" --data-urlencode "to=${now}" \
    --data-urlencode "query=${Q}")
  if [ "$(echo "$resp" | jq -r '.status // "error"' 2>/dev/null)" != "ok" ]; then
    echo "datadog query failed: $(echo "$resp" | jq -r '.error // .errors // .' 2>/dev/null | cut -c1-200)"
    return
  fi
  # Per pod: latest waiting and waiting ~60s ago -> drain rate, ETA, moving/FLAT.
  echo "$resp" | jq -r --argjson now "$now" '
    [ .series[]
      | [.pointlist[] | select(.[1] != null)] as $p
      | ($p | last) as $l
      | ([$p[] | select((.[0] / 1000) <= ($now - 60))] | last) as $b
      | { pod: (.scope | sub("^.*pod_name:"; "") | sub(",.*$"; "")),
          waiting: (($l[1] // 0) | floor),
          prev: (if $b == null then null else ($b[1] | floor) end),
          age: (((($now * 1000) - ($l[0] // 0)) / 1000) | floor) } ]
    | map(select(.waiting > 0))
    | map(.rate = (if .prev == null then null else (((.prev - .waiting) / 60) | floor) end)
          | .eta = (if (.rate // 0) > 0 then "\((.waiting / .rate / 60) | floor)m" else "-" end)
          | .state = (if .age > 60 then "NODATA"
                      elif .rate == null then "new"
                      elif .rate <= 0 then "FLAT"
                      else "moving" end))
    | sort_by(-.waiting)
    | (["POD", "STATE", "WAITING", "RATE/s", "ETA", "AGE"] | @tsv),
      (.[] | [.pod, .state, .waiting, (.rate // "-"), .eta, "\(.age)s"] | @tsv)
  ' | column -t
}

while true; do
  out=$(render)
  [ -z "$ONCE" ] && clear
  rows=$(( $(printf '%s\n' "$out" | wc -l) - 1 ))
  echo "$(date -u +%T) UTC  ns=${NS}  source=datadog discovery.rebalancer.waiting  pods with waiting>0: $(( rows < 0 ? 0 : rows ))"
  echo "FLAT = waiting not decreasing over 60s (stale/frozen candidate: check that pod's :7878/health). Ctrl-C to exit."
  echo
  printf '%s\n' "$out"
  [ -n "$ONCE" ] && break
  sleep "$INTERVAL"
done

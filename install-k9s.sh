#!/bin/bash
# Install the k9s handoff-scan plugin and ElixirDeployment view.
# Merges into existing k9s plugins.yaml/views.yaml (backing them up) instead of overwriting.
#
#   ./install-k9s.sh            # install / update
#   ./install-k9s.sh --dry-run  # show what would change
#
# Runtime requirements for the plugin: k9s, keysmith (Datadog read-only), curl, jq, column.
set -e

DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/k9s"
[ -d "$SRC_DIR" ] || { echo "k9s/ directory not found next to $0"; exit 1; }

say() { echo "[k9s] $*"; }

# Resolve the k9s config dir the same way k9s does (respects XDG_CONFIG_HOME / macOS default).
k9s_dir=""
if command -v k9s >/dev/null 2>&1; then
  plugins_path=$(k9s info 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | awk -F': *' '/^Plugins/{print $2}')
  [ -n "$plugins_path" ] && k9s_dir=$(dirname "$plugins_path")
fi
if [ -z "$k9s_dir" ]; then
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    k9s_dir="$XDG_CONFIG_HOME/k9s"
  elif [ "$(uname)" = "Darwin" ]; then
    k9s_dir="$HOME/Library/Application Support/k9s"
  else
    k9s_dir="$HOME/.config/k9s"
  fi
  command -v k9s >/dev/null 2>&1 || say "k9s not found on PATH; installing config to $k9s_dir anyway"
fi
say "config dir: $k9s_dir"

for c in keysmith curl jq column; do
  command -v "$c" >/dev/null 2>&1 || say "warning: '$c' not found; the plugin needs it at runtime"
done

if [ "$DRY_RUN" = true ]; then
  say "dry run: would install scripts/handoff-scan.sh and merge plugins.yaml + views.yaml"
  exit 0
fi

mkdir -p "$k9s_dir/scripts"
install -m 0755 "$SRC_DIR/scripts/handoff-scan.sh" "$k9s_dir/scripts/handoff-scan.sh"
say "installed scripts/handoff-scan.sh"

# Render plugin template with the real script path.
rendered_plugins=$(mktemp)
trap 'rm -f "$rendered_plugins"' EXIT
sed "s|__K9S_DIR__|$k9s_dir|g" "$SRC_DIR/plugins.yaml" >"$rendered_plugins"

# merge_yaml <template> <dest> <top-level key>
# Adds/updates our entries under the top-level key, keeps everything else, backs up dest.
merge_yaml() {
  local tmpl="$1" dest="$2" key="$3"
  if [ ! -f "$dest" ]; then
    cp "$tmpl" "$dest"
    say "created $(basename "$dest")"
    return
  fi
  if python3 -c 'import yaml' >/dev/null 2>&1; then
    cp "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    python3 - "$tmpl" "$dest" "$key" <<'PY'
import sys, yaml
tmpl_path, dest_path, key = sys.argv[1:4]
with open(tmpl_path) as f:
    ours = (yaml.safe_load(f) or {}).get(key, {}) or {}
with open(dest_path) as f:
    data = yaml.safe_load(f) or {}
section = data.setdefault(key, {}) or {}
data[key] = section
# Retire the old single-pod watch plugin if a previous version installed it.
if key == "plugins":
    section.pop("handoff-watch", None)
    for name, p in ours.items():
        sc = (p.get("shortCut") or "").lower()
        scopes = set(p.get("scopes") or [])
        for other, op in section.items():
            if other == name or not isinstance(op, dict):
                continue
            if (op.get("shortCut") or "").lower() == sc and scopes & set(op.get("scopes") or []):
                print(f"[k9s] warning: plugin '{other}' also uses {p.get('shortCut')} in an overlapping scope; "
                      f"k9s will refuse to load plugins until one is changed", file=sys.stderr)
section.update(ours)
with open(dest_path, "w") as f:
    yaml.safe_dump(data, f, sort_keys=False, default_flow_style=False)
PY
    say "merged $(basename "$dest") (backup saved alongside)"
  elif grep -q "handoff-scan:\|discord.com/v1/elixirdeployments:" "$dest"; then
    say "$(basename "$dest") already has our entries and PyYAML is unavailable; leaving it as-is"
  else
    say "can't merge $(basename "$dest") without PyYAML (pip3 install pyyaml)."
    say "add this under '$key:' in $dest manually:"
    sed -n "2,\$p" "$tmpl"
  fi
}

merge_yaml "$rendered_plugins" "$k9s_dir/plugins.yaml" plugins
merge_yaml "$SRC_DIR/views.yaml" "$k9s_dir/views.yaml" views

# Remove the retired watch script if present.
rm -f "$k9s_dir/scripts/handoff-watch.sh"

say "done. In k9s: open :elixirdeployments (or pods) in a namespace and press Shift-Q."
say "first run may prompt for 'keysmith login' if you have no cached Datadog credential."

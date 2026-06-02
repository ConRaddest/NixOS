#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
nos="${NOS_DIR:-$HOME/NixOS}"
base="$nos/config/webapps"
apps_json="$base/apps.json"
launcher_qml="$nos/config/shell/components/WebApps.qml"
icons_dir="$base/icons"
mkdir -p "$icons_dir"
[ -f "$apps_json" ] || printf '[]\n' > "$apps_json"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

json_escape_arg() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

regenerate() {
  python3 - "$apps_json" "$launcher_qml" <<'PY'
import json, sys
apps_path, qml_path = sys.argv[1:3]
with open(apps_path, encoding="utf-8") as f:
    apps = json.load(f)

def q(s):
    return json.dumps(str(s), ensure_ascii=False)

with open(qml_path, "w", encoding="utf-8") as f:
    f.write("import QtQuick\n\n")
    f.write("QtObject {\n")
    f.write("    readonly property var items: [\n")
    for app in apps:
        if not app.get("launcher", False):
            continue
        f.write("        {\n")
        f.write(f"            name: {q(app['name'])},\n")
        f.write(f"            icon: {q(app.get('glyph') or '󰖟')},\n")
        f.write(f"            desktop: {q(app['id'] + '-pwa')}\n")
        f.write("        },\n")
    f.write("    ]\n")
    f.write("}\n")
PY
}

restart_quickshell() {
  command -v qs >/dev/null 2>&1 || return 0
  printf 'Restarting Quickshell...\n'
  qs kill >/dev/null 2>&1 || true
  sleep 0.2
  if command -v uwsm >/dev/null 2>&1; then
    uwsm app -- qs >/dev/null 2>&1 &
  else
    qs --daemonize >/dev/null 2>&1 || true
  fi
}

list_apps() {
  python3 - "$apps_json" <<'PY'
import json, sys
apps=json.load(open(sys.argv[1], encoding="utf-8"))
if not apps:
    print("No web apps installed.")
else:
    for i, app in enumerate(apps, 1):
        print(f"{i:2d}) {app['name']:<24} {app['url']}")
PY
}

find_icon_url() {
  local url="$1"
  python3 - "$url" <<'PY'
import re, sys, urllib.parse, urllib.request
url=sys.argv[1]
try:
    req=urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"})
    html=urllib.request.urlopen(req, timeout=10).read(500000).decode("utf-8", "ignore")
except Exception:
    html=""
links=re.findall(r'<link[^>]+>', html, flags=re.I)
best=""
for link in links:
    rel=re.search(r'rel=["\']([^"\']+)["\']', link, flags=re.I)
    href=re.search(r'href=["\']([^"\']+)["\']', link, flags=re.I)
    if not href or not rel:
        continue
    relv=rel.group(1).lower()
    if "icon" in relv:
        best=urllib.parse.urljoin(url, href.group(1))
        if "apple" in relv or "shortcut" in relv:
            break
if not best:
    p=urllib.parse.urlparse(url)
    best=f"{p.scheme}://{p.netloc}/favicon.ico"
print(best)
PY
}

app_exists() {
  python3 - "$apps_json" "$1" <<'PY'
import json, sys
apps=json.load(open(sys.argv[1], encoding="utf-8"))
sys.exit(0 if any(app.get("id") == sys.argv[2] for app in apps) else 1)
PY
}

add_app_json() {
  python3 - "$apps_json" "$id" "$name" "$url" "$icon_rel" "$launcher" "$glyph" <<'PY'
import json, sys
path, id_, name, url, icon, launcher, glyph = sys.argv[1:]
with open(path, encoding="utf-8") as f:
    apps=json.load(f)
apps.append({
    "id": id_,
    "name": name,
    "url": url,
    "icon": icon,
    "launcher": launcher == "true",
    "glyph": glyph,
})
with open(path, "w", encoding="utf-8") as f:
    json.dump(apps, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

remove_app_json() {
  python3 - "$apps_json" "$id" <<'PY'
import json, sys
path, id_ = sys.argv[1:]
apps=json.load(open(path, encoding="utf-8"))
apps=[app for app in apps if app.get("id") != id_]
with open(path, "w", encoding="utf-8") as f:
    json.dump(apps, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

id_from_choice() {
  python3 - "$apps_json" "$1" <<'PY'
import json, sys
apps=json.load(open(sys.argv[1], encoding="utf-8"))
choice=sys.argv[2]
if choice.isdigit():
    i=int(choice)-1
    print(apps[i]["id"] if 0 <= i < len(apps) else "")
else:
    print(choice)
PY
}

install_app() {
  read -rp 'App name: ' name
  [ -n "$name" ] || { echo 'name required' >&2; exit 1; }
  read -rp 'URL: ' url
  [ -n "$url" ] || { echo 'url required' >&2; exit 1; }
  case "$url" in http://*|https://*) ;; *) url="https://$url" ;; esac

  id="$(slugify "$name")"
  if app_exists "$id"; then
    echo "web app already exists: $id" >&2
    exit 1
  fi

  icon_url="$(find_icon_url "$url" || true)"
  ext="${icon_url%%\?*}"
  ext="${ext##*.}"
  case "$ext" in png|jpg|jpeg|svg|ico|webp) ;; *) ext="ico" ;; esac

  # Desktop entries do not reliably display WebP icons, so normalize WebP to
  # PNG. If anything fails, generate a simple SVG fallback so the icon path is
  # always valid and visible.
  icon_rel="icons/$id.$ext"
  [ "$ext" = webp ] && icon_rel="icons/$id.png"
  icon_path="$base/$icon_rel"
  tmp_icon="$(mktemp --suffix=.$ext)"
  printf 'Fetching icon: %s\n' "$icon_url"
  if [ -n "$icon_url" ] && curl -L --fail --max-time 20 -A 'Mozilla/5.0' -o "$tmp_icon" "$icon_url"; then
    if [ "$ext" = webp ]; then
      if command -v magick >/dev/null 2>&1 && magick "$tmp_icon" "$icon_path"; then
        :
      else
        echo 'webp icon conversion failed; using fallback icon' >&2
        icon_rel="icons/$id.svg"
        icon_path="$base/$icon_rel"
        printf '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect width="128" height="128" rx="28" fill="#2b2548"/><text x="64" y="80" text-anchor="middle" font-family="sans-serif" font-size="56" fill="#f2d6e8">%s</text></svg>\n' "${name:0:1}" > "$icon_path"
      fi
    else
      cp "$tmp_icon" "$icon_path"
    fi
  else
    echo 'icon download failed; using fallback icon' >&2
    icon_rel="icons/$id.svg"
    icon_path="$base/$icon_rel"
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect width="128" height="128" rx="28" fill="#2b2548"/><text x="64" y="80" text-anchor="middle" font-family="sans-serif" font-size="56" fill="#f2d6e8">%s</text></svg>\n' "${name:0:1}" > "$icon_path"
  fi
  rm -f "$tmp_icon"

  read -rp 'Add to custom launcher menu? [Y/n]: ' add_launcher
  case "${add_launcher:-Y}" in n|N|no|NO) launcher=false ;; *) launcher=true ;; esac
  glyph=""
  if [ "$launcher" = true ]; then
    read -rp 'Nerd Font launcher icon [󰖟]: ' glyph
    glyph="${glyph:-󰖟}"
  fi

  add_app_json
  regenerate
  printf '\nCreated desktop entry: %s-pwa\n' "$id"
  nos-refresh
  restart_quickshell
}

uninstall_app() {
  list_apps
  read -rp 'Remove which app number or id? ' choice
  [ -n "$choice" ] || exit 1
  id="$(id_from_choice "$choice")"
  [ -n "$id" ] || { echo 'invalid selection' >&2; exit 1; }
  if ! app_exists "$id"; then
    echo "not found: $id" >&2
    exit 1
  fi
  read -rp "Remove browser profile data for $id? [y/N]: " remove_profile
  remove_app_json
  regenerate
  case "$remove_profile" in y|Y|yes|YES) rm -rf "$HOME/.local/share/chromium-pwas/$id" ;; esac
  printf '\nRemoved desktop entry: %s-pwa\n' "$id"
  nos-refresh
  restart_quickshell
}

case "$cmd" in
  install) install_app ;;
  uninstall|remove) uninstall_app ;;
  list) list_apps ;;
  regenerate) regenerate ;;
  *) printf 'usage: nos-webapp install|uninstall|list|regenerate\n' >&2; exit 1 ;;
esac

#!/usr/bin/env bash
set -euo pipefail

REPO="Control-D-Inc/ctrld"
INSTALL_DIR="/usr/local/bin"

version="latest"
install=false
list=false
check=false

usage() {
  cat <<EOF
ctrld fetcher

Usage:
  $0 [--version <tag>] [--install] [--list] [--check] [--help]

Options:
  --version <tag>   Specify a release version (ex: 1.4.3 or v1.4.3). Default: latest
  --install         Move the extracted 'ctrld' into ${INSTALL_DIR}
  --list            List available release tags
  --check           Dry-run: print detected OS/arch and the download URL, then exit
  --help            Show this help message

Examples:
  $0
  $0 --version 1.4.3
  $0 --check
  sudo $0 --install
  sudo $0 --version v1.4.3 --install
EOF
}

# --- parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      shift
      [[ $# -gt 0 ]] || { echo "Missing value for --version"; exit 1; }
      version="${1#v}"  # accept with/without leading v
      ;;
    --install) install=true ;;
    --list)    list=true ;;
    --check)   check=true ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

# --- helpers ---
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1"; exit 1; }; }

# jq is only required for API selection (safer than guessing filenames)
need_cmd curl
need_cmd tar
need_cmd unzip || true   # only needed if a .zip ever appears for *nix builds
need_cmd jq

if $list; then
  curl -s "https://api.github.com/repos/${REPO}/releases" \
    | jq -r '.[].tag_name' \
    | sed 's/^v//' \
    | sort -Vr
  exit 0
fi

# --- detect platform ---
os_raw=$(uname -s | tr '[:upper:]' '[:lower:]')
arch_raw=$(uname -m)

case "$os_raw" in
  linux)   os="linux" ;;
  darwin)  os="darwin" ;;
  freebsd) os="freebsd" ;;
  msys*|mingw*|cygwin*) echo "Windows detected—use the PowerShell script."; exit 1 ;;
  *) echo "Unsupported OS: $os_raw"; exit 1 ;;
esac

case "$arch_raw" in
  x86_64)    arch="amd64" ;;
  aarch64)   arch="arm64" ;;
  arm64)     arch="arm64" ;;
  armv7l)    arch="armv7" ;;
  armv6l)    arch="armv6" ;;
  i386|i686) arch="386" ;;
  mips64el)  arch="mips64le" ;;
  mips64)    arch="mips64" ;;
  mipsel)    arch="mipsle" ;;
  mips)      arch="mips" ;;
  ppc64le)   arch="ppc64le" ;;
  ppc64)     arch="ppc64" ;;
  *) echo "Unsupported/unknown arch: $arch_raw"; exit 1 ;;
esac

# --- choose release API endpoint ---
if [[ "$version" == "latest" ]]; then
  api_url="https://api.github.com/repos/${REPO}/releases/latest"
  ver_label="latest"
else
  api_url="https://api.github.com/repos/${REPO}/releases/tags/v${version}"
  ver_label="v${version}"
fi

# --- find matching asset via API ---
url=$(
  curl -s "$api_url" \
    | jq -r --arg os "$os" --arg arch "$arch" '
        .assets[] | select(
          (.name | test($os)) and (.name | test($arch))
        ) | .browser_download_url
      ' | head -n1
)

if [[ -z "${url}" || "${url}" == "null" ]]; then
  echo "❌ No matching asset found for ${os}-${arch} (version: ${ver_label})"
  exit 1
fi

if $check; then
  echo "OS:    $os"
  echo "Arch:  $arch"
  echo "Ver:   $ver_label"
  echo "URL:   $url"
  exit 0
fi

echo "Downloading: $url"
outfile="$(basename "$url")"
curl -sSL "$url" -o "$outfile"

# --- extract ---
case "$outfile" in
  *.tar.gz|*.tgz) tar -xzf "$outfile" ;;
  *.zip)
    if ! command -v unzip >/dev/null 2>&1; then
      echo "❌ 'unzip' not found (required for .zip archives). Install it and retry."
      exit 1
    fi
    unzip -o "$outfile"
    ;;
  *) echo "❌ Unknown archive format: $outfile"; exit 1 ;;
esac

rm -f "$outfile"
echo "✅ Extracted files into: $(pwd)"

# --- optional install ---
if $install; then
  # elevate only if needed
  if [ "$(id -u)" -ne 0 ]; then
    echo "Re-running install step with sudo..."
    exec sudo "$0" --version "${version}" --install
  fi

  if [[ ! -f "./ctrld" ]]; then
    # some archives may place binary under a folder—try to locate it
    binpath=$(find . -maxdepth 2 -type f -name ctrld -perm -u+x | head -n1 || true)
    [[ -n "$binpath" ]] || { echo "❌ 'ctrld' binary not found after extraction."; exit 1; }
  else
    binpath="./ctrld"
  fi

  echo "Installing to ${INSTALL_DIR} ..."
  install -m 0755 -D "$binpath" "${INSTALL_DIR}/ctrld"
  echo "✅ Installed: ${INSTALL_DIR}/ctrld"
  echo "Version: $(${INSTALL_DIR}/ctrld --version || true)"
else
  echo "ℹ️ Install skipped. Use --install to move 'ctrld' into ${INSTALL_DIR}."
fi

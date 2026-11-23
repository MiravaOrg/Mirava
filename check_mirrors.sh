#!/bin/sh
# Mirava portable single-file launcher + cross-distribution optimizer
# Enhancements by FarshidSar

if [ "${1:-}" != "--__mirava_bash" ]; then
  set -eu
  say() { printf '%s\n' "$*"; }
  die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
  have() { command -v "$1" >/dev/null 2>&1; }
  ca_bundle_present() {
    for f in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt /etc/ssl/ca-bundle.pem /etc/ssl/cert.pem; do
      [ -s "$f" ] && return 0
    done
    return 1
  }
  root_run() {
    if [ "$(id -u)" -eq 0 ]; then "$@"
    elif have sudo; then sudo "$@"
    elif have doas; then doas "$@"
    else return 126
    fi
  }
  detect_pm() {
    for pm in apt-get dnf yum microdnf pacman apk zypper; do
      if have "$pm"; then printf '%s\n' "$pm"; return 0; fi
    done
    return 1
  }
  bootstrap_packages() {
    pm="$1"
    case "$pm" in
      apt-get) root_run apt-get update >/dev/null 2>&1 && root_run env DEBIAN_FRONTEND=noninteractive apt-get install -y bash curl ca-certificates >/dev/null 2>&1 ;;
      dnf) root_run dnf install -y bash curl ca-certificates >/dev/null 2>&1 ;;
      yum) root_run yum install -y bash curl ca-certificates >/dev/null 2>&1 ;;
      microdnf) root_run microdnf install -y bash curl ca-certificates >/dev/null 2>&1 ;;
      pacman) root_run pacman -S --needed --noconfirm bash curl ca-certificates >/dev/null 2>&1 ;;
      apk) root_run apk add --no-cache bash curl ca-certificates >/dev/null 2>&1 ;;
      zypper) root_run zypper --non-interactive install bash curl ca-certificates >/dev/null 2>&1 ;;
      *) return 1 ;;
    esac
  }
  if ! have bash || ! have curl || ! ca_bundle_present; then
    pm="$(detect_pm || true)"
    [ -n "$pm" ] || die "Required bootstrap tools are missing and no supported package manager was found."
    say "Mirava: installing bootstrap dependencies with $pm ..."
    bootstrap_packages "$pm" || die "Could not install bash/curl/ca-certificates automatically. Run as root or install them manually."
  fi
  exec bash "$0" --__mirava_bash "$@"
fi
shift
set -Eeuo pipefail

# Mirava cross-distribution mirror/DNS optimizer
# Interactive/cross-distro enhancements by FarshidSar

readonly MIRAVA_VERSION="3.4.1"
readonly MIRROR_URL="https://raw.githubusercontent.com/MiravaOrg/Mirava/refs/heads/main/mirrors_list.yaml"
readonly BACKUP_ROOT="/var/backups/mirava"
readonly STATE_ROOT="/var/lib/mirava"
readonly MAX_PARALLEL="${MIRAVA_JOBS:-8}"
readonly BENCHMARK_RUNS="${MIRAVA_BENCH_RUNS:-2}"

if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
  C_RESET=$'\033[0m'; C_RED=$'\033[0;31m'; C_GREEN=$'\033[0;32m'
  C_YELLOW=$'\033[0;33m'; C_BLUE=$'\033[0;34m'; C_CYAN=$'\033[0;36m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_CYAN=""; C_BOLD=""
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
if [[ -n "${MIRAVA_MIRROR_FILE:-}" ]]; then
  MIRROR_FILE="$MIRAVA_MIRROR_FILE"
elif [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/mirrors_list.yaml" ]]; then
  MIRROR_FILE="$SCRIPT_DIR/mirrors_list.yaml"
elif [[ -f /usr/share/mirava/mirrors_list.yaml ]]; then
  MIRROR_FILE="/usr/share/mirava/mirrors_list.yaml"
elif [[ -f ./mirrors_list.yaml ]]; then
  MIRROR_FILE="./mirrors_list.yaml"
else
  MIRROR_FILE="${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}/mirava/mirrors_list.yaml"
fi
PYTHON_BIN=""
SYSTEM_ID="unknown"
SYSTEM_LIKE=""
SYSTEM_VERSION=""
SYSTEM_CODENAME=""
SYSTEM_PRETTY=""
SYSTEM_PACKAGE=""
SYSTEM_BACKEND=""
SYSTEM_APPLY_SUPPORTED=0
BEST_MIRROR_ROW=""
BEST_DNS_1=""
BEST_DNS_2=""
NETINFO_LOADED=0
PUBLIC_IP="Unavailable"
PUBLIC_LOCATION="Unavailable"
PUBLIC_ISP="Unavailable"

# Package roots relative to a general mirror root. Resolver code also probes
# alternate/common layouts before accepting a candidate.
declare -A PACKAGE_PATHS=(
  ["Ubuntu"]="ubuntu" ["Debian"]="debian" ["Arch Linux"]="archlinux" ["ArchLinux"]="archlinux"
  ["PyPI"]="pypi" ["npm"]="npm" ["CentOS"]="centos" ["Alpine"]="alpine" ["Composer"]="packages.json"
  ["Composer/Packagist"]="packages.json" ["Docker Registry"]="v2/" ["Homebrew"]="brew" ["AlmaLinux"]="almalinux"
  ["Fedora"]="fedora" ["Rocky"]="rocky" ["Rocky Linux"]="rocky" ["Kali"]="kali" ["Manjaro"]="manjaro"
  ["Mint"]="linuxmint" ["LinuxMint"]="linuxmint" ["OpenSUSE"]="opensuse" ["FreeBSD"]="freebsd" ["EPEL"]="epel"
  ["Fedora EPEL"]="epel" ["MariaDB"]="mariadb" ["MongoDB"]="mongodb" ["Node.js"]="node" ["Zabbix"]="zabbix"
  ["Proxmox"]="proxmox" ["Termux"]="termux" ["Void Linux"]="void" ["Go"]="golang" ["Python"]="python"
  ["Maven"]="maven" ["NuGet"]="nuget" ["Docker"]="v2/" ["Yarn"]="yarn" ["APT"]="apt" ["RPM"]="rpm"
  ["pip"]="pip" ["Gradle"]="gradle" ["Android SDK"]="android" ["CTAN"]="ctan" ["R"]="CRAN" ["OmniOS"]="omnios"
  ["PHP"]="php" ["Terraform"]="terraform" ["Oracle Linux"]="oraclelinux" ["TorProject"]="tor" ["Tor Project"]="tor"
  ["F-Droid"]="fdroid" ["Chaotic-AUR"]="chaotic-aur" ["Dart Pub"]="dart-pub" ["Flutter packages"]="flutter"
  ["Maven Central"]="maven2" ["Google Maven"]="google-maven" ["DeltaChat"]="deltachat" ["OpenBSD"]="openbsd"
  ["RHEL"]="rhel" ["Windows"]="windows" ["Windows Server"]="windowsserver" ["YUM/DNF (CentOS, Fedora, Rocky)"]="centos"
  ["Linux kernel"]="kernel" ["Kernel"]="kernel" ["Elastic Registry"]="v2/" ["Google Registry"]="v2/"
  ["Microsoft Registry"]="v2/" ["Quay Registry"]="v2/" ["JitPack"]="jitpack" ["Java Dev"]="java-dev"
  ["Java Runtime"]="java-runtime" ["CPAN"]="CPAN" ["Cygwin"]="cygwin" ["Debian backports"]="debian"
  ["Gentoo"]="gentoo" ["Gentoo Portage"]="gentoo-portage" ["KDE"]="kde" ["NetBSD"]="NetBSD"
  ["Raspbian"]="raspbian" ["Ubuntu ports"]="ubuntu-ports" ["Ubuntu CD images"]="ubuntu-cd"
  ["Ubuntu releases"]="ubuntu-releases"
)

info()    { printf '%bℹ%b  %s\n' "$C_BLUE" "$C_RESET" "$*"; }
success() { printf '%b✅%b %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()    { printf '%b⚠%b  %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
error()   { printf '%b❌%b %s\n' "$C_RED" "$C_RESET" "$*" >&2; }

PROGRESS_LAST_DONE=-1
PROGRESS_SPINNER_INDEX=0
readonly -a PROGRESS_SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

progress_reset() {
  PROGRESS_LAST_DONE=-1
  PROGRESS_SPINNER_INDEX=0
}

progress_mark_start() {
  local dir="$1" idx="$2" label="$3"
  printf '%s\n' "$label" > "$dir/$idx.active"
}

progress_mark_done() {
  local dir="$1" idx="$2" state="$3" label="$4"
  rm -f "$dir/$idx.active"
  printf '%s|%s\n' "$state" "$label" > "$dir/$idx.done"
}

terminal_columns() {
  local cols="${COLUMNS:-}"
  if [[ ! "$cols" =~ ^[0-9]+$ ]] && have tput; then
    cols="$(tput cols 2>/dev/null || true)"
  fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  (( cols < 40 )) && cols=40
  (( cols > 180 )) && cols=180
  printf '%s\n' "$cols"
}

progress_render() {
  local dir="$1" total="$2" launched="$3" title="$4" force="${5:-0}"
  local done=0 ok=0 failed=0 active=0 left=0 queued=0 pct=0 filled=0 empty=0
  local spinner current="" bar_fill="" bar_empty="" i cols bar_width line
  local -a done_files=() result_files=() active_files=()
  shopt -s nullglob
  done_files=("$dir"/*.done)
  result_files=("$dir"/*.result)
  active_files=("$dir"/*.active)
  shopt -u nullglob
  done=${#done_files[@]}
  ok=${#result_files[@]}
  failed=$((done - ok)); (( failed < 0 )) && failed=0
  active=${#active_files[@]}
  left=$((total - done)); (( left < 0 )) && left=0
  queued=$((total - launched)); (( queued < 0 )) && queued=0
  (( total > 0 )) && pct=$((done * 100 / total))
  if (( active > 0 )); then current="$(head -n1 "${active_files[0]}" 2>/dev/null || true)"; fi
  spinner="${PROGRESS_SPINNER[$PROGRESS_SPINNER_INDEX]}"
  PROGRESS_SPINNER_INDEX=$(((PROGRESS_SPINNER_INDEX + 1) % ${#PROGRESS_SPINNER[@]}))

  if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then
    cols="$(terminal_columns)"
    if (( cols >= 90 )); then bar_width=18
    elif (( cols >= 68 )); then bar_width=14
    elif (( cols >= 52 )); then bar_width=10
    else bar_width=0
    fi

    if (( bar_width > 0 )); then
      filled=$((pct * bar_width / 100)); empty=$((bar_width - filled))
      for ((i=0; i<filled; i++)); do bar_fill+='█'; done
      for ((i=0; i<empty; i++)); do bar_empty+='░'; done
      line="$spinner [$bar_fill$bar_empty] $done/$total ${pct}% | ✓$ok ✗$failed | $left left"
    else
      line="$spinner $done/$total ${pct}% | ✓$ok ✗$failed | $left left"
    fi

    if (( cols >= 88 )); then line+=" | $active active"; fi
    if (( cols >= 112 )) && [[ -n "$current" ]]; then line+=" | ${title}: ${current:0:24}"; fi

    # Formats above are intentionally shorter than their terminal-width tier,
    # so carriage-return updates stay on one row without Unicode byte truncation.
    printf '\r\033[2K%s' "$line"
  elif (( force == 1 || done != PROGRESS_LAST_DONE )); then
    printf '[%3d%%] %d/%d checked | ok=%d failed=%d active=%d left=%d\n' "$pct" "$done" "$total" "$ok" "$failed" "$active" "$left"
  fi
  PROGRESS_LAST_DONE=$done
}

progress_finish() {
  progress_render "$1" "$2" "$3" "$4" 0
  if [[ -t 1 && "${TERM:-dumb}" != "dumb" ]]; then printf '\n'; fi
}

have() { command -v "$1" >/dev/null 2>&1; }

pause_screen() {
  [[ -t 0 ]] || return 0
  printf '\nPress Enter to continue...'
  read -r _ || true
}

confirm() {
  local prompt="$1" answer
  [[ -t 0 ]] || return 1
  printf '%s [y/N]: ' "$prompt"
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

root_run() {
  if (( EUID == 0 )); then
    "$@"
  elif have sudo; then
    sudo "$@"
  elif have doas; then
    doas "$@"
  else
    return 126
  fi
}

require_root_access() {
  if (( EUID == 0 )); then return 0; fi
  if have sudo || have doas; then return 0; fi
  error "This action changes system configuration and needs root privileges (root/sudo/doas)."
  return 1
}

systemd_active() {
  have systemctl && systemctl is-active --quiet "$1" 2>/dev/null
}

detect_package_manager() {
  local pm
  if [[ -n "${MIRAVA_PACKAGE_MANAGER:-}" ]]; then printf '%s\n' "$MIRAVA_PACKAGE_MANAGER"; return 0; fi
  for pm in apt-get dnf yum microdnf pacman apk zypper; do
    if have "$pm"; then printf '%s\n' "$pm"; return 0; fi
  done
  return 1
}

install_os_packages() {
  local pm="$1"; shift
  require_root_access || return 1
  case "$pm" in
    apt-get)
      root_run env DEBIAN_FRONTEND=noninteractive apt-get update -y || return 1
      root_run env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
      ;;
    dnf) root_run dnf install -y "$@" ;;
    yum) root_run yum install -y "$@" ;;
    microdnf) root_run microdnf install -y "$@" ;;
    pacman)
      # Deliberately avoid `pacman -Sy` to prevent a partial-upgrade state.
      root_run pacman -S --needed --noconfirm "$@"
      ;;
    apk) root_run apk add --no-cache "$@" ;;
    zypper) root_run zypper --non-interactive install "$@" ;;
    *) return 1 ;;
  esac
}

ensure_dig() {
  have dig && return 0
  local pm pkg
  pm="$(detect_package_manager || true)"
  case "$pm" in
    apt-get) pkg="dnsutils" ;;
    dnf|yum|microdnf) pkg="bind-utils" ;;
    pacman) pkg="bind" ;;
    apk) pkg="bind-tools" ;;
    zypper) pkg="bind-utils" ;;
    *) error "'dig' is missing and no supported package manager was detected."; return 1 ;;
  esac
  info "Installing DNS benchmark dependency '$pkg' with $pm ..."
  if ! install_os_packages "$pm" "$pkg"; then
    error "Automatic installation of '$pkg' failed. DNS benchmarking is unavailable until 'dig' is installed."
    return 1
  fi
  have dig || { error "'dig' is still unavailable after installation."; return 1; }
  success "Installed DNS benchmark dependency."
}

ensure_python() {
  local pm pkg candidate
  for candidate in python3 python; do
    if have "$candidate" && "$candidate" -c 'import sys; raise SystemExit(sys.version_info.major != 3)' >/dev/null 2>&1; then
      PYTHON_BIN="$(command -v "$candidate")"
      return 0
    fi
  done

  pm="$(detect_package_manager || true)"
  case "$pm" in
    apt-get|dnf|yum|microdnf|apk|zypper) pkg="python3" ;;
    pacman) pkg="python" ;;
    *) error "Python 3 is missing and no supported package manager was detected."; return 1 ;;
  esac
  info "Installing Python 3 dependency '$pkg' with $pm ..."
  install_os_packages "$pm" "$pkg" || { error "Automatic Python 3 installation failed."; return 1; }
  for candidate in python3 python; do
    if have "$candidate" && "$candidate" -c 'import sys; raise SystemExit(sys.version_info.major != 3)' >/dev/null 2>&1; then
      PYTHON_BIN="$(command -v "$candidate")"
      success "Installed Python 3 dependency."
      return 0
    fi
  done
  error "Python 3 is still unavailable after installation."
  return 1
}

dataq() {
  "$PYTHON_BIN" - "$MIRROR_FILE" "$@" <<'PY'
from __future__ import annotations
import sys
from pathlib import Path

def scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == "'":
        return value[1:-1].replace("''", "'")
    if len(value) >= 2 and value[0] == value[-1] == '"':
        return value[1:-1].replace(r'\\"', '"').replace(r'\\\\', '\\')
    return value

def load(path: str):
    mirrors, dns = [], []
    section = current = list_key = None
    for raw in Path(path).read_text(encoding='utf-8', errors='replace').splitlines():
        if not raw.strip() or raw.lstrip().startswith('#'):
            continue
        if raw and not raw[0].isspace() and raw.endswith(':') and not raw.startswith('-'):
            section, current, list_key = raw[:-1].strip(), None, None
            continue
        stripped = raw.strip()
        if section == 'mirrors':
            if raw.startswith('- name:'):
                current = {'name': scalar(raw.split(':',1)[1]), 'url':'', 'packages':[]}
                mirrors.append(current); list_key = None; continue
            if current is None: continue
            if raw.startswith('  url:'):
                current['url'] = scalar(raw.split(':',1)[1]); list_key = None
            elif raw.startswith('  packages:'):
                list_key = 'packages'
            elif raw.startswith('  - ') and list_key == 'packages':
                current['packages'].append(scalar(stripped[2:]))
            elif raw.startswith('  ') and not raw.startswith('  - '):
                list_key = None
        elif section == 'dns_servers':
            if raw.startswith('- name:'):
                current = {'name': scalar(raw.split(':',1)[1]), 'categories':[], 'servers':[]}
                dns.append(current); list_key = None; continue
            if current is None: continue
            if raw.startswith('  categories:'):
                list_key = 'categories'
            elif raw.startswith('  servers:'):
                list_key = 'servers'
            elif raw.startswith('  category:'):
                current['categories'] = [scalar(raw.split(':',1)[1])]; list_key = None
            elif raw.startswith('  - ') and list_key in ('categories','servers'):
                current[list_key].append(scalar(stripped[2:]))
            elif raw.startswith('  ') and not raw.startswith('  - '):
                list_key = None
    return mirrors, dns

def die(msg, code=2):
    print(msg, file=sys.stderr); raise SystemExit(code)

if len(sys.argv) < 3:
    die('data query requires FILE COMMAND')
path, command, *args = sys.argv[1:]
mirrors, dns = load(path)
if command == 'validate':
    errors=[]
    if not mirrors: errors.append('no mirrors found')
    if not dns: errors.append('no DNS entries found')
    bad=[m for m in mirrors if not m['name'] or not m['url'] or not m['packages']]
    if bad: errors.append(f'invalid mirror entries: {len(bad)}')
    norm=[m['url'].rstrip('/').lower() for m in mirrors]
    if len(norm) != len(set(norm)): errors.append('duplicate mirror URLs found')
    ips=[s for d in dns for s in d.get('servers',[])]
    if len(ips) != len(set(ips)): errors.append('duplicate DNS IPs found')
    badcats=[d['name'] for d in dns if not d.get('categories') or not d.get('servers')]
    if badcats: errors.append('invalid DNS groups: ' + ', '.join(badcats))
    if errors: die('; '.join(errors), 1)
    print('ok')
elif command == 'mirror-count':
    print(len(mirrors))
elif command == 'mirror-field':
    idx, field = int(args[0]), args[1]
    value = mirrors[idx][field]
    print('\n'.join(value) if isinstance(value, list) else value)
elif command == 'mirror-package-count':
    print(len(mirrors[int(args[0])]['packages']))
elif command == 'mirror-package':
    print(mirrors[int(args[0])]['packages'][int(args[1])])
elif command == 'list-packages':
    for package in sorted({p for m in mirrors for p in m['packages']}, key=str.casefold):
        print(package)
elif command == 'candidates':
    package=args[0]
    seen=set()
    for m in mirrors:
        if package in m['packages']:
            key=m['url'].rstrip('/').lower()
            if key not in seen:
                seen.add(key); print(f"{m['name']}|{m['url']}")
elif command == 'dns-rows':
    for entry in dns:
        cats=','.join(entry.get('categories') or [])
        for server in entry.get('servers',[]):
            print(f"{entry['name']}\t{cats}\t{server}")
elif command == 'stats':
    packages={p for m in mirrors for p in m['packages']}
    all_dns={s for d in dns for s in d.get('servers',[])}
    local={s for d in dns if 'local' in d.get('categories',[]) for s in d.get('servers',[])}
    global_={s for d in dns if 'global' in d.get('categories',[]) for s in d.get('servers',[])}
    print(f'mirrors={len(mirrors)}')
    print(f'package_types={len(packages)}')
    print(f'dns_unique={len(all_dns)}')
    print(f'dns_local={len(local)}')
    print(f'dns_global={len(global_)}')
else:
    die(f'unknown data command: {command}')
PY
}
check_resource() {
  local file="$1" url="$2"
  [[ -f "$file" ]] && return 0
  info "Mirror data was not found; downloading current Mirava data ..."
  mkdir -p "$(dirname "$file")"
  curl -fsSL "$url" -o "$file" || { error "Could not download $url"; return 1; }
}

load_system_info() {
  local id_like_lc
  local os_release_file="${MIRAVA_OS_RELEASE_FILE:-/etc/os-release}"
  if [[ -r "$os_release_file" ]]; then
    # shellcheck disable=SC1090
    source "$os_release_file"
    SYSTEM_ID="${ID:-unknown}"
    SYSTEM_LIKE="${ID_LIKE:-}"
    SYSTEM_VERSION="${VERSION_ID:-}"
    SYSTEM_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
    SYSTEM_PRETTY="${PRETTY_NAME:-${NAME:-$SYSTEM_ID} ${VERSION_ID:-}}"
  fi
  SYSTEM_BACKEND="$(detect_package_manager || true)"
  SYSTEM_APPLY_SUPPORTED=0

  case "$SYSTEM_ID" in
    ubuntu) SYSTEM_PACKAGE="Ubuntu"; SYSTEM_APPLY_SUPPORTED=1 ;;
    debian) SYSTEM_PACKAGE="Debian"; SYSTEM_APPLY_SUPPORTED=1 ;;
    fedora) SYSTEM_PACKAGE="Fedora"; SYSTEM_APPLY_SUPPORTED=1 ;;
    rocky) SYSTEM_PACKAGE="Rocky"; SYSTEM_APPLY_SUPPORTED=1 ;;
    almalinux) SYSTEM_PACKAGE="AlmaLinux"; SYSTEM_APPLY_SUPPORTED=1 ;;
    centos) SYSTEM_PACKAGE="CentOS"; SYSTEM_APPLY_SUPPORTED=1 ;;
    arch) SYSTEM_PACKAGE="Arch Linux"; SYSTEM_APPLY_SUPPORTED=1 ;;
    manjaro) SYSTEM_PACKAGE="Manjaro"; SYSTEM_APPLY_SUPPORTED=1 ;;
    alpine) SYSTEM_PACKAGE="Alpine"; SYSTEM_APPLY_SUPPORTED=1 ;;
    opensuse*|opensuse-leap|opensuse-tumbleweed) SYSTEM_PACKAGE="OpenSUSE"; SYSTEM_APPLY_SUPPORTED=1 ;;
    *)
      id_like_lc=" ${SYSTEM_LIKE,,} "
      if [[ "$id_like_lc" == *" ubuntu "* ]]; then
        SYSTEM_PACKAGE="Ubuntu"
        # Ubuntu derivatives (for example Linux Mint) often use their own
        # VERSION_CODENAME but expose the upstream suite in UBUNTU_CODENAME.
        # Use the upstream suite for benchmark validation; auto-apply remains
        # disabled for derivatives to avoid overwriting distro-specific repos.
        SYSTEM_CODENAME="${UBUNTU_CODENAME:-$SYSTEM_CODENAME}"
      elif [[ "$id_like_lc" == *" debian "* ]]; then SYSTEM_PACKAGE="Debian"
      elif [[ "$id_like_lc" == *" fedora "* ]]; then SYSTEM_PACKAGE="Fedora"
      elif [[ "$id_like_lc" == *" arch "* ]]; then SYSTEM_PACKAGE="Arch Linux"
      elif [[ "$id_like_lc" == *" suse "* ]]; then SYSTEM_PACKAGE="OpenSUSE"
      fi
      ;;
  esac
}

init() {
  have curl || { error "curl is required. Run via check_mirrors.sh so it can bootstrap dependencies."; exit 1; }
  if [[ ! "$MAX_PARALLEL" =~ ^[1-9][0-9]*$ ]]; then
    error "MIRAVA_JOBS must be a positive integer."
    exit 2
  fi
  if [[ ! "$BENCHMARK_RUNS" =~ ^[1-9][0-9]*$ ]] || (( BENCHMARK_RUNS > 5 )); then
    error "MIRAVA_BENCH_RUNS must be an integer from 1 to 5."
    exit 2
  fi
  check_resource "$MIRROR_FILE" "$MIRROR_URL" || exit 1
  ensure_python || exit 1
  load_system_info
}

repeat_char() {
  local char="$1" count="$2" out
  printf -v out '%*s' "$count" ''
  printf '%s' "${out// /$char}"
}

compact_lines() {
  local limit="${1:-0}"
  awk -v limit="$limit" 'NF { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); if (!seen[$0]++) { count++; if (!limit || count<=limit) out=out (out ? ", " : "") $0 } } END { if (limit && count>limit) out=out " (+" (count-limit) " more)"; print out }'
}

collect_current_dns() {
  local result=""
  if have resolvectl; then
    result="$(resolvectl dns 2>/dev/null \
      | sed -nE '/: / {s/^[^:]+: //; p}' \
      | tr ' ' '\n' \
      | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9A-Fa-f]*:[0-9A-Fa-f:.]+$' \
      | compact_lines 4 || true)"
  fi
  if [[ -z "$result" ]] && have nmcli; then
    result="$(nmcli -t -f IP4.DNS,IP6.DNS device show 2>/dev/null \
      | sed -E 's/^[^:]*://' \
      | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9A-Fa-f]*:[0-9A-Fa-f:.]+$' \
      | compact_lines 4 || true)"
  fi
  if [[ -z "$result" && -r /etc/resolv.conf ]]; then
    result="$(awk '/^nameserver[[:space:]]+/ {print $2}' /etc/resolv.conf \
      | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^[0-9A-Fa-f]*:[0-9A-Fa-f:.]+$' \
      | compact_lines 4 || true)"
  fi
  printf '%s\n' "${result:-Not detected}"
}

apt_repo_urls() {
  local f
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/mirava.sources /etc/apt/sources.list.d/mirava.list /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list; do
    [[ -r "$f" ]] || continue
    awk '
      /^[[:space:]]*#/ {next}
      /^[[:space:]]*URIs:[[:space:]]+/ {sub(/^[[:space:]]*URIs:[[:space:]]+/, ""); for(i=1;i<=NF;i++) print $i; next}
      /^[[:space:]]*deb[[:space:]]+/ {
        i=2
        if ($i ~ /^\[/) { while (i<=NF && $i !~ /\]$/) i++; i++ }
        if (i<=NF) print $i
      }
    ' "$f" 2>/dev/null || true
  done
}

rpm_repo_urls() {
  local f key value
  for f in /etc/yum.repos.d/mirava.repo /etc/yum.repos.d/*.repo /etc/zypp/repos.d/mirava.repo /etc/zypp/repos.d/*.repo; do
    [[ -r "$f" ]] || continue
    while IFS='=' read -r key value; do
      [[ "$key" =~ ^[[:space:]]*(baseurl|mirrorlist|metalink)[[:space:]]*$ ]] || continue
      value="${value%%#*}"
      value="${value#${value%%[![:space:]]*}}"
      value="${value%${value##*[![:space:]]}}"
      [[ -n "$value" ]] && printf '%s\n' "$value"
    done < "$f"
  done
}

current_repo_summary() {
  local result=""
  case "$SYSTEM_BACKEND" in
    apt-get)
      result="$(apt_repo_urls \
        | grep -vEi 'download\.docker\.com|packages\.microsoft\.com|deb\.nodesource\.com|apt\.releases\.hashicorp\.com' \
        | compact_lines 2 || true)"
      ;;
    dnf|yum|microdnf|zypper) result="$(rpm_repo_urls | grep -vi docker | compact_lines 2 || true)" ;;
    pacman)
      result="$(awk -F= '/^[[:space:]]*Server[[:space:]]*=/ {v=$2; sub(/^[[:space:]]+/, "", v); print v}' /etc/pacman.d/mirrorlist 2>/dev/null | compact_lines 2)"
      ;;
    apk)
      result="$(awk 'NF && $1 !~ /^#/ && $1 ~ /^https?:\/\// {print $1}' /etc/apk/repositories 2>/dev/null | compact_lines 2)"
      ;;
  esac
  printf '%s\n' "${result:-Not detected}"
}

docker_registry_summary() {
  local f result=""
  for f in /etc/docker/daemon.json "${HOME:-/nonexistent}/.docker/daemon.json"; do
    [[ -r "$f" ]] || continue
    result="$($PYTHON_BIN - "$f" <<'PYDOCKER' 2>/dev/null || true
import json, sys
try:
    with open(sys.argv[1], encoding='utf-8') as fh:
        data = json.load(fh)
    mirrors = data.get('registry-mirrors') or []
    print(', '.join(str(x) for x in mirrors if x))
except Exception:
    pass
PYDOCKER
)"
    [[ -n "$result" ]] && break
  done
  if [[ -n "$result" ]]; then
    printf '%s\n' "$result"
  else
    printf '%s\n' 'Docker Hub (registry-1.docker.io) - default/no mirror configured'
  fi
}

docker_package_repo_summary() {
  local result="" f
  case "$SYSTEM_BACKEND" in
    apt-get)
      result="$({
        for f in /etc/apt/sources.list /etc/apt/sources.list.d/*docker*.list /etc/apt/sources.list.d/*docker*.sources; do
          [[ -r "$f" ]] || continue
          awk '
            /^[[:space:]]*#/ {next}
            /^[[:space:]]*URIs:[[:space:]]+/ {sub(/^[[:space:]]*URIs:[[:space:]]+/, ""); for(i=1;i<=NF;i++) print $i; next}
            /^[[:space:]]*deb[[:space:]]+/ && /docker/ {
              i=2
              if ($i ~ /^\[/) { while (i<=NF && $i !~ /\]$/) i++; i++ }
              if (i<=NF) print $i
            }
          ' "$f" 2>/dev/null || true
        done
      } | grep -i docker | compact_lines)"
      ;;
    dnf|yum|microdnf|zypper)
      result="$(grep -hEi '^[[:space:]]*(baseurl|mirrorlist|metalink)[[:space:]]*=' /etc/yum.repos.d/*docker*.repo /etc/zypp/repos.d/*docker*.repo 2>/dev/null | cut -d= -f2- | grep -i docker | compact_lines || true)"
      ;;
  esac
  printf '%s\n' "${result:-Not configured/detected}"
}

fetch_public_netinfo() {
  (( NETINFO_LOADED == 1 )) && return 0
  NETINFO_LOADED=1
  [[ "${MIRAVA_SKIP_NETINFO:-0}" == "1" ]] && return 0
  local json parsed fallback_ip
  json="$(curl -fsSL --connect-timeout 2 --max-time 4 https://ipwho.is/ 2>/dev/null || true)"
  if [[ -n "$json" ]]; then
    parsed="$($PYTHON_BIN -c 'import json,sys; d=json.load(sys.stdin); ok=d.get("success", True); ip=d.get("ip", "") if ok else ""; parts=[d.get("city"), d.get("country")]; loc=", ".join(str(x) for x in parts if x); isp=((d.get("connection") or {}).get("isp") or ""); clean=lambda x:str(x).replace("|","/").replace("\\t"," ").replace("\\n"," "); print("|".join(map(clean,[ip,loc,isp])))' <<< "$json" 2>/dev/null || true)"
    if [[ -n "$parsed" ]]; then
      IFS='|' read -r PUBLIC_IP PUBLIC_LOCATION PUBLIC_ISP <<< "$parsed"
    fi
  fi
  if [[ -z "$PUBLIC_IP" || "$PUBLIC_IP" == "Unavailable" ]]; then
    fallback_ip="$(curl -fsSL --connect-timeout 2 --max-time 3 https://api.ipify.org 2>/dev/null || true)"
    [[ -n "$fallback_ip" ]] && PUBLIC_IP="$fallback_ip"
  fi
  [[ -n "$PUBLIC_IP" ]] || PUBLIC_IP="Unavailable"
  [[ -n "$PUBLIC_LOCATION" ]] || PUBLIC_LOCATION="Unavailable"
  [[ -n "$PUBLIC_ISP" ]] || PUBLIC_ISP="Unavailable"
}

format_memory() {
  if [[ -r /proc/meminfo ]]; then
    awk '/^MemTotal:/ {kb=$2; if (kb>=1048576) printf "%.1f GiB", kb/1048576; else printf "%.0f MiB", kb/1024; exit}' /proc/meminfo
  elif have sysctl; then
    local bytes
    bytes="$(sysctl -n hw.memsize 2>/dev/null || true)"
    [[ "$bytes" =~ ^[0-9]+$ ]] && awk -v b="$bytes" 'BEGIN {printf "%.1f GiB", b/1073741824}'
  fi
}

format_uptime() {
  if have uptime; then
    uptime -p 2>/dev/null \
      | sed -E 's/^up //; s/ days?/d/g; s/ hours?/h/g; s/ minutes?/m/g; s/,//g' \
      || true
  fi
}

table_row() {
  local label="$1" value="$2" lw="$3" vw="$4" first=1 chunk
  value="${value//$'\n'/ }"
  [[ -n "$value" ]] || value="-"
  while [[ -n "$value" ]]; do
    chunk="${value:0:vw}"
    value="${value:vw}"
    if (( first == 1 )); then
      printf '│ %-*s │ %-*s │\n' "$lw" "$label" "$vw" "$chunk"
      first=0
    else
      printf '│ %-*s │ %-*s │\n' "$lw" '' "$vw" "$chunk"
    fi
  done
}

table_row_single() {
  local label="$1" value="$2" lw="$3" vw="$4"
  value="${value//$'\n'/ }"
  [[ -n "$value" ]] || value="-"
  if (( ${#value} > vw )); then
    if (( vw > 3 )); then value="${value:0:$((vw-3))}..."; else value="${value:0:vw}"; fi
  fi
  printf '│ %-*s │ %-*s │\n' "$lw" "$label" "$vw" "$value"
}

system_overview() {
  local cols=92 lw=11 vw
  local hostname_value os_value arch_value mem_value uptime_value server_value system_value public_value
  local dns_value repo_value docker_pkg_value

  if have tput; then cols="$(tput cols 2>/dev/null || printf 92)"; fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=92
  (( cols < 64 )) && cols=64
  (( cols > 104 )) && cols=104
  vw=$((cols - lw - 7))

  if [[ -t 1 && "$NETINFO_LOADED" -eq 0 && "${MIRAVA_SKIP_NETINFO:-0}" != "1" ]]; then
    printf '%bGathering server overview…%b\r' "$C_CYAN" "$C_RESET"
  fi
  fetch_public_netinfo
  [[ -t 1 ]] && printf '\033[2K\r'

  hostname_value="$(hostname -s 2>/dev/null || hostname 2>/dev/null || printf unknown)"
  os_value="${SYSTEM_PRETTY:-${SYSTEM_ID} ${SYSTEM_VERSION}}"
  arch_value="$(uname -m 2>/dev/null || printf unknown)"
  mem_value="$(format_memory)"; [[ -n "$mem_value" ]] || mem_value="Unknown RAM"
  uptime_value="$(format_uptime)"; [[ -n "$uptime_value" ]] || uptime_value="unknown uptime"
  server_value="$hostname_value • $mem_value RAM • up $uptime_value"
  system_value="$os_value ($arch_value)"

  public_value="$PUBLIC_IP"
  if [[ -n "$PUBLIC_LOCATION" && "$PUBLIC_LOCATION" != "Unavailable" ]]; then
    public_value+=" • $PUBLIC_LOCATION"
  fi

  dns_value="$(collect_current_dns)"
  repo_value="$(current_repo_summary)"
  docker_pkg_value="$(docker_package_repo_summary)"
  if [[ "$docker_pkg_value" == "Not configured/detected" ]] && have docker; then
    docker_pkg_value="Distribution/default package repo"
  fi

  printf '%bSystem Overview%b\n' "$C_BOLD" "$C_RESET"
  printf '┌%s┬%s┐\n' "$(repeat_char '─' $((lw+2)))" "$(repeat_char '─' $((vw+2)))"
  table_row_single 'Server' "$server_value" "$lw" "$vw"
  table_row_single 'OS / Arch' "$system_value" "$lw" "$vw"
  table_row_single 'Public' "$public_value" "$lw" "$vw"
  printf '├%s┼%s┤\n' "$(repeat_char '─' $((lw+2)))" "$(repeat_char '─' $((vw+2)))"
  table_row_single 'DNS' "$dns_value" "$lw" "$vw"
  table_row_single 'Repo' "$repo_value" "$lw" "$vw"
  table_row_single 'Docker repo' "$docker_pkg_value" "$lw" "$vw"
  printf '└%s┴%s┘\n\n' "$(repeat_char '─' $((lw+2)))" "$(repeat_char '─' $((vw+2)))"
}

banner() {
  printf '%b' "$C_CYAN"
  cat <<'BANNER'
 __  __ _
|  \/  (_)_ __ __ ___   ____ _
| |\/| | | '__/ _` \ \ / / _` |
| |  | | | | | (_| |\ V / (_| |
|_|  |_|_|_|  \__,_| \_/ \__,_|
BANNER
  printf '%b' "$C_RESET"
  printf '%bMirava%b — cross-distro mirror & DNS optimizer v%s\n' "$C_BOLD" "$C_RESET" "$MIRAVA_VERSION"
  printf '%bOfficial:%b   https://github.com/MiravaOrg/Mirava\n' "$C_BOLD" "$C_RESET"
  printf '%bFarshidSar:%b https://github.com/farshidsar/Mirava\n\n' "$C_BOLD" "$C_RESET"
  system_overview
}

http_ok() {
  local status="$1"
  [[ "$status" =~ ^2[0-9][0-9]$ || "$status" =~ ^3[0-9][0-9]$ || "$status" == "401" ]]
}

strict_http_ok() {
  local status="$1"
  [[ "$status" =~ ^2[0-9][0-9]$ || "$status" =~ ^3[0-9][0-9]$ ]]
}

probe_status() {
  local url="$1" output
  [[ -n "$url" ]] || { printf '000'; return 0; }
  output="$(curl -L -sS -o /dev/null --connect-timeout 3 --max-time 7 -w '%{http_code}' "$url" 2>/dev/null || true)"
  printf '%s' "${output:-000}"
}

join_url() {
  local base="${1%/}" path="${2#/}"
  [[ -z "$path" ]] && { printf '%s\n' "$base"; return; }
  if [[ "${base,,}" == */"${path,,}" ]]; then printf '%s\n' "$base"; else printf '%s/%s\n' "$base" "$path"; fi
}

package_path() {
  local package="$1"
  if [[ -n "${PACKAGE_PATHS[$package]+set}" ]]; then printf '%s\n' "${PACKAGE_PATHS[$package]}"; else printf '\n'; fi
}

archive_root_ok() {
  local root="${1%/}" status
  status="$(probe_status "$root/ls-lR.gz")"; strict_http_ok "$status" && return 0
  status="$(probe_status "$root/dists/")"; strict_http_ok "$status" && return 0
  if [[ -n "$SYSTEM_CODENAME" ]]; then
    status="$(probe_status "$root/dists/$SYSTEM_CODENAME/Release")"; strict_http_ok "$status" && return 0
  fi
  return 1
}

resolve_package_root() {
  local base="${1%/}" package="$2" path candidate status alt
  path="$(package_path "$package")"

  if [[ "$package" == *"Registry"* || "$package" == "Docker" ]]; then
    [[ "$base" == */v2 ]] && { printf '%s\n' "$base"; return 0; }
    printf '%s/v2\n' "$base"; return 0
  fi

  case "$package" in
    Ubuntu)
      for alt in "" "ubuntu" "Ubuntu" "repo/Ubuntu" "repo/ubuntu" "ubuntuarchive" "ubuntu-ports" "ports"; do
        [[ -z "$alt" ]] && candidate="$base" || candidate="$(join_url "$base" "$alt")"
        if archive_root_ok "$candidate"; then printf '%s\n' "${candidate%/}"; return 0; fi
      done
      return 1
      ;;
    Debian|Kali|Mint|LinuxMint)
      for alt in "$path" ""; do
        [[ -z "$alt" ]] && candidate="$base" || candidate="$(join_url "$base" "$alt")"
        if archive_root_ok "$candidate"; then printf '%s\n' "${candidate%/}"; return 0; fi
      done
      return 1
      ;;
  esac

  if [[ -n "$path" ]]; then
    candidate="$(join_url "$base" "$path")"
    status="$(probe_status "$candidate")"
    if http_ok "$status"; then printf '%s\n' "${candidate%/}"; return 0; fi
  fi
  status="$(probe_status "$base")"
  if http_ok "$status"; then printf '%s\n' "$base"; return 0; fi
  return 1
}

repo_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'x86_64\n' ;;
    aarch64|arm64) printf 'aarch64\n' ;;
    armv7l) [[ "$SYSTEM_ID" == "arch" ]] && printf 'armv7h\n' || printf 'armv7\n' ;;
    i?86) printf 'i686\n' ;;
    *) uname -m ;;
  esac
}

apt_arch() {
  if have dpkg; then
    dpkg --print-architecture 2>/dev/null && return 0
  fi
  case "$(uname -m)" in
    x86_64|amd64) printf 'amd64\n' ;;
    aarch64|arm64) printf 'arm64\n' ;;
    armv7l|armv7*) printf 'armhf\n' ;;
    i?86) printf 'i386\n' ;;
    ppc64le) printf 'ppc64el\n' ;;
    s390x) printf 's390x\n' ;;
    riscv64) printf 'riscv64\n' ;;
    *) uname -m ;;
  esac
}

alpine_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'x86_64\n' ;;
    aarch64|arm64) printf 'aarch64\n' ;;
    armv7l) printf 'armv7\n' ;;
    armhf) printf 'armhf\n' ;;
    x86|i?86) printf 'x86\n' ;;
    ppc64le) printf 'ppc64le\n' ;;
    s390x) printf 's390x\n' ;;
    riscv64) printf 'riscv64\n' ;;
    *) uname -m ;;
  esac
}

alpine_branch() {
  local branch
  branch="$(grep -Eo '/alpine/(edge|v[0-9]+\.[0-9]+)/' /etc/apk/repositories 2>/dev/null | head -1 | cut -d/ -f3 || true)"
  if [[ -n "$branch" ]]; then printf '%s\n' "$branch"; return; fi
  if [[ -r /etc/alpine-release ]]; then
    branch="v$(cut -d. -f1,2 /etc/alpine-release)"
    printf '%s\n' "$branch"
  else
    printf 'edge\n'
  fi
}

manjaro_branch() {
  local branch=""
  if have pacman-mirrors; then branch="$(pacman-mirrors --get-branch 2>/dev/null | head -1 || true)"; fi
  [[ -n "$branch" ]] || branch="$(grep -Eo '/(stable|testing|unstable)/\$repo' /etc/pacman.d/mirrorlist 2>/dev/null | head -1 | cut -d/ -f2 || true)"
  printf '%s\n' "${branch:-stable}"
}

first_valid_url() {
  local url status
  for url in "$@"; do
    status="$(probe_status "$url")"
    if strict_http_ok "$status"; then printf '%s\n' "$url"; return 0; fi
  done
  return 1
}

apt_suite_target() {
  local root="${1%/}" suite="$2" arch="$3"
  first_valid_url \
    "$root/dists/$suite/main/binary-$arch/Packages.xz" \
    "$root/dists/$suite/main/binary-$arch/Packages.gz" \
    "$root/dists/$suite/main/binary-$arch/Release" \
    "$root/dists/$suite/InRelease" \
    "$root/dists/$suite/Release" 2>/dev/null
}

apt_suite_available() {
  local root="${1%/}" suite="$2" arch="$3" release arch_target
  release="$(first_valid_url "$root/dists/$suite/InRelease" "$root/dists/$suite/Release" 2>/dev/null || true)"
  [[ -n "$release" ]] || return 1
  arch_target="$(first_valid_url \
    "$root/dists/$suite/main/binary-$arch/Packages.xz" \
    "$root/dists/$suite/main/binary-$arch/Packages.gz" \
    "$root/dists/$suite/main/binary-$arch/Release" 2>/dev/null || true)"
  [[ -n "$arch_target" ]]
}

benchmark_target_url() {
  local root="${1%/}" package="$2" arch ver major branch target=""
  if [[ "$package" == "$SYSTEM_PACKAGE" ]]; then
    arch="$(repo_arch)"; ver="$SYSTEM_VERSION"; major="${ver%%.*}"
    case "$package" in
      Ubuntu|Debian)
        arch="$(apt_arch)"
        if [[ -n "$SYSTEM_CODENAME" ]]; then
          target="$(apt_suite_target "$root" "$SYSTEM_CODENAME" "$arch" 2>/dev/null || true)"
        fi
        [[ -n "$target" ]] || target="$(first_valid_url "$root/ls-lR.gz" 2>/dev/null || true)"
        ;;
      Fedora)
        ver="$(rpm -E %fedora 2>/dev/null | grep -E '^[0-9]+$' | head -1 || printf '%s' "$ver")"
        target="$(first_valid_url "$root/linux/releases/$ver/Everything/$arch/os/repodata/repomd.xml" "$root/releases/$ver/Everything/$arch/os/repodata/repomd.xml" 2>/dev/null || true)"
        ;;
      Rocky|Rocky\ Linux|AlmaLinux)
        target="$(first_valid_url "$root/$major/BaseOS/$arch/os/repodata/repomd.xml" "$root/$ver/BaseOS/$arch/os/repodata/repomd.xml" 2>/dev/null || true)"
        ;;
      CentOS)
        target="$(first_valid_url "$root/${major}-stream/BaseOS/$arch/os/repodata/repomd.xml" "$root/$major/BaseOS/$arch/os/repodata/repomd.xml" "$root/$major/os/$arch/repodata/repomd.xml" 2>/dev/null || true)"
        ;;
      Arch\ Linux|ArchLinux)
        target="$(first_valid_url "$root/core/os/$arch/core.db" "$root/core/os/$arch/core.db.tar.gz" 2>/dev/null || true)"
        ;;
      Manjaro)
        branch="$(manjaro_branch)"
        target="$(first_valid_url "$root/$branch/core/$arch/core.db" 2>/dev/null || true)"
        ;;
      Alpine)
        branch="$(alpine_branch)"; arch="$(alpine_arch)"
        target="$(first_valid_url "$root/$branch/main/$arch/APKINDEX.tar.gz" 2>/dev/null || true)"
        ;;
      OpenSUSE)
        if [[ "$SYSTEM_ID" == *tumbleweed* || "${SYSTEM_VERSION,,}" == *tumbleweed* ]]; then
          target="$(first_valid_url "$root/tumbleweed/repo/oss/repodata/repomd.xml" 2>/dev/null || true)"
        else
          target="$(first_valid_url "$root/distribution/leap/$ver/repo/oss/repodata/repomd.xml" 2>/dev/null || true)"
        fi
        ;;
    esac
  fi

  if [[ -z "$target" ]]; then
    case "$package" in
      Ubuntu|Debian|Kali|Mint|LinuxMint)
        target="$(first_valid_url "$root/ls-lR.gz" "$root/dists/" 2>/dev/null || true)" ;;
      Arch\ Linux|ArchLinux) target="$(first_valid_url "$root/lastsync" "$root/core/" 2>/dev/null || true)" ;;
      Alpine) target="$(first_valid_url "$root/latest-stable/" "$root/edge/" "$root/" 2>/dev/null || true)" ;;
      *) target="$(first_valid_url "$root" 2>/dev/null || true)" ;;
    esac
  fi
  [[ -n "$target" ]] || return 1
  printf '%s\n' "$target"
}

system_candidate_compatible() {
  local root="${1%/}" package="$2" arch ver major branch base app updates prefix
  [[ "$package" == "$SYSTEM_PACKAGE" ]] || return 0
  case "$package" in
    Ubuntu)
      [[ -n "$SYSTEM_CODENAME" ]] || return 1
      arch="$(apt_arch)"
      apt_suite_available "$root" "$SYSTEM_CODENAME" "$arch" || return 1
      apt_suite_available "$root" "${SYSTEM_CODENAME}-updates" "$arch" || return 1
      apt_suite_available "$root" "${SYSTEM_CODENAME}-security" "$arch" || return 1
      ;;
    Debian)
      [[ -n "$SYSTEM_CODENAME" ]] || return 1
      arch="$(apt_arch)"
      apt_suite_available "$root" "$SYSTEM_CODENAME" "$arch" || return 1
      apt_suite_available "$root" "${SYSTEM_CODENAME}-updates" "$arch" || return 1
      ;;
    Fedora)
      arch="$(repo_arch)"; ver="$(rpm -E %fedora 2>/dev/null | grep -E '^[0-9]+$' | head -1 || printf '%s' "$SYSTEM_VERSION")"
      base="$(first_valid_url "$root/linux/releases/$ver/Everything/$arch/os" "$root/releases/$ver/Everything/$arch/os" 2>/dev/null || true)"
      updates="$(first_valid_url "$root/linux/updates/$ver/Everything/$arch" "$root/updates/$ver/Everything/$arch" 2>/dev/null || true)"
      [[ -n "$base" && -n "$updates" ]] && rpm_metadata_ok "$base" && rpm_metadata_ok "$updates"
      ;;
    Rocky|Rocky\ Linux|AlmaLinux)
      arch="$(repo_arch)"; ver="$SYSTEM_VERSION"; major="${ver%%.*}"
      base="$(first_valid_url "$root/$major/BaseOS/$arch/os" "$root/$ver/BaseOS/$arch/os" 2>/dev/null || true)"
      [[ -n "$base" ]] || return 1
      prefix="${base%/BaseOS/$arch/os}"; app="$prefix/AppStream/$arch/os"
      rpm_metadata_ok "$base" && rpm_metadata_ok "$app"
      ;;
    CentOS)
      arch="$(repo_arch)"; major="${SYSTEM_VERSION%%.*}"
      base="$(first_valid_url "$root/${major}-stream/BaseOS/$arch/os" "$root/$major/BaseOS/$arch/os" "$root/$major/os/$arch" 2>/dev/null || true)"
      [[ -n "$base" ]] || return 1
      if [[ "$base" == */BaseOS/$arch/os ]]; then
        prefix="${base%/BaseOS/$arch/os}"; app="$prefix/AppStream/$arch/os"
        rpm_metadata_ok "$base" && rpm_metadata_ok "$app"
      else
        rpm_metadata_ok "$base"
      fi
      ;;
    Arch\ Linux|ArchLinux)
      arch="$(repo_arch)"
      strict_http_ok "$(probe_status "$root/core/os/$arch/core.db")" || return 1
      strict_http_ok "$(probe_status "$root/extra/os/$arch/extra.db")" || return 1
      ;;
    Manjaro)
      arch="$(repo_arch)"; branch="$(manjaro_branch)"
      strict_http_ok "$(probe_status "$root/$branch/core/$arch/core.db")" || return 1
      strict_http_ok "$(probe_status "$root/$branch/extra/$arch/extra.db")" || return 1
      ;;
    Alpine)
      arch="$(alpine_arch)"; branch="$(alpine_branch)"
      strict_http_ok "$(probe_status "$root/$branch/main/$arch/APKINDEX.tar.gz")"
      ;;
    OpenSUSE)
      ver="$SYSTEM_VERSION"
      if [[ "$SYSTEM_ID" == *tumbleweed* || "${SYSTEM_VERSION,,}" == *tumbleweed* ]]; then
        rpm_metadata_ok "$root/tumbleweed/repo/oss"
      else
        rpm_metadata_ok "$root/distribution/leap/$ver/repo/oss"
      fi
      ;;
    *) return 0 ;;
  esac
}

resolve_system_root() {
  local base="${1%/}" package="$2" alt candidate key
  local -a alts=()
  case "$package" in
    Ubuntu) alts=("" "ubuntu" "Ubuntu" "repo/Ubuntu" "repo/ubuntu" "ubuntuarchive" "ubuntu-ports" "ports") ;;
    Debian) alts=("" "debian" "Debian" "debian/debian") ;;
    Fedora) alts=("" "fedora" "Fedora" "pub/fedora") ;;
    Rocky|Rocky\ Linux) alts=("" "rocky" "Rocky" "rockylinux") ;;
    AlmaLinux) alts=("" "almalinux" "AlmaLinux") ;;
    CentOS) alts=("" "centos-stream" "centos" "CentOS") ;;
    Arch\ Linux|ArchLinux) alts=("" "archlinux" "ArchLinux") ;;
    Manjaro) alts=("" "manjaro") ;;
    Alpine) alts=("" "alpine") ;;
    OpenSUSE) alts=("" "opensuse" "openSUSE") ;;
    *) alts=("") ;;
  esac
  declare -A seen=()
  for alt in "${alts[@]}"; do
    [[ -z "$alt" ]] && candidate="$base" || candidate="$(join_url "$base" "$alt")"
    key="${candidate%/}"
    [[ -n "${seen[$key]+x}" ]] && continue
    seen[$key]=1
    if system_candidate_compatible "$candidate" "$package"; then
      printf '%s\n' "${candidate%/}"
      return 0
    fi
  done
  return 1
}

emit_package_candidates() {
  local package="$1" arch
  dataq candidates "$package"
  # Ubuntu uses the separate ports archive on several non-x86 architectures.
  # Include Mirava entries tagged as Ubuntu ports; metadata validation decides
  # whether any candidate is actually usable for this machine.
  if [[ "$package" == "Ubuntu" ]]; then
    arch="$(apt_arch 2>/dev/null || true)"
    case "$arch" in
      amd64|i386) : ;;
      *) dataq candidates "Ubuntu ports" ;;
    esac
  fi
}

check_all_mirrors() {
  local count mirror_idx name base package_count j package root status total=0 checked=0 outdir line state
  local -a details=()
  count="$(dataq mirror-count)"
  for ((mirror_idx=0; mirror_idx<count; mirror_idx++)); do
    package_count="$(dataq mirror-package-count "$mirror_idx")"
    total=$((total + package_count))
  done
  outdir="$(mktemp -d)"
  printf '\n%bChecking all registered mirror/package endpoints%b\n' "$C_BOLD" "$C_RESET"
  printf '   Mirrors: %b%s%b | Endpoint checks: %b%s%b\n\n' "$C_CYAN" "$count" "$C_RESET" "$C_CYAN" "$total" "$C_RESET"
  progress_reset
  progress_render "$outdir" "$total" 0 "Now" 1
  for ((mirror_idx=0; mirror_idx<count; mirror_idx++)); do
    name="$(dataq mirror-field "$mirror_idx" name)"
    base="$(dataq mirror-field "$mirror_idx" url)"
    package_count="$(dataq mirror-package-count "$mirror_idx")"
    for ((j=0; j<package_count; j++)); do
      checked=$((checked+1))
      package="$(dataq mirror-package "$mirror_idx" "$j")"
      progress_mark_start "$outdir" "$checked" "$name / $package"
      root="$(resolve_package_root "$base" "$package" || true)"
      if [[ -z "$root" ]]; then
        printf '%06d|FAIL|%s|%s|-|no valid package root\n' "$checked" "$name" "$package" > "$outdir/$checked.failure"
        progress_mark_done "$outdir" "$checked" failed "$name / $package"
        progress_render "$outdir" "$total" "$checked" "Now"
        continue
      fi
      status="$(probe_status "$root")"
      if http_ok "$status"; then
        printf '%06d|OK|%s|%s|%s|%s\n' "$checked" "$name" "$package" "$root" "$status" > "$outdir/$checked.result"
        progress_mark_done "$outdir" "$checked" ok "$name / $package"
      else
        printf '%06d|FAIL|%s|%s|%s|%s\n' "$checked" "$name" "$package" "$root" "$status" > "$outdir/$checked.failure"
        progress_mark_done "$outdir" "$checked" failed "$name / $package"
      fi
      progress_render "$outdir" "$total" "$checked" "Now"
    done
  done
  progress_finish "$outdir" "$total" "$checked" "Now"

  shopt -s nullglob; local detail_files=("$outdir"/*.result "$outdir"/*.failure); shopt -u nullglob
  mapfile -t details < <(cat "${detail_files[@]}" | sort -t'|' -k1,1n)
  printf '\n%-5s %-28s %-24s %-6s %s\n' "STATE" "MIRROR" "PACKAGE" "HTTP" "PACKAGE ROOT"
  printf '%*s\n' 108 '' | tr ' ' '-'
  for line in "${details[@]}"; do
    IFS='|' read -r _ state name package root status <<< "$line"
    if [[ "$state" == "OK" ]]; then
      printf '%b%-5s%b %-28.28s %-24.24s %-6s %s\n' "$C_GREEN" "OK" "$C_RESET" "$name" "$package" "$status" "$root"
    else
      printf '%b%-5s%b %-28.28s %-24.24s %-6s %s\n' "$C_RED" "FAIL" "$C_RESET" "$name" "$package" "$status" "$root"
    fi
  done
  rm -rf "$outdir"
}

list_packages() { dataq list-packages; }

choose_package() {
  local -a packages=(); local choice i
  mapfile -t packages < <(list_packages)
  printf '\n%bAvailable package/repository types%b\n' "$C_BOLD" "$C_RESET" >&2
  for i in "${!packages[@]}"; do printf '  %3d) %s\n' "$((i+1))" "${packages[$i]}" >&2; done
  printf 'Select a package [1-%d]: ' "${#packages[@]}" >&2
  read -r choice
  if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#packages[@]} )); then error "Invalid package selection."; return 1; fi
  printf '%s\n' "${packages[$((choice-1))]}"
}

wait_for_slot() {
  local dir="${1:-}" total="${2:-0}" launched="${3:-0}" title="${4:-Testing}" running
  while true; do
    running="$(jobs -rp | wc -l | tr -d ' ')"
    if (( running < MAX_PARALLEL )); then return 0; fi
    [[ -n "$dir" && "$total" -gt 0 ]] && progress_render "$dir" "$total" "$launched" "$title"
    sleep 0.08
  done
}

wait_for_progress_jobs() {
  local dir="$1" total="$2" launched="$3" title="$4" running
  while true; do
    running="$(jobs -rp | wc -l | tr -d ' ')"
    progress_render "$dir" "$total" "$launched" "$title"
    (( running == 0 )) && break
    sleep 0.08
  done
  wait || true
  progress_finish "$dir" "$total" "$launched" "$title"
}

benchmark_candidate() {
  local idx="$1" name="$2" base="$3" package="$4" outdir="$5"
  local root target metrics status ttfb speed size run ok=0 samples=""
  progress_mark_start "$outdir" "$idx" "$name"
  if [[ "$package" == "$SYSTEM_PACKAGE" ]]; then
    root="$(resolve_system_root "$base" "$package" || true)"
  else
    root="$(resolve_package_root "$base" "$package" || true)"
  fi
  if [[ -z "$root" ]]; then progress_mark_done "$outdir" "$idx" failed "$name"; return 0; fi
  target="$(benchmark_target_url "$root" "$package" || true)"
  if [[ -z "$target" ]]; then progress_mark_done "$outdir" "$idx" failed "$name"; return 0; fi

  for ((run=1; run<=BENCHMARK_RUNS; run++)); do
    metrics="$(curl -L -sS -o /dev/null --connect-timeout 3 --max-time 10 --range 0-1048575 \
      -w '%{http_code}|%{time_starttransfer}|%{speed_download}|%{size_download}' "$target" 2>/dev/null || true)"
    IFS='|' read -r status ttfb speed size <<< "$metrics"
    [[ -n "${status:-}" ]] || status="000"
    [[ -n "${ttfb:-}" ]] || ttfb="99"
    [[ -n "${speed:-}" ]] || speed="0"
    [[ -n "${size:-}" ]] || size="0"
    if strict_http_ok "$status"; then
      samples+="$speed $ttfb $size"$'\n'
      ok=$((ok + 1))
    fi
  done
  if (( ok == 0 )); then progress_mark_done "$outdir" "$idx" failed "$name"; return 0; fi

  read -r speed ttfb size < <(awk '
    NF >= 3 {s+=$1; t+=$2; z+=$3; n++}
    END {if(n) printf "%.3f %.6f %.0f\n", s/n, t/n, z/n}
  ' <<< "$samples")
  printf '%s|%s|%s|%s|%s|%s|%s\n' "$speed" "$ttfb" "$status" "$name" "$root" "$target" "$size" > "$outdir/$idx.result"
  progress_mark_done "$outdir" "$idx" ok "$name"
}

benchmark_package() {
  local package="$1" outdir candidates_file idx=0 total=0 line name base speed ttfb status root target size mbps ttfb_ms rank
  local -a results=()
  outdir="$(mktemp -d)"; candidates_file="$outdir/candidates"
  emit_package_candidates "$package" | awk -F'|' 'NF>=2 {key=$2; sub(/\/+$/, "", key); if(!seen[key]++) print $0}' > "$candidates_file"
  if [[ ! -s "$candidates_file" ]]; then rm -rf "$outdir"; error "No mirror entries are registered for '$package'."; return 1; fi
  total="$(wc -l < "$candidates_file" | tr -d ' ')"

  printf '\n%bBenchmarking %s mirrors%b\n' "$C_BOLD" "$package" "$C_RESET"
  info "Candidates are validated first; each valid endpoint is sampled $BENCHMARK_RUNS time(s), then ranked by average transfer speed and TTFB."
  printf '   Candidates: %b%s%b | Parallel workers: %b%s%b | Samples/valid mirror: %b%s%b\n\n' "$C_CYAN" "$total" "$C_RESET" "$C_CYAN" "$MAX_PARALLEL" "$C_RESET" "$C_CYAN" "$BENCHMARK_RUNS" "$C_RESET"
  progress_reset
  progress_render "$outdir" "$total" 0 "Now" 1
  while IFS='|' read -r name base; do
    idx=$((idx+1))
    benchmark_candidate "$idx" "$name" "$base" "$package" "$outdir" &
    wait_for_slot "$outdir" "$total" "$idx" "Now"
  done < "$candidates_file"
  wait_for_progress_jobs "$outdir" "$total" "$idx" "Now"

  shopt -s nullglob; local files=("$outdir"/*.result); shopt -u nullglob
  if (( ${#files[@]} == 0 )); then rm -rf "$outdir"; error "No valid/reachable repository was found for '$package'."; return 1; fi
  mapfile -t results < <(cat "${files[@]}" | sort -t'|' -k1,1nr -k2,2n | awk -F'|' '!seen[$5]++')
  rm -rf "$outdir"

  printf '\n%-5s %-30s %12s %10s %6s  %s\n' "RANK" "MIRROR" "SPEED" "TTFB" "HTTP" "PACKAGE ROOT"
  printf '%*s\n' 116 '' | tr ' ' '-'
  rank=1
  for line in "${results[@]}"; do
    IFS='|' read -r speed ttfb status name root target size <<< "$line"
    mbps="$(awk -v s="$speed" 'BEGIN {printf "%.2f Mbps", (s*8)/1000000}')"
    ttfb_ms="$(awk -v t="$ttfb" 'BEGIN {printf "%.0f", t*1000}')"
    printf '%-5s %-30.30s %12s %8sms %6s  %s\n' "$rank" "$name" "$mbps" "$ttfb_ms" "$status" "$root"
    rank=$((rank+1))
  done
  BEST_MIRROR_ROW="${results[0]}"
  IFS='|' read -r speed ttfb status name root target size <<< "$BEST_MIRROR_ROW"
  success "Fastest measured '$package' mirror: $name -> $root"
}

make_backup_dir() {
  local kind="$1" dir
  dir="$BACKUP_ROOT/$kind-$(date +%Y%m%d-%H%M%S)"
  root_run mkdir -p "$dir" || return 1
  printf '%s\n' "$dir"
}

backup_root_file() {
  local file="$1" dir="$2"
  [[ -e "$file" || -L "$file" ]] || return 0
  root_run cp -a "$file" "$dir/"
}

install_temp_file() {
  local tmp="$1" dest="$2"
  root_run mkdir -p "$(dirname "$dest")" || return 1
  root_run cp "$tmp" "$dest" || return 1
  root_run chmod 0644 "$dest"
}

rollback_single_file() {
  local dest="$1" backup_dir="$2" existed="$3" backup
  backup="$backup_dir/$(basename "$dest")"
  if [[ "$existed" == "1" && -e "$backup" ]]; then root_run cp -a "$backup" "$dest"
  else root_run rm -f "$dest"; fi
}

validate_apt_suite() {
  local root="${1%/}" suite="$2" arch
  arch="$(apt_arch)"
  apt_suite_available "$root" "$suite" "$arch"
}

apt_update_selected_source() {
  local source_file="$1" log rc=0
  log="$(mktemp)"
  root_run env DEBIAN_FRONTEND=noninteractive apt-get update -qq \
    -o "Dir::Etc::sourcelist=$source_file" \
    -o 'Dir::Etc::sourceparts=-' \
    -o 'APT::Get::List-Cleanup=0' >"$log" 2>&1 || rc=$?
  if (( rc != 0 )); then
    warn "APT validation failed. Last output:"
    tail -n 12 "$log" >&2 || true
    rm -f "$log"
    return "$rc"
  fi
  rm -f "$log"
  return 0
}

append_preserved_apt_lines() {
  local original="$1" codename="$2" out="$3"
  [[ -r "$original" ]] || return 0
  awk -v c="$codename" '
    BEGIN { pat="[[:space:]]" c "(-updates|-backports|-security)?[[:space:]]" }
    /^[[:space:]]*deb(-src)?[[:space:]]/ && $0 ~ pat { next }
    { print }
  ' "$original" >> "$out"
}

apply_ubuntu_apt() {
  local root="${1%/}" name="$2" codename="$SYSTEM_CODENAME" source_file backup_dir tmp_dir tmp_repo tmp_final existed=0 suite has_backports=0
  require_root_access || return 1
  [[ "$SYSTEM_ID" == "ubuntu" ]] || { error "Ubuntu APT auto-apply is only enabled on Ubuntu itself."; return 1; }
  [[ -n "$codename" ]] || codename="$(lsb_release -cs 2>/dev/null || true)"
  [[ -n "$codename" ]] || { error "Could not detect Ubuntu codename."; return 1; }

  for suite in "$codename" "${codename}-updates" "${codename}-security"; do
    validate_apt_suite "$root" "$suite" || { error "Selected mirror lacks $suite for architecture $(apt_arch); nothing changed."; return 1; }
  done
  validate_apt_suite "$root" "${codename}-backports" && has_backports=1 || true

  if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
    source_file=/etc/apt/sources.list.d/ubuntu.sources
  else
    source_file=/etc/apt/sources.list
  fi

  tmp_dir="$(mktemp -d)"
  if [[ "$source_file" == *.sources ]]; then
    tmp_repo="$tmp_dir/mirava.sources"
  else
    tmp_repo="$tmp_dir/mirava.list"
  fi
  tmp_final="$tmp_dir/final"
  if [[ "$source_file" == *.sources ]]; then
    {
      printf '# Generated by Mirava v%s | mirror: %s\n' "$MIRAVA_VERSION" "$name"
      printf 'Types: deb\nURIs: %s\nSuites: %s %s' "$root" "$codename" "${codename}-updates"
      (( has_backports == 1 )) && printf ' %s' "${codename}-backports"
      printf ' %s\n' "${codename}-security"
      printf 'Components: main restricted universe multiverse\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n'
    } > "$tmp_repo"
  else
    {
      printf '# Generated by Mirava v%s | mirror: %s\n' "$MIRAVA_VERSION" "$name"
      printf 'deb %s %s main restricted universe multiverse\n' "$root" "$codename"
      printf 'deb %s %s main restricted universe multiverse\n' "$root" "${codename}-updates"
      (( has_backports == 1 )) && printf 'deb %s %s main restricted universe multiverse\n' "$root" "${codename}-backports"
      printf 'deb %s %s main restricted universe multiverse\n' "$root" "${codename}-security"
    } > "$tmp_repo"
  fi

  info "Validating selected Ubuntu mirror with an isolated apt update ..."
  if ! apt_update_selected_source "$tmp_repo"; then
    rm -rf "$tmp_dir"
    error "Selected Ubuntu mirror failed isolated APT validation; nothing changed."
    return 1
  fi

  cp "$tmp_repo" "$tmp_final"
  if [[ "$source_file" != *.sources ]]; then
    printf '\n# Existing non-Ubuntu-suite entries preserved by Mirava\n' >> "$tmp_final"
    append_preserved_apt_lines "$source_file" "$codename" "$tmp_final"
  fi

  [[ -e "$source_file" ]] && existed=1
  backup_dir="$(make_backup_dir apt)" || { rm -rf "$tmp_dir"; return 1; }
  backup_root_file "$source_file" "$backup_dir" || true
  install_temp_file "$tmp_final" "$source_file" || { rm -rf "$tmp_dir"; return 1; }
  rm -rf "$tmp_dir"

  if ! apt_update_selected_source "$source_file"; then
    error "Installed Ubuntu source failed validation; restoring previous APT source."
    rollback_single_file "$source_file" "$backup_dir" "$existed"
    root_run apt-get update || true
    return 1
  fi
  success "Ubuntu APT mirror applied. Backup: $backup_dir"
  info "Refreshing all configured APT sources (third-party failures will not undo the validated Mirava mirror) ..."
  root_run env DEBIAN_FRONTEND=noninteractive apt-get update -qq || warn "The Mirava mirror validated, but another configured APT source failed during the full refresh."
}

apply_debian_apt() {
  local root="${1%/}" name="$2" codename="$SYSTEM_CODENAME" source_file backup_dir tmp_dir tmp_repo tmp_final existed=0 components suite major
  require_root_access || return 1
  [[ "$SYSTEM_ID" == "debian" ]] || { error "Debian APT auto-apply is only enabled on Debian itself."; return 1; }
  [[ -n "$codename" ]] || codename="$(. /etc/os-release; printf '%s' "${VERSION_CODENAME:-}")"
  [[ -n "$codename" ]] || { error "Could not detect Debian codename."; return 1; }
  for suite in "$codename" "${codename}-updates"; do
    validate_apt_suite "$root" "$suite" || { error "Selected mirror lacks $suite for architecture $(apt_arch); nothing changed."; return 1; }
  done
  major="${SYSTEM_VERSION%%.*}"; components="main contrib non-free"
  [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 12 )) && components+=" non-free-firmware"

  if [[ -f /etc/apt/sources.list.d/debian.sources ]]; then
    source_file=/etc/apt/sources.list.d/debian.sources
  else
    source_file=/etc/apt/sources.list
  fi

  tmp_dir="$(mktemp -d)"
  if [[ "$source_file" == *.sources ]]; then
    tmp_repo="$tmp_dir/mirava.sources"
  else
    tmp_repo="$tmp_dir/mirava.list"
  fi
  tmp_final="$tmp_dir/final"
  if [[ "$source_file" == *.sources ]]; then
    cat > "$tmp_repo" <<APT
# Generated by Mirava v$MIRAVA_VERSION | mirror: $name
Types: deb
URIs: $root
Suites: $codename ${codename}-updates
Components: $components
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: ${codename}-security
Components: $components
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
APT
  else
    cat > "$tmp_repo" <<APT
# Generated by Mirava v$MIRAVA_VERSION | mirror: $name
deb $root $codename $components
deb $root ${codename}-updates $components
deb https://security.debian.org/debian-security ${codename}-security $components
APT
  fi

  info "Validating selected Debian mirror with an isolated apt update ..."
  if ! apt_update_selected_source "$tmp_repo"; then
    rm -rf "$tmp_dir"
    error "Selected Debian mirror failed isolated APT validation; nothing changed."
    return 1
  fi

  cp "$tmp_repo" "$tmp_final"
  if [[ "$source_file" != *.sources ]]; then
    printf '\n# Existing non-Debian-suite entries preserved by Mirava\n' >> "$tmp_final"
    append_preserved_apt_lines "$source_file" "$codename" "$tmp_final"
  fi

  [[ -e "$source_file" ]] && existed=1
  backup_dir="$(make_backup_dir apt)" || { rm -rf "$tmp_dir"; return 1; }
  backup_root_file "$source_file" "$backup_dir" || true
  install_temp_file "$tmp_final" "$source_file" || { rm -rf "$tmp_dir"; return 1; }
  rm -rf "$tmp_dir"

  if ! apt_update_selected_source "$source_file"; then
    error "Installed Debian source failed validation; restoring previous APT source."
    rollback_single_file "$source_file" "$backup_dir" "$existed"
    root_run apt-get update || true
    return 1
  fi
  success "Debian APT mirror applied. Backup: $backup_dir"
  info "Refreshing all configured APT sources (third-party failures will not undo the validated Mirava mirror) ..."
  root_run env DEBIAN_FRONTEND=noninteractive apt-get update -qq || warn "The Mirava mirror validated, but another configured APT source failed during the full refresh."
}

rpm_metadata_ok() { strict_http_ok "$(probe_status "${1%/}/repodata/repomd.xml")"; }

append_rpm_repo() {
  local file="$1" id="$2" title="$3" url="$4"
  cat >> "$file" <<RPM
[$id]
name=$title
baseurl=$url
enabled=1
gpgcheck=1
repo_gpgcheck=0
priority=1
cost=1
skip_if_unavailable=1

RPM
}

apply_rpm_backend() {
  local root="${1%/}" name="$2" package="$3" pm="$SYSTEM_BACKEND" arch ver major prefix tmp repo_file backup_dir existed=0
  local base app extras updates
  require_root_access || return 1
  [[ "$pm" == "dnf" || "$pm" == "yum" || "$pm" == "microdnf" ]] || { error "DNF/YUM backend is not active on this system."; return 1; }
  arch="$(repo_arch)"; ver="$SYSTEM_VERSION"; major="${ver%%.*}"; tmp="$(mktemp)"; : > "$tmp"

  case "$package" in
    Fedora)
      ver="$(rpm -E %fedora 2>/dev/null | grep -E '^[0-9]+$' | head -1 || printf '%s' "$ver")"
      base="$(first_valid_url "$root/linux/releases/$ver/Everything/$arch/os" "$root/releases/$ver/Everything/$arch/os" 2>/dev/null || true)"
      updates="$(first_valid_url "$root/linux/updates/$ver/Everything/$arch" "$root/updates/$ver/Everything/$arch" 2>/dev/null || true)"
      [[ -n "$base" && -n "$updates" ]] || { rm -f "$tmp"; error "Mirror does not expose compatible Fedora $ver Base/Updates metadata."; return 1; }
      rpm_metadata_ok "$base" && rpm_metadata_ok "$updates" || { rm -f "$tmp"; error "Fedora repodata validation failed."; return 1; }
      append_rpm_repo "$tmp" mirava-fedora "Mirava Fedora - $name" "$base"
      append_rpm_repo "$tmp" mirava-fedora-updates "Mirava Fedora Updates - $name" "$updates"
      ;;
    Rocky|Rocky\ Linux|AlmaLinux)
      base="$(first_valid_url "$root/$major/BaseOS/$arch/os" "$root/$ver/BaseOS/$arch/os" 2>/dev/null || true)"
      [[ -n "$base" ]] || { rm -f "$tmp"; error "Mirror does not expose compatible $package BaseOS metadata."; return 1; }
      prefix="${base%/BaseOS/$arch/os}"
      app="$prefix/AppStream/$arch/os"; extras="$prefix/extras/$arch/os"
      rpm_metadata_ok "$base" && rpm_metadata_ok "$app" || { rm -f "$tmp"; error "$package BaseOS/AppStream validation failed."; return 1; }
      append_rpm_repo "$tmp" mirava-baseos "Mirava $package BaseOS - $name" "$base"
      append_rpm_repo "$tmp" mirava-appstream "Mirava $package AppStream - $name" "$app"
      rpm_metadata_ok "$extras" && append_rpm_repo "$tmp" mirava-extras "Mirava $package Extras - $name" "$extras"
      ;;
    CentOS)
      base="$(first_valid_url "$root/${major}-stream/BaseOS/$arch/os" "$root/$major/BaseOS/$arch/os" "$root/$major/os/$arch" 2>/dev/null || true)"
      [[ -n "$base" ]] || { rm -f "$tmp"; error "Mirror does not expose compatible CentOS metadata."; return 1; }
      if [[ "$base" == */BaseOS/$arch/os ]]; then
        prefix="${base%/BaseOS/$arch/os}"; app="$prefix/AppStream/$arch/os"; extras="$prefix/extras/$arch/os"
        rpm_metadata_ok "$base" && rpm_metadata_ok "$app" || { rm -f "$tmp"; error "CentOS BaseOS/AppStream validation failed."; return 1; }
        append_rpm_repo "$tmp" mirava-baseos "Mirava CentOS BaseOS - $name" "$base"
        append_rpm_repo "$tmp" mirava-appstream "Mirava CentOS AppStream - $name" "$app"
        rpm_metadata_ok "$extras" && append_rpm_repo "$tmp" mirava-extras "Mirava CentOS Extras - $name" "$extras"
      else
        prefix="${base%/os/$arch}"; updates="$prefix/updates/$arch"; extras="$prefix/extras/$arch"
        rpm_metadata_ok "$base" || { rm -f "$tmp"; error "CentOS base repodata validation failed."; return 1; }
        append_rpm_repo "$tmp" mirava-base "Mirava CentOS Base - $name" "$base"
        rpm_metadata_ok "$updates" && append_rpm_repo "$tmp" mirava-updates "Mirava CentOS Updates - $name" "$updates"
        rpm_metadata_ok "$extras" && append_rpm_repo "$tmp" mirava-extras "Mirava CentOS Extras - $name" "$extras"
      fi
      ;;
    *) rm -f "$tmp"; error "DNF/YUM auto-apply is not defined for '$package'."; return 1 ;;
  esac

  repo_file=/etc/yum.repos.d/mirava.repo; [[ -e "$repo_file" ]] && existed=1
  backup_dir="$(make_backup_dir rpm)" || { rm -f "$tmp"; return 1; }; backup_root_file "$repo_file" "$backup_dir" || true
  install_temp_file "$tmp" "$repo_file"; rm -f "$tmp"
  info "Validating Mirava RPM repositories with $pm ..."
  if [[ "$pm" == "dnf" ]]; then
    if root_run dnf -y --disablerepo='*' --enablerepo='mirava-*' makecache --refresh; then success "Mirava DNF repository priority applied. Backup: $backup_dir"; return 0; fi
  elif [[ "$pm" == "microdnf" ]]; then
    if root_run microdnf --disablerepo='*' --enablerepo='mirava-*' makecache; then success "Mirava MicroDNF repository priority applied. Backup: $backup_dir"; return 0; fi
  else
    root_run yum clean metadata >/dev/null 2>&1 || true
    if root_run yum -y --disablerepo='*' --enablerepo='mirava-*' makecache; then success "Mirava YUM repository priority applied. Backup: $backup_dir"; return 0; fi
  fi
  error "$pm metadata refresh failed; rolling back Mirava repo file."
  rollback_single_file "$repo_file" "$backup_dir" "$existed"; return 1
}

apply_pacman_backend() {
  local root="${1%/}" name="$2" package="$3" mirrorlist=/etc/pacman.d/mirrorlist backup_dir tmp existed=0 arch branch server target
  require_root_access || return 1
  [[ "$SYSTEM_BACKEND" == "pacman" ]] || { error "Pacman backend is not active."; return 1; }
  arch="$(repo_arch)"
  case "$package" in
    Arch\ Linux|ArchLinux)
      target="$(first_valid_url "$root/core/os/$arch/core.db" "$root/core/os/$arch/core.db.tar.gz" 2>/dev/null || true)"
      [[ -n "$target" ]] || { error "Selected mirror is not a compatible Arch repository."; return 1; }
      server="$root/\$repo/os/\$arch"
      ;;
    Manjaro)
      branch="$(manjaro_branch)"
      target="$(first_valid_url "$root/$branch/core/$arch/core.db" 2>/dev/null || true)"
      [[ -n "$target" ]] || { error "Selected mirror is not a compatible Manjaro $branch repository."; return 1; }
      server="$root/$branch/\$repo/\$arch"
      ;;
    *) error "Pacman auto-apply is not defined for '$package'."; return 1 ;;
  esac
  [[ -e "$mirrorlist" ]] && existed=1; backup_dir="$(make_backup_dir pacman)" || return 1; backup_root_file "$mirrorlist" "$backup_dir" || true
  tmp="$(mktemp)"
  {
    printf '# BEGIN MIRAVA SELECTED MIRROR\n# %s\nServer = %s\n# END MIRAVA SELECTED MIRROR\n\n' "$name" "$server"
    if [[ -r "$mirrorlist" ]]; then awk 'BEGIN{s=0} /^# BEGIN MIRAVA SELECTED MIRROR/{s=1;next} /^# END MIRAVA SELECTED MIRROR/{s=0;next} !s{print}' "$mirrorlist"; fi
  } > "$tmp"
  install_temp_file "$tmp" "$mirrorlist"; rm -f "$tmp"
  success "Pacman mirror placed first; existing mirrors remain as fallbacks. Backup: $backup_dir"
  info "Arch-family safety: database-only sync is intentionally skipped. Use 'pacman -Syu' for the next normal full upgrade."
  return 0
}

apply_apk_backend() {
  local root="${1%/}" name="$2" repos=/etc/apk/repositories backup_dir tmp existed=0 branch arch main community line prefix url suffix component repo_branch changed=0
  require_root_access || return 1
  [[ "$SYSTEM_BACKEND" == "apk" && "$SYSTEM_ID" == "alpine" ]] || { error "APK auto-apply is only enabled on Alpine."; return 1; }
  branch="$(alpine_branch)"; arch="$(alpine_arch)"; main="$root/$branch/main"; community="$root/$branch/community"
  strict_http_ok "$(probe_status "$main/$arch/APKINDEX.tar.gz")" || { error "Selected mirror lacks Alpine $branch main/$arch index."; return 1; }
  strict_http_ok "$(probe_status "$community/$arch/APKINDEX.tar.gz")" || warn "Community index was not detected; any existing community entry will be preserved on its old mirror."
  [[ -e "$repos" ]] && existed=1; backup_dir="$(make_backup_dir apk)" || return 1; backup_root_file "$repos" "$backup_dir" || true
  tmp="$(mktemp)"
  if [[ -r "$repos" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      prefix=""; url="$line"
      if [[ "$line" =~ ^(@[^[:space:]]+)[[:space:]]+(https?://.*)$ ]]; then prefix="${BASH_REMATCH[1]} "; url="${BASH_REMATCH[2]}"; fi
      if [[ "$url" =~ ^https?://.*/alpine/(edge|v[0-9]+\.[0-9]+)/(main|community|testing)(/.*)?$ ]]; then
        suffix="${url#*/alpine/}"; repo_branch="${BASH_REMATCH[1]}"; component="${BASH_REMATCH[2]}"
        if strict_http_ok "$(probe_status "$root/$repo_branch/$component/$arch/APKINDEX.tar.gz")"; then
          printf '%s%s/%s\n' "$prefix" "$root" "$suffix"; changed=1
        else
          printf '%s\n' "$line"
        fi
      else
        printf '%s\n' "$line"
      fi
    done < "$repos" > "$tmp"
  fi
  if (( changed == 0 )); then
    printf '%s\n' "$main" >> "$tmp"
    strict_http_ok "$(probe_status "$community/$arch/APKINDEX.tar.gz")" && printf '%s\n' "$community" >> "$tmp"
  fi
  install_temp_file "$tmp" "$repos"; rm -f "$tmp"
  info "Validating Alpine repositories with apk update ..."
  if root_run apk update; then success "Alpine APK mirror applied. Backup: $backup_dir"; return 0; fi
  error "apk update failed; restoring repositories file."; rollback_single_file "$repos" "$backup_dir" "$existed"; root_run apk update || true; return 1
}

append_zypper_repo() {
  local file="$1" id="$2" title="$3" url="$4"
  cat >> "$file" <<ZYPP
[$id]
name=$title
enabled=1
autorefresh=1
baseurl=$url
type=rpm-md
gpgcheck=1
priority=1

ZYPP
}

apply_zypper_backend() {
  local root="${1%/}" name="$2" repo_file=/etc/zypp/repos.d/mirava.repo backup_dir tmp existed=0 ver="$SYSTEM_VERSION" oss nonoss upd updnon
  local -a aliases=()
  require_root_access || return 1
  [[ "$SYSTEM_BACKEND" == "zypper" && "$SYSTEM_ID" == opensuse* ]] || { error "Zypper auto-apply is only enabled on openSUSE."; return 1; }
  tmp="$(mktemp)"; : > "$tmp"
  if [[ "$SYSTEM_ID" == *tumbleweed* || "${SYSTEM_VERSION,,}" == *tumbleweed* ]]; then
    oss="$root/tumbleweed/repo/oss"; nonoss="$root/tumbleweed/repo/non-oss"; upd="$root/update/tumbleweed"
    rpm_metadata_ok "$oss" || { rm -f "$tmp"; error "Selected mirror lacks openSUSE Tumbleweed OSS metadata."; return 1; }
    append_zypper_repo "$tmp" mirava-oss "Mirava Tumbleweed OSS - $name" "$oss"; aliases+=(mirava-oss)
    if rpm_metadata_ok "$nonoss"; then append_zypper_repo "$tmp" mirava-non-oss "Mirava Tumbleweed Non-OSS - $name" "$nonoss"; aliases+=(mirava-non-oss); fi
    if rpm_metadata_ok "$upd"; then append_zypper_repo "$tmp" mirava-update "Mirava Tumbleweed Update - $name" "$upd"; aliases+=(mirava-update); fi
  else
    oss="$root/distribution/leap/$ver/repo/oss"; nonoss="$root/distribution/leap/$ver/repo/non-oss"; upd="$root/update/leap/$ver/oss"; updnon="$root/update/leap/$ver/non-oss"
    rpm_metadata_ok "$oss" || { rm -f "$tmp"; error "Selected mirror lacks openSUSE Leap $ver OSS metadata."; return 1; }
    append_zypper_repo "$tmp" mirava-oss "Mirava Leap OSS - $name" "$oss"; aliases+=(mirava-oss)
    if rpm_metadata_ok "$nonoss"; then append_zypper_repo "$tmp" mirava-non-oss "Mirava Leap Non-OSS - $name" "$nonoss"; aliases+=(mirava-non-oss); fi
    if rpm_metadata_ok "$upd"; then append_zypper_repo "$tmp" mirava-update-oss "Mirava Leap Update OSS - $name" "$upd"; aliases+=(mirava-update-oss); fi
    if rpm_metadata_ok "$updnon"; then append_zypper_repo "$tmp" mirava-update-non-oss "Mirava Leap Update Non-OSS - $name" "$updnon"; aliases+=(mirava-update-non-oss); fi
  fi
  [[ -e "$repo_file" ]] && existed=1; backup_dir="$(make_backup_dir zypper)" || { rm -f "$tmp"; return 1; }; backup_root_file "$repo_file" "$backup_dir" || true
  install_temp_file "$tmp" "$repo_file"; rm -f "$tmp"
  info "Validating Mirava repositories with zypper ..."
  local alias ok=1
  for alias in "${aliases[@]}"; do root_run zypper --non-interactive --gpg-auto-import-keys refresh "$alias" || { ok=0; break; }; done
  if (( ok == 1 )); then success "Mirava Zypper repositories applied with priority 1. Backup: $backup_dir"; return 0; fi
  error "zypper refresh failed; rolling back Mirava repo file."; rollback_single_file "$repo_file" "$backup_dir" "$existed"; return 1
}

apply_system_mirror() {
  local root="$1" name="$2" package="$3"
  if (( SYSTEM_APPLY_SUPPORTED == 0 )); then
    error "Detected '$SYSTEM_ID' is a derivative/unsupported auto-apply target. Benchmarking is supported, but Mirava will not rewrite its repositories automatically."
    return 1
  fi
  case "$SYSTEM_BACKEND:$package" in
    apt-get:Ubuntu) apply_ubuntu_apt "$root" "$name" ;;
    apt-get:Debian) apply_debian_apt "$root" "$name" ;;
    dnf:Fedora|yum:Fedora|microdnf:Fedora|dnf:Rocky|yum:Rocky|microdnf:Rocky|dnf:AlmaLinux|yum:AlmaLinux|microdnf:AlmaLinux|dnf:CentOS|yum:CentOS|microdnf:CentOS) apply_rpm_backend "$root" "$name" "$package" ;;
    pacman:Arch\ Linux|pacman:Manjaro) apply_pacman_backend "$root" "$name" "$package" ;;
    apk:Alpine) apply_apk_backend "$root" "$name" ;;
    zypper:OpenSUSE) apply_zypper_backend "$root" "$name" ;;
    *) error "No automatic apply backend is available for $SYSTEM_ID ($SYSTEM_BACKEND / $package)."; return 1 ;;
  esac
}

fastest_repository_flow() {
  local package="${1:-}" mode="${2:-prompt}" speed ttfb status name root target size
  [[ -n "$package" ]] || package="$(choose_package)" || return 1
  benchmark_package "$package" || return 1
  [[ -n "$BEST_MIRROR_ROW" ]] || return 1
  IFS='|' read -r speed ttfb status name root target size <<< "$BEST_MIRROR_ROW"
  if [[ "$package" == "$SYSTEM_PACKAGE" ]]; then
    if [[ "$mode" == "yes" ]]; then apply_system_mirror "$root" "$name" "$package"
    elif [[ "$mode" == "prompt" ]] && confirm "Apply '$name' using the detected $SYSTEM_BACKEND backend?"; then apply_system_mirror "$root" "$name" "$package"; fi
  fi
}

system_repository_flow() {
  [[ -n "$SYSTEM_PACKAGE" ]] || { error "Could not map this Linux distribution to a supported repository family."; return 1; }
  info "Detected $SYSTEM_ID $SYSTEM_VERSION -> $SYSTEM_PACKAGE via ${SYSTEM_BACKEND:-unknown backend}."
  fastest_repository_flow "$SYSTEM_PACKAGE" "${1:-prompt}"
}

current_dns() {
  printf '%bCurrent DNS servers%b\n' "$C_BOLD" "$C_RESET"
  local summary item
  summary="$(collect_current_dns)"
  if [[ "$summary" == "Not detected" ]]; then
    printf '  • %s\n' "$summary"
    return 0
  fi
  while IFS= read -r item; do [[ -n "$item" ]] && printf '  • %s\n' "$item"; done < <(tr ',' '\n' <<< "$summary" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
}

benchmark_dns_server() {
  local idx="$1" provider="$2" categories="$3" server="$4" outdir="$5" q ms sum=0 ok=0 avg response
  progress_mark_start "$outdir" "$idx" "$provider @ $server"
  for q in 1 2 3; do
    response="$(dig +tries=1 +time=2 +noall +comments +answer +stats @"$server" example.com A 2>/dev/null || true)"
    grep -q 'status: NOERROR' <<< "$response" || continue
    ms="$(awk '/Query time:/ {print $4; exit}' <<< "$response")"
    if [[ "$ms" =~ ^[0-9]+$ ]]; then sum=$((sum + ms)); ok=$((ok + 1)); fi
  done
  # Ignore highly flaky resolvers. A candidate must answer at least 2/3 probes.
  if (( ok < 2 )); then progress_mark_done "$outdir" "$idx" failed "$provider @ $server"; return 0; fi
  avg="$(awk -v s="$sum" -v n="$ok" 'BEGIN {printf "%.2f", s/n}')"
  printf '%s|%s|%s|%s|%s\n' "$avg" "$server" "$provider" "$categories" "$ok" > "$outdir/$idx.result"
  progress_mark_done "$outdir" "$idx" ok "$provider @ $server"
}

benchmark_dns() {
  local category="${1:-all}" outdir candidates_file idx=0 total=0 provider categories server rank row avg ip name cats replies
  local -a rows=()
  ensure_dig || return 1
  if [[ "$category" != "all" && "$category" != "local" && "$category" != "global" ]]; then error "DNS category must be local, global, or all."; return 2; fi
  outdir="$(mktemp -d)"; candidates_file="$outdir/candidates"
  dataq dns-rows | awk -F '\t' -v cat="$category" '
    cat == "all" || index("," $2 ",", "," cat ",") { if (!seen[$3]++) print $0 }
  ' > "$candidates_file"
  total="$(wc -l < "$candidates_file" | tr -d ' ')"
  if (( total == 0 )); then rm -rf "$outdir"; error "No DNS entries are registered for category '$category'."; return 1; fi

  printf '\n%bBenchmarking DNS resolvers (%s)%b\n' "$C_BOLD" "$category" "$C_RESET"
  info "Duplicate DNS IPs are tested only once. Ranking requires at least 2/3 successful DNS replies."
  printf '   Resolvers: %b%s%b | Parallel workers: %b%s%b | Queries/resolver: %b3%b\n\n' "$C_CYAN" "$total" "$C_RESET" "$C_CYAN" "$MAX_PARALLEL" "$C_RESET" "$C_CYAN" "$C_RESET"
  progress_reset
  progress_render "$outdir" "$total" 0 "Now" 1
  while IFS=$'\t' read -r provider categories server; do
    idx=$((idx+1))
    benchmark_dns_server "$idx" "$provider" "$categories" "$server" "$outdir" &
    wait_for_slot "$outdir" "$total" "$idx" "Now"
  done < "$candidates_file"
  wait_for_progress_jobs "$outdir" "$total" "$idx" "Now"
  shopt -s nullglob; local result_files=("$outdir"/*.result); shopt -u nullglob
  if (( ${#result_files[@]} == 0 )); then rm -rf "$outdir"; error "No DNS resolver answered enough test queries."; return 1; fi
  mapfile -t rows < <(cat "${result_files[@]}" | sort -t'|' -k1,1n -k5,5nr); rm -rf "$outdir"
  printf '\n%-5s %-24s %-16s %-9s %-8s %s\n' "RANK" "PROVIDER" "SERVER" "AVG" "REPLIES" "SOURCE CATEGORY"
  printf '%*s\n' 88 '' | tr ' ' '-'; rank=1
  for row in "${rows[@]}"; do
    IFS='|' read -r avg ip name cats replies <<< "$row"
    printf '%-5s %-24.24s %-16s %7sms %4s/3   %s\n' "$rank" "$name" "$ip" "$avg" "$replies" "$cats"
    rank=$((rank+1))
  done
  BEST_DNS_1="$(cut -d'|' -f2 <<< "${rows[0]}")"; BEST_DNS_2="$BEST_DNS_1"
  (( ${#rows[@]} > 1 )) && BEST_DNS_2="$(cut -d'|' -f2 <<< "${rows[1]}")"
  success "Fastest stable measured DNS pair: $BEST_DNS_1, $BEST_DNS_2"
}

remove_managed_block() {
  local file="$1" tmp
  [[ -f "$file" ]] || return 0
  tmp="$(mktemp)"
  awk 'BEGIN{s=0} /^# BEGIN MIRAVA DNS/{s=1;next} /^# END MIRAVA DNS/{s=0;next} !s{print}' "$file" > "$tmp"
  install_temp_file "$tmp" "$file"; rm -f "$tmp"
}

apply_dns() {
  local dns1="$1" dns2="$2" backup_dir conn dropin head dhcp_file
  require_root_access || return 1; backup_dir="$(make_backup_dir dns)" || return 1

  if have nmcli; then
    conn="$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | awk -F: '$2 != "lo" {print $1; exit}')"
    if [[ -n "$conn" ]]; then
      root_run nmcli connection export "$conn" "$backup_dir/networkmanager.nmconnection" >/dev/null 2>&1 || true
      root_run nmcli connection modify "$conn" ipv4.dns "$dns1 $dns2" ipv4.ignore-auto-dns yes
      root_run nmcli connection up "$conn" >/dev/null
      success "DNS applied through NetworkManager. Backup: $backup_dir"; return 0
    fi
  fi

  if have resolvectl && (systemd_active systemd-resolved || [[ -d /run/systemd/resolve ]]); then
    dropin=/etc/systemd/resolved.conf.d/90-mirava-dns.conf; backup_root_file "$dropin" "$backup_dir" || true
    local tmp="$(mktemp)"; printf '# Generated by Mirava v%s\n[Resolve]\nDNS=%s %s\n' "$MIRAVA_VERSION" "$dns1" "$dns2" > "$tmp"
    install_temp_file "$tmp" "$dropin"; rm -f "$tmp"
    root_run systemctl restart systemd-resolved
    success "DNS applied through systemd-resolved. Backup: $backup_dir"; return 0
  fi

  if have resolvconf; then
    head=/etc/resolvconf/resolv.conf.d/head; backup_root_file "$head" "$backup_dir" || true
    local tmp="$(mktemp)"; [[ -r "$head" ]] && cat "$head" > "$tmp" || : > "$tmp"
    awk 'BEGIN{s=0} /^# BEGIN MIRAVA DNS/{s=1;next} /^# END MIRAVA DNS/{s=0;next} !s{print}' "$tmp" > "$tmp.clean"; mv "$tmp.clean" "$tmp"
    printf '\n# BEGIN MIRAVA DNS\nnameserver %s\nnameserver %s\n# END MIRAVA DNS\n' "$dns1" "$dns2" >> "$tmp"
    install_temp_file "$tmp" "$head"; rm -f "$tmp"; root_run resolvconf -u
    success "DNS applied through resolvconf/openresolv. Backup: $backup_dir"; return 0
  fi

  if have dhcpcd && [[ -f /etc/dhcpcd.conf ]]; then
    dhcp_file=/etc/dhcpcd.conf; backup_root_file "$dhcp_file" "$backup_dir" || true
    local tmp="$(mktemp)"; awk 'BEGIN{s=0} /^# BEGIN MIRAVA DNS/{s=1;next} /^# END MIRAVA DNS/{s=0;next} !s{print}' "$dhcp_file" > "$tmp"
    printf '\n# BEGIN MIRAVA DNS\nstatic domain_name_servers=%s %s\n# END MIRAVA DNS\n' "$dns1" "$dns2" >> "$tmp"
    install_temp_file "$tmp" "$dhcp_file"; rm -f "$tmp"
    if systemd_active dhcpcd; then root_run systemctl restart dhcpcd; elif have rc-service; then root_run rc-service dhcpcd restart; fi
    success "DNS applied through dhcpcd. Backup: $backup_dir"; return 0
  fi

  if [[ -L /etc/resolv.conf ]]; then error "/etc/resolv.conf is managed by an unsupported resolver; refusing to replace the symlink."; return 1; fi
  backup_root_file /etc/resolv.conf "$backup_dir" || true
  local tmp="$(mktemp)"; printf '# BEGIN MIRAVA DNS\nnameserver %s\nnameserver %s\noptions timeout:2 attempts:2 rotate\n# END MIRAVA DNS\n' "$dns1" "$dns2" > "$tmp"
  install_temp_file "$tmp" /etc/resolv.conf; rm -f "$tmp"
  success "DNS written to /etc/resolv.conf. Backup: $backup_dir"
}

reset_dns() {
  require_root_access || return 1
  local conn dropin=/etc/systemd/resolved.conf.d/90-mirava-dns.conf changed=0 latest
  if have nmcli; then
    conn="$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | awk -F: '$2 != "lo" {print $1; exit}')"
    if [[ -n "$conn" ]]; then root_run nmcli connection modify "$conn" ipv4.dns "" ipv4.ignore-auto-dns no; root_run nmcli connection up "$conn" >/dev/null; changed=1; fi
  fi
  if [[ -f "$dropin" ]]; then root_run rm -f "$dropin"; systemd_active systemd-resolved && root_run systemctl restart systemd-resolved; changed=1; fi
  if have resolvconf && [[ -f /etc/resolvconf/resolv.conf.d/head ]]; then remove_managed_block /etc/resolvconf/resolv.conf.d/head; root_run resolvconf -u; changed=1; fi
  if have dhcpcd && [[ -f /etc/dhcpcd.conf ]] && grep -q '^# BEGIN MIRAVA DNS' /etc/dhcpcd.conf; then remove_managed_block /etc/dhcpcd.conf; if systemd_active dhcpcd; then root_run systemctl restart dhcpcd; elif have rc-service; then root_run rc-service dhcpcd restart; fi; changed=1; fi
  if [[ -f /etc/resolv.conf ]] && grep -q '^# BEGIN MIRAVA DNS' /etc/resolv.conf 2>/dev/null; then
    latest="$(root_run find "$BACKUP_ROOT" -maxdepth 2 -type f -path '*/dns-*/resolv.conf' 2>/dev/null | sort -r | head -1 || true)"
    if [[ -n "$latest" ]]; then root_run cp -a "$latest" /etc/resolv.conf; changed=1; else warn "No resolv.conf backup was found; leaving direct fallback untouched."; fi
  fi
  (( changed == 1 )) && success "Mirava-managed DNS overrides reset." || warn "No Mirava-managed DNS override was detected."
}

dns_flow() {
  local choice category
  while true; do
    printf '\n%bDNS benchmark & management%b\n' "$C_BOLD" "$C_RESET"
    printf '  1) Find fastest Iranian/local DNS\n  2) Find fastest global DNS\n  3) Find fastest DNS from all imported entries\n  4) Show current DNS\n  5) Reset Mirava-managed DNS\n  0) Back\nChoose: '
    read -r choice
    case "$choice" in
      1) category=local ;; 2) category=global ;; 3) category=all ;;
      4) current_dns; pause_screen; continue ;;
      5) if confirm "Reset DNS to automatic/default settings?"; then reset_dns; fi; pause_screen; continue ;;
      0) return 0 ;; *) warn "Invalid selection."; continue ;;
    esac
    benchmark_dns "$category" || { pause_screen; continue; }
    if confirm "Apply $BEST_DNS_1 and $BEST_DNS_2 as system DNS?"; then apply_dns "$BEST_DNS_1" "$BEST_DNS_2"; fi
    pause_screen
  done
}

backend_info() {
  printf 'OS ID:              %s\nVersion:            %s\nCodename:           %s\nPackage manager:    %s\nRepository family:  %s\nAuto-apply backend: %s\n' \
    "$SYSTEM_ID" "${SYSTEM_VERSION:-unknown}" "${SYSTEM_CODENAME:-unknown}" "${SYSTEM_BACKEND:-unsupported}" "${SYSTEM_PACKAGE:-unknown}" "$([[ $SYSTEM_APPLY_SUPPORTED -eq 1 ]] && echo yes || echo no)"
}

doctor() {
  local cmd
  printf '%bMirava doctor%b\n' "$C_BOLD" "$C_RESET"
  printf 'Version:            %s\n' "$MIRAVA_VERSION"
  backend_info
  printf '\nRuntime commands:\n'
  for cmd in bash curl awk sed grep sort mktemp; do
    if have "$cmd"; then printf '  [ok]      %s -> %s\n' "$cmd" "$(command -v "$cmd")"
    else printf '  [missing] %s\n' "$cmd"; fi
  done
  if [[ -n "$PYTHON_BIN" ]]; then printf '  [ok]      python3 -> %s\n' "$PYTHON_BIN"; fi
  if have dig; then printf '  [ok]      dig -> %s\n' "$(command -v dig)"
  else printf '  [on-demand] dig (Mirava installs the distro package automatically before DNS benchmarking)\n'; fi
  printf '\nData validation:\n'
  dataq validate >/dev/null && printf '  [ok] mirrors_list.yaml validation passed\n'
  dataq stats | sed 's/^/  /'
  printf '\nPrivilege path: '
  if (( EUID == 0 )); then printf 'root\n'
  elif have sudo; then printf 'sudo\n'
  elif have doas; then printf 'doas\n'
  else printf 'none (benchmark works; automatic dependency/config changes require running as root)\n'; fi
}

main_menu() {
  local choice package
  while true; do
    clear 2>/dev/null || true; banner
    printf '  1) Optimize repository for this Linux system (detect → benchmark → optional apply)\n'
    printf '  2) Find fastest repository/package mirror\n'
    printf '  3) Check all registered mirrors/packages\n'
    printf '  4) DNS benchmark & management\n'
    printf '  5) Show current DNS\n'
    printf '  6) Show server / network overview\n'
    printf '  7) Show detected backend\n'
    printf '  8) List supported package types\n'
    printf '  9) Doctor / data validation\n'
    printf '  0) Exit\n\nChoose: '
    read -r choice || return 0
    case "$choice" in
      1) system_repository_flow prompt; pause_screen ;;
      2) package="$(choose_package)" && fastest_repository_flow "$package" prompt; pause_screen ;;
      3) check_all_mirrors; pause_screen ;;
      4) dns_flow ;;
      5) current_dns; pause_screen ;;
      6) system_overview; pause_screen ;;
      7) backend_info; pause_screen ;;
      8) list_packages | nl -w3 -s') '; pause_screen ;;
      9) doctor; pause_screen ;;
      0) return 0 ;; *) warn "Invalid selection."; sleep 1 ;;
    esac
  done
}

usage() {
  cat <<EOF
Usage: check_mirrors.sh [option]

Mirava bootstraps bash/curl/ca-certificates in the POSIX launcher and installs Python 3 from the native package manager when missing.
The data reader is embedded in check_mirrors.sh and has no PyYAML/yq dependency. DNS benchmarking installs the distro package that provides 'dig' when needed.

Options:
  --menu                        Open interactive menu
  --system-repo                 Detect this distro, benchmark compatible mirrors, optionally apply on TTY
  --apply-system-repo --yes     Detect, benchmark and apply the fastest compatible mirror non-interactively
  --check-all                   Check every mirror/package endpoint
  --fastest PACKAGE             Benchmark mirrors that provide PACKAGE
  --fastest-ubuntu              Benchmark all registered Ubuntu mirrors
  --dns [local|global|all]      Benchmark registered DNS resolvers
  --current-dns                 Show current DNS servers
  --system-info                 Show server/network overview (IP, location, DNS, repos, Docker)
  --backend-info                Show detected distro/package-manager backend
  --doctor                      Validate dependencies, backend, and Mirava data
  --list-packages               Print package types known by the YAML list
  -h, --help                    Show this help

Auto-apply backends:
  APT      Ubuntu, Debian
  DNF/YUM  Fedora, Rocky Linux, AlmaLinux, CentOS/Stream (validated layouts only)
  Pacman   Arch Linux, Manjaro
  APK      Alpine Linux
  Zypper   openSUSE Leap, openSUSE Tumbleweed

Environment:
  MIRAVA_MIRROR_FILE=...        Use a custom YAML data file
  MIRAVA_JOBS=N                 Maximum parallel benchmark workers (default: 8)
  MIRAVA_BENCH_RUNS=N           Repository samples per valid endpoint, 1-5 (default: 2)
  MIRAVA_OS_RELEASE_FILE=...    Override /etc/os-release (testing/chroot use)
  MIRAVA_PACKAGE_MANAGER=...    Override detected package manager
  MIRAVA_SKIP_NETINFO=1         Skip public IP/location lookup in the menu overview
EOF
}

main() {
  case "${1:-}" in
    -h|--help) usage; return 0 ;;
    --current-dns) current_dns; return 0 ;;
    --backend-info) load_system_info; backend_info; return 0 ;;
  esac
  init
  case "${1:-}" in
    --menu) main_menu ;;
    --system-repo) system_repository_flow prompt ;;
    --apply-system-repo)
      [[ "${2:-}" == "--yes" ]] || { error "--apply-system-repo requires --yes for non-interactive system changes."; exit 2; }
      system_repository_flow yes
      ;;
    --check-all) check_all_mirrors ;;
    --fastest) [[ -n "${2:-}" ]] || { error "--fastest requires a package name."; exit 2; }; fastest_repository_flow "$2" prompt ;;
    --fastest-ubuntu) fastest_repository_flow Ubuntu prompt ;;
    --dns) benchmark_dns "${2:-all}" ;;
    --system-info) system_overview ;;
    --backend-info) backend_info ;;
    --doctor) doctor ;;
    --list-packages) list_packages ;;
    "") if [[ -t 0 && -t 1 ]]; then main_menu; else check_all_mirrors; fi ;;
    *) error "Unknown option: $1"; usage; exit 2 ;;
  esac
}

main "$@"

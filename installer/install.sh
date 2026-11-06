#!/bin/bash
# Katalyst Exam installer — run on each lab machine from the installer folder:
#
#     sudo ./install.sh              install or update
#     sudo ./install.sh --uninstall  remove Katalyst Exam completely
#
# Needs internet (downloads Firefox ESR from Mozilla and cage from Ubuntu/Debian).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
MOZ_KEYRING=/etc/apt/keyrings/packages.mozilla.org.asc
MOZ_LIST=/etc/apt/sources.list.d/mozilla.list
MOZ_PIN=/etc/apt/preferences.d/mozilla-firefox-esr
MOZ_FPR=35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3

step() { printf '\n==> %s\n' "$*"; }
die()  { printf '\nERROR: %s\n' "$*" >&2; exit 1; }
# Never fail silently: report the command and line that failed.
trap 'rc=$?; printf "\nERROR: install.sh line %s failed (exit %s): %s\n" "$LINENO" "$rc" "$BASH_COMMAND" >&2; exit $rc' ERR

[ "$(id -u)" = 0 ] || die "run with sudo: sudo $0"
export DEBIAN_FRONTEND=noninteractive
# chpasswd/useradd/etc. live in /usr/sbin; some shells (non-login, minimal
# containers) don't have it on PATH even as root.
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ---- Uninstall ---------------------------------------------------------------
if [ "${1:-}" = "--uninstall" ]; then
    step "Removing Katalyst Exam"
    apt-get purge -y katalyst-exam || true
    apt-get purge -y exam-kiosk 2>/dev/null || true   # pre-release name
    read -rp "Also remove Firefox ESR and the Mozilla APT repository? [y/N] " a
    if [[ "$a" =~ ^[Yy] ]]; then
        apt-get purge -y firefox-esr || true
        rm -f "$MOZ_LIST" "$MOZ_PIN" "$MOZ_KEYRING"
        apt-get update -qq || true
    fi
    step "Done. The exam user and exam session have been removed."
    exit 0
fi

# ---- Pre-flight ----------------------------------------------------------------
DEB=$(ls -1 "$HERE"/katalyst-exam_*_all.deb 2>/dev/null | sort -V | tail -n1 || true)
[ -n "$DEB" ] || die "katalyst-exam_*.deb not found next to install.sh"
[ -f "$HERE/katalyst-exam.secrets" ] || die "katalyst-exam.secrets not found (run build-installer.sh)"
[ -f "$HERE/config/allowlist.txt" ] && [ -f "$HERE/config/exam.conf" ] \
    || die "config/allowlist.txt or config/exam.conf missing"

. /etc/os-release
case "${ID:-}" in
    ubuntu)
        dpkg --compare-versions "${VERSION_ID:-0}" lt 22.04 \
            && die "Ubuntu 22.04 or newer required (this is $VERSION_ID)"
        ;;
    debian)
        dpkg --compare-versions "${VERSION_ID:-0}" lt 12 \
            && die "Debian 12 (bookworm) or newer required (this is $VERSION_ID)"
        ;;
    *)
        echo "Warning: tested on Ubuntu/Debian; this is ${PRETTY_NAME:-unknown}."
        ;;
esac

# Load password hashes (plain passwords are never stored in the installer folder)
LOGIN_HASH="" EXIT_HASH=""
# shellcheck disable=SC1091
. "$HERE/katalyst-exam.secrets"
[ -n "$LOGIN_HASH" ] && [ -n "$EXIT_HASH" ] || die "katalyst-exam.secrets is incomplete"

# ---- Repositories --------------------------------------------------------------
step "Preparing package sources"
apt-get update -qq
apt-get install -y -qq ca-certificates wget gnupg software-properties-common >/dev/null

if [ "${ID:-}" = ubuntu ] \
   && ! grep -rqsE '^deb .*ubuntu.* universe' /etc/apt/sources.list /etc/apt/sources.list.d/ \
   && ! grep -rqs 'Components:.*universe' /etc/apt/sources.list.d/; then
    echo "Enabling Ubuntu 'universe' repository (needed for cage)"
    add-apt-repository -y universe
fi

if [ ! -s "$MOZ_KEYRING" ]; then
    echo "Adding Mozilla APT repository"
    install -d -m 0755 /etc/apt/keyrings
    tmpkey=$(mktemp)
    wget -nv --timeout=30 --tries=3 https://packages.mozilla.org/apt/repo-signing-key.gpg -O "$tmpkey" \
        || die "could not download the Mozilla signing key (check internet / proxy)"
    # Throwaway GnuPG home so root's (or sudo user's) keyring is never touched
    gnupg_tmp=$(mktemp -d)
    fpr=$(GNUPGHOME="$gnupg_tmp" gpg --batch --with-colons --import-options show-only \
              --import "$tmpkey" 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}' || true)
    rm -rf "$gnupg_tmp"
    if [ "$fpr" != "$MOZ_FPR" ]; then
        rm -f "$tmpkey"
        die "Mozilla key fingerprint mismatch (got '${fpr:-none}', expected $MOZ_FPR)"
    fi
    install -m 0644 "$tmpkey" "$MOZ_KEYRING"
    rm -f "$tmpkey"
    echo "Mozilla key verified: $fpr"
fi
echo "deb [signed-by=$MOZ_KEYRING] https://packages.mozilla.org/apt mozilla main" > "$MOZ_LIST"
# Only firefox-esr comes from Mozilla; everything else (including the normal
# snap-based "firefox" package students/teachers use) stays as Ubuntu ships it.
cat > "$MOZ_PIN" <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 100

Package: firefox-esr firefox-esr-l10n-*
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

# Remove the pre-release build (package "exam-kiosk") if present
if dpkg -s exam-kiosk >/dev/null 2>&1; then
    step "Removing previous test build (exam-kiosk)"
    apt-get purge -y exam-kiosk
fi

step "Installing Firefox ESR, cage and Katalyst Exam"
apt-get update -qq
# Copy the .deb somewhere apt's sandbox user (_apt) can read (USB / home dirs aren't)
debdir=$(mktemp -d)
chmod 0755 "$debdir"
install -m 0644 "$DEB" "$debdir/"
apt-get install -y "$debdir/$(basename "$DEB")"
rm -rf "$debdir"

# ---- Configuration -------------------------------------------------------------
step "Applying configuration"
install -m 0644 "$HERE/config/allowlist.txt" /etc/katalyst-exam/allowlist.txt
install -m 0644 "$HERE/config/exam.conf"    /etc/katalyst-exam/exam.conf

printf 'exam:%s\n' "$LOGIN_HASH" | chpasswd -e
passwd -u exam >/dev/null 2>&1 || true
install -m 0644 /dev/null /etc/katalyst-exam/exit.hash
printf '%s\n' "$EXIT_HASH" > /etc/katalyst-exam/exit.hash

/usr/lib/katalyst-exam/apply

step "Status"
katalyst-exam-admin status

cat <<'EOF'

Installation complete.
Test it: log out, choose the "Katalyst Exam" user, enter the exam login password.
EOF

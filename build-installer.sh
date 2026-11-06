#!/bin/bash
# Build the Katalyst Exam installer folder. Run on YOUR machine (no sudo needed):
#
#     bash build-installer.sh            prompts for both passwords, builds dist/katalyst-exam-installer/
#     bash build-installer.sh --keep-passwords   rebuild, reusing the existing secrets file
#
# Then copy dist/katalyst-exam-installer/ to the lab machines (USB drive,
# shared folder, ...) and on each one run:
#     sudo ./install.sh
set -euo pipefail

VERSION=0.1.0
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/dist/katalyst-exam-installer"
SECRETS="$OUT/katalyst-exam.secrets"

for t in dpkg-deb openssl python3; do
    command -v "$t" >/dev/null || { echo "Missing tool: $t" >&2; exit 1; }
done

read_password_twice() {
    local a b
    read -rsp "$1: " a; echo >&2
    read -rsp "Repeat: " b; echo >&2
    [ -n "$a" ] || { echo "Empty password." >&2; exit 1; }
    [ "$a" = "$b" ] || { echo "Passwords do not match." >&2; exit 1; }
    [ ${#a} -ge 8 ] || echo "Warning: passwords shorter than 8 characters are easy to guess." >&2
    printf '%s' "$a"
}

# ---- Passwords -----------------------------------------------------------------
mkdir -p "$OUT"
if [ "${1:-}" = "--keep-passwords" ] && [ -f "$SECRETS" ]; then
    echo "Reusing existing passwords from $SECRETS"
else
    echo "Exam login password  = typed by the invigilator to START the exam session"
    login_pw=$(read_password_twice "Exam login password")
    echo "Exit password        = typed by the invigilator to END the exam session"
    exit_pw=$(read_password_twice "Invigilator exit password")
    [ "$login_pw" != "$exit_pw" ] || echo "Warning: using the same password for both is not recommended." >&2

    login_hash=$(printf '%s\n' "$login_pw" | openssl passwd -6 -stdin)
    exit_hash=$(printf '%s\n' "$exit_pw" | python3 -I "$ROOT/pkg/usr/lib/katalyst-exam/hash-password")
    unset login_pw exit_pw
    umask 077
    {
        echo "# Katalyst Exam password hashes (generated $(date -I)). Not plain text,"
        echo "# but keep this folder safe: weak passwords can be brute-forced."
        printf 'LOGIN_HASH=%q\n' "$login_hash"
        printf 'EXIT_HASH=%q\n' "$exit_hash"
    } > "$SECRETS"
    umask 022
fi

# ---- Build the .deb ----------------------------------------------------------------
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
cp -a "$ROOT/pkg/." "$STAGE/"
find "$STAGE" -name __pycache__ -prune -exec rm -rf {} +
sed -i "s/@VERSION@/$VERSION/" "$STAGE/DEBIAN/control"

install -d "$STAGE/usr/share/katalyst-exam/defaults"
install -m 0644 "$ROOT/config/allowlist.txt" "$ROOT/config/exam.conf" \
    "$STAGE/usr/share/katalyst-exam/defaults/"

# Stripped XDG data dir for the exam session: themes/icons/mime/schemas, but no
# applications/ directory, so nothing can be "opened with" another program.
XDG="$STAGE/usr/lib/katalyst-exam/xdg-data"
install -d "$XDG"
for d in icons themes mime glib-2.0 fonts pixmaps X11 gtk-3.0; do
    ln -sfn "/usr/share/$d" "$XDG/$d"
done

find "$STAGE" -type d -exec chmod 0755 {} +
find "$STAGE" -type f -exec chmod 0644 {} +
chmod 0755 "$STAGE"/DEBIAN/{postinst,prerm,postrm} \
           "$STAGE"/usr/sbin/katalyst-exam-admin \
           "$STAGE"/usr/lib/katalyst-exam/{apply,build-policies,exit-guard,hash-password,exam-session,round-chooser,session-wayland,session-x11}

rm -f "$OUT"/katalyst-exam_*_all.deb
dpkg-deb --root-owner-group -Zxz --build "$STAGE" "$OUT/katalyst-exam_${VERSION}_all.deb" >/dev/null

# ---- Assemble the installer folder -------------------------------------------------------
install -m 0755 "$ROOT/installer/install.sh" "$OUT/install.sh"
install -d "$OUT/config"
install -m 0644 "$ROOT/config/allowlist.txt" "$ROOT/config/exam.conf" "$OUT/config/"
cat > "$OUT/README.txt" <<'EOF'
Katalyst Exam installer
====================
On each lab machine (needs internet):

    sudo ./install.sh

To change the allowlist / start page for all machines, edit the files in
config/ in this folder and run install.sh again.

To remove:  sudo ./install.sh --uninstall
EOF

echo
echo "Built: $OUT"
ls -l "$OUT"

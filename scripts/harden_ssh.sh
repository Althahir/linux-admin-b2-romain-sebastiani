#!/bin/bash
# ============================================================
# Script : harden_ssh.sh
# Auteur : Romain Sebastiani
# Date   : 2026-06-18
# Desc   : Durcissement de la configuration SSH du serveur.
# Usage  : sudo ./harden_ssh.sh
# ============================================================

if [ "$EUID" -ne 0 ]; then
echo "[ERREUR] A lancer en tant que root (sudo)." >&2
exit 1
fi

CONFIG="/etc/ssh/sshd_config"
SAUVE="${CONFIG}.bak.$(date +%Y%m%d)"

# === Sauvegarde de la config actuelle ===
cp "$CONFIG" "$SAUVE"
echo "[OK] Sauvegarde : $SAUVE"

# Applique une directive : remplace la ligne (commentee ou
# non), sinon l'ajoute en fin de fichier.
appliquer() {
local cle="$1"
local val="$2"
sed -i "s|^#\?${cle} .*|${cle} ${val}|" "$CONFIG"
grep -q "^${cle} " "$CONFIG" || echo "${cle} ${val}" >> "$CONFIG"
}

# === Regles de durcissement ===
appliquer "PermitRootLogin" "no"
appliquer "PasswordAuthentication" "no"
appliquer "PubkeyAuthentication" "yes"
appliquer "MaxAuthTries" "3"
appliquer "LoginGraceTime" "20"
appliquer "ClientAliveInterval" "300"
appliquer "ClientAliveCountMax" "2"
appliquer "X11Forwarding" "no"
echo "[OK] Directives appliquees."

# === Validation de la syntaxe ===
if sshd -t; then
echo "[OK] Syntaxe sshd valide."
echo "=== Differences (sauvegarde -> nouvelle) ==="
diff "$SAUVE" "$CONFIG"
echo ""
echo "[ACTION] Verifiez puis redemarrez a la main :"
echo "         sudo systemctl restart ssh"
else
echo "[ERREUR] Syntaxe invalide ! Restauration." >&2
cp "$SAUVE" "$CONFIG"
echo "[OK] Config restauree depuis $SAUVE" >&2
exit 1
fi

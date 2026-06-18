#!/bin/bash
  # ============================================================
  # Script : create_users.sh
  # Auteur : Romain Sebastiani
  # Date   : 2026-06-18
  # Desc   : Creation automatisee des comptes de l'equipe dev
  # Usage  : sudo ./create_users.sh
  # ============================================================

  if [ "$EUID" -ne 0 ]; then
      echo "[ERREUR] Ce script doit etre lance en tant que root (sudo)." >&2
      exit 1
  fi

  GROUPE_DEV="devteam"
  GID_DEV=3001
  GROUPE_OPS="ops"
  GID_OPS=3002
  PROJET_DIR="/opt/devproject"

  echo "=== Creation des groupes ==="
  if getent group "$GROUPE_DEV" >/dev/null; then
      echo "[INFO] Le groupe $GROUPE_DEV existe deja."
  else
      groupadd -g "$GID_DEV" "$GROUPE_DEV"
      echo "[OK] Groupe $GROUPE_DEV cree (GID $GID_DEV)."
  fi

  if getent group "$GROUPE_OPS" >/dev/null; then
      echo "[INFO] Le groupe $GROUPE_OPS existe deja."
  else
      groupadd -g "$GID_OPS" "$GROUPE_OPS"
      echo "[OK] Groupe $GROUPE_OPS cree (GID $GID_OPS)."
  fi

  echo "=== Creation des utilisateurs ==="
  creer_utilisateur() {
      local login="$1"
      local uid="$2"
      local groupe="$3"
      local commentaire="$4"
      local motdepasse="$5"

      if id "$login" >/dev/null 2>&1; then
          echo "[INFO] L'utilisateur $login existe deja, creation ignoree."
      else
          useradd -m -s /bin/bash -u "$uid" -g "$groupe" -c "$commentaire" "$login"
          echo "[OK] Utilisateur $login cree (UID $uid, groupe $groupe)."
      fi

      echo "${login}:${motdepasse}" | chpasswd
      chage -d 0 "$login"
  }

  creer_utilisateur "alice"   2001 "$GROUPE_DEV" "Alice - Developpeuse" "alice123!"
  creer_utilisateur "bob"     2002 "$GROUPE_DEV" "Bob - Developpeur"    "bob123!"
  creer_utilisateur "charlie" 2003 "$GROUPE_OPS" "Charlie - Ops"        "charlie123!"

  echo "=== Groupes secondaires ==="
  usermod -aG "$GROUPE_OPS" alice
  echo "[OK] alice ajoutee au groupe secondaire $GROUPE_OPS."

  echo "=== Repertoire projet ==="
  mkdir -p "$PROJET_DIR"
  chown root:"$GROUPE_DEV" "$PROJET_DIR"
  chmod 770 "$PROJET_DIR"
  echo "[OK] $PROJET_DIR cree (root:$GROUPE_DEV, 770)."

  echo ""
  echo "============================================================"
  echo "                     RECAPITULATIF"
  echo "============================================================"
  for u in alice bob charlie; do
      echo "- $(id "$u")"
  done
  echo ""
  echo "Etat du repertoire $PROJET_DIR :"
  ls -ld "$PROJET_DIR"
  echo "============================================================"

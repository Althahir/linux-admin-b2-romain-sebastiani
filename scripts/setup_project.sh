#!/bin/bash
  # ============================================================
  # Script : setup_project.sh
  # Auteur : Romain Sebastiani
  # Date   : 2026-06-18
  # Desc   : Espace de travail partage /srv/devproject
  #          (arborescence, permissions, sticky bit, SGID, ACL)
  # Usage  : sudo ./setup_project.sh
  # ============================================================
 # === Variables ===
  BASE="/srv/devproject"
  GROUPE_DEV="devteam"

  # === Creation de l'arborescence ===
  echo "=== Creation de l'arborescence ==="
  mkdir -p "$BASE"/src "$BASE"/docs "$BASE"/releases "$BASE"/logs
  echo "[OK] Arborescence creee sous $BASE."

  # === Proprietaires ===
  echo "=== Application des proprietaires ==="
  chown root:"$GROUPE_DEV" "$BASE"/src "$BASE"/docs "$BASE"/releases
  chown root:root "$BASE"/logs
  echo "[OK] Proprietaires definis."

  # === Permissions + bits speciaux ===
  echo "=== Application des permissions ==="
  # src/ et docs/ : 770 + SGID(2) + sticky(1) => 3770
  #   SGID   : les nouveaux fichiers heritent du groupe devteam
  #   sticky : seul le proprietaire d'un fichier peut le supprimer
  chmod 3770 "$BASE"/src "$BASE"/docs
  # releases/ : lecture seule pour devteam => 750
  chmod 750 "$BASE"/releases
  # logs/ : accessible uniquement par root => 700
  chmod 700 "$BASE"/logs
  echo "[OK] Permissions, SGID et sticky bit appliques."

  # === ACL : charlie en lecture (r-x) sur docs/ uniquement ===
  echo "=== ACL pour charlie sur docs/ ==="
  setfacl -m u:charlie:r-x "$BASE"/docs
  echo "[OK] ACL u:charlie:r-x ajoutee sur $BASE/docs."

  # === Fichiers de test ===
  echo "=== Creation des fichiers de test ==="
  touch "$BASE"/src/main.c "$BASE"/docs/ARCHITECTURE.md "$BASE"/releases/v1.0.tar.gz
  echo "[OK] Fichiers de test crees."

  # === Recapitulatif ===
  echo ""
  echo "============================================================"
  echo "   RECAPITULATIF : ls -laR $BASE"
  echo "============================================================"
  ls -laR "$BASE"
  echo ""
  echo "============================================================"
  echo "   getfacl $BASE/docs"
  echo "============================================================"
  getfacl "$BASE"/docs

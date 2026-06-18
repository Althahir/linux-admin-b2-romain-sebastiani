#!/bin/bash
  # ============================================================
  # Script : logwatcher_oneshot.sh
  # Auteur : Romain Sebastiani
  # Date   : 2026-06-18
  # Desc   : Version one-shot de logwatcher (pour timer systemd).
  #          Une seule verification ; l'etat est conserve dans
  #          un fichier entre deux declenchements.
  # ============================================================

  AUTH_LOG="/var/log/auth.log"
  [ -f "$AUTH_LOG" ] || AUTH_LOG="/var/log/secure"

  LOG_DIR="/var/log/logwatcher"
  LOG_FILE="$LOG_DIR/activity.log"
  ETAT="$LOG_DIR/last_count"
  SEUIL=5
  MOTIF='Failed password|Invalid user'

  mkdir -p "$LOG_DIR"

  TOTAL=$(grep -cE "$MOTIF" "$AUTH_LOG" 2>/dev/null)
  TOTAL=${TOTAL:-0}

  PRECEDENT=$(cat "$ETAT" 2>/dev/null)
  PRECEDENT=${PRECEDENT:-0}

  NOUVELLES=$((TOTAL - PRECEDENT))
  [ "$NOUVELLES" -lt 0 ] && NOUVELLES=0

  echo "$TOTAL" > "$ETAT"

  HEURE=$(date '+%H:%M:%S')
  DATE=$(date '+%Y-%m-%d %H:%M:%S')

  MSG="[LOGWATCHER] $NOUVELLES tentative(s) SSH"
  MSG="$MSG echouee(s) detectee(s) -- $HEURE"
  echo "$MSG"

  if [ "$NOUVELLES" -gt "$SEUIL" ]; then
      AL="[LOGWATCHER][ALERTE] Pic d'activite"
      AL="$AL suspect : $NOUVELLES tentatives."
      echo "$AL" >&2
  fi

  echo "$DATE - $NOUVELLES tentative(s) echouee(s)" >> "$LOG_FILE"

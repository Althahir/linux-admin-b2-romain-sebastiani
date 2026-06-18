#!/bin/bash
# ============================================================
# Script : logwatcher.sh
# Auteur : Romain Sebastiani
# Date   : 2026-06-18
# Desc   : Surveille les tentatives SSH echouees et
#          journalise l'activite (journald + fichier).
# Usage  : lance par logwatcher.service
# ============================================================

AUTH_LOG="/var/log/auth.log"
[ -f "$AUTH_LOG" ] || AUTH_LOG="/var/log/secure"

LOG_DIR="/var/log/logwatcher"
LOG_FILE="$LOG_DIR/activity.log"
INTERVAL=30
SEUIL=5
MOTIF='Failed password|Invalid user'

mkdir -p "$LOG_DIR"

PRECEDENT=$(grep -cE "$MOTIF" "$AUTH_LOG" 2>/dev/null)
PRECEDENT=${PRECEDENT:-0}

while true; do
    TOTAL=$(grep -cE "$MOTIF" "$AUTH_LOG" 2>/dev/null)
    TOTAL=${TOTAL:-0}

    NOUVELLES=$((TOTAL - PRECEDENT))
    [ "$NOUVELLES" -lt 0 ] && NOUVELLES=0
    PRECEDENT=$TOTAL

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

    LIGNE="$DATE - $NOUVELLES tentative(s) echouee(s)"
    echo "$LIGNE" >> "$LOG_FILE"

    sleep "$INTERVAL"
done


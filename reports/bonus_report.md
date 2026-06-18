
# Bonus — Option A : Timer systemd

**Auteur :** Romain Sebastiani | **Date :** 2026-06-18

## Objectif

Remplacer la boucle `while true` de `logwatcher.sh` (Mission 4) par
un **timer systemd** declenchant une verification toutes les 5 min.
On ajoute un service "oneshot" et un timer.

## 1. Principe

- `logwatcher_oneshot.sh` fait **une seule** verification puis se
  termine (plus de boucle, plus de sleep).
- Chaque execution etant un nouveau processus, le compteur precedent
  est conserve dans un fichier d'etat `/var/log/logwatcher/last_count`.
- Le timer declenche le service oneshot periodiquement.

## 2. Service oneshot (configs/logwatcher_oneshot.service)

```
[Unit]
Description=Verification ponctuelle des echecs SSH
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/logwatcher_oneshot.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=logwatcher
```

## 3. Timer (configs/logwatcher.timer)

```
[Unit]
Description=Declenche logwatcher toutes les 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=logwatcher_oneshot.service

[Install]
WantedBy=timers.target
```

## 4. Deploiement

```
$ sudo systemctl disable --now logwatcher.service
$ sudo cp scripts/logwatcher_oneshot.sh /usr/local/bin/
$ sudo chmod +x /usr/local/bin/logwatcher_oneshot.sh
$ sudo cp configs/logwatcher_oneshot.service /etc/systemd/system/
$ sudo cp configs/logwatcher.timer /etc/systemd/system/
$ sudo systemctl daemon-reload
$ sudo systemctl enable --now logwatcher.timer
```

## 5. Timer actif

```
$ systemctl list-timers logwatcher.timer
NEXT : dans 4min 53s   LAST : il y a 6s
UNIT : logwatcher.timer  ACTIVATES : logwatcher_oneshot
1 timers listed.
```

## 6. Demonstration du fonctionnement

1er passage (fichier d'etat absent -> compte le cumul, alerte) :

```
[LOGWATCHER] 19 tentative(s) SSH echouee(s) detectee(s) -- 14:15:57
[LOGWATCHER][ALERTE] Pic d'activite suspect : 19 tentatives.
```

2e passage, sans nouvelle tentative (compteur relu dans last_count
-> delta = 0) :

```
[LOGWATCHER] 0 tentative(s) SSH echouee(s) detectee(s) -- 14:18:16
```

La persistance de l'etat entre deux executions est validee.

## 7. Avantages par rapport a la boucle while

- Aucun processus en permanence : le service ne consomme des
  ressources qu'au moment du declenchement.
- Planification geree par systemd (precise, journalisee, relancee
  apres reboot grace a OnBootSec).
- `systemctl list-timers` donne une vue claire des echeances.
- Le script ne gere plus le rythme (plus de `sleep`) : c'est le role
  du timer. Separation des responsabilites plus propre.

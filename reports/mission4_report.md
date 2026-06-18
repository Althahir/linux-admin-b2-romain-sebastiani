# Mission 4 — Service systemd custom

**Auteur :** Romain Sebastiani | **Date :** 2026-06-18

## Objectif

Creer un service systemd `logwatcher` qui surveille les tentatives
de connexion SSH echouees (`/var/log/auth.log`), journalise le nombre
detecte a chaque cycle (journald + fichier), et emet une alerte
au-dela de 5 tentatives par cycle.

## 1. Le fichier unit (configs/logwatcher.service)

```
[Unit]
Description=Surveillance des connexions SSH echouees
After=network.target syslog.target

[Service]
Type=simple
ExecStart=/usr/local/bin/logwatcher.sh
Restart=on-failure
RestartSec=10s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=logwatcher

# Durcissement (bonus)
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/log/logwatcher
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
```

## 2. Etat du service (systemctl status)

```
$ sudo systemctl status logwatcher --no-pager
● logwatcher.service - Surveillance des connexions SSH echouees
     Loaded: loaded (.../logwatcher.service; enabled)
     Active: active (running) since 2026-06-18 12:31:55 UTC
   Main PID: 3802 (logwatcher.sh)
     CGroup: /system.slice/logwatcher.service
             |-3802 /bin/bash /usr/local/bin/logwatcher.sh
             `-3810 sleep 30
```

## 3. Logs du service (journalctl)

Fonctionnement normal, puis detection d'un pic (alerte) :

```
$ sudo journalctl -u logwatcher --no-pager -n 20
[LOGWATCHER] 0 tentative(s) SSH echouee(s) -- 12:55:07
[LOGWATCHER] 8 tentative(s) SSH echouee(s) -- 12:55:37
[LOGWATCHER][ALERTE] Pic d'activite suspect : 8 tentatives.
[LOGWATCHER] 0 tentative(s) SSH echouee(s) -- 12:56:07
```

(extrait, prefixe d'horodatage abrege.) Les 8 tentatives ont ete
generees en parallele vers `localhost` avec des utilisateurs
inexistants, depassant le seuil de 5 et declenchant `[ALERTE]`.

## 4. Fichier de log persistant (activity.log)

```
$ cat /var/log/logwatcher/activity.log
2026-06-18 12:31:54 - 0 tentative(s) echouee(s)
2026-06-18 12:47:31 - 4 tentative(s) echouee(s)
2026-06-18 12:55:37 - 8 tentative(s) echouee(s)
2026-06-18 12:56:07 - 0 tentative(s) echouee(s)
```

(extrait : une ligne par cycle de 30 s.)

## 5. Pourquoi Type=simple et non Type=forking ?

Avec `Type=simple`, systemd considere le service demarre des qu'il
lance `ExecStart`, le processus principal restant au premier plan.
Notre script tourne en boucle (`while true`) au premier plan sans se
detacher : `Type=simple` est donc adapte.

`Type=forking` vise les demons qui se dedoublent (fork) en
arriere-plan, le parent se terminant ensuite ; systemd attend alors
la fin du parent. Comme notre script ne fait pas de fork,
`Type=forking` ferait croire a systemd que le demarrage echoue (il
attendrait un fork qui n'arrive jamais).

## 6. Que fait Restart=on-failure ? Cas insuffisant ?

`Restart=on-failure` relance le service uniquement s'il se termine
anormalement (code de sortie non nul ou processus tue par un signal).
Il ne relance pas apres un arret propre (code 0) ni apres un
`systemctl stop` volontaire.

Cas insuffisant : si le script se fige (boucle bloquee, deadlock)
sans se terminer, le processus reste « vivant » pour systemd, donc
aucun redemarrage n'est declenche — il faudrait un `WatchdogSec`. De
meme, une sortie propre en code 0 a cause d'un bug ne serait pas
relancee ; `Restart=always` couvrirait ce cas.

# Mission 5 — Sécurisation SSH & pare-feu

**Auteur :** Romain Sebastiani | **Date :** 2026-06-18

## Objectif

Durcir la configuration SSH via `harden_ssh.sh`, puis filtrer le
trafic reseau avec le pare-feu UFW.

## 1. Durcissement SSH — diff de sshd_config

Le script sauvegarde `sshd_config` puis applique 8 directives. Diff
entre la sauvegarde (original) et la config durcie :

```
$ diff /etc/ssh/sshd_config.bak.20260618 /etc/ssh/sshd_config
< #LoginGraceTime 2m
< #PermitRootLogin prohibit-password
---
> LoginGraceTime 20
> PermitRootLogin no
< #MaxAuthTries 6
---
> MaxAuthTries 3
< #PubkeyAuthentication yes
---
> PubkeyAuthentication yes
< #PasswordAuthentication yes
---
> PasswordAuthentication no
< X11Forwarding yes
---
> X11Forwarding no
< #ClientAliveInterval 0
< #ClientAliveCountMax 3
---
> ClientAliveInterval 300
> ClientAliveCountMax 2
```

## 2. Validation de la syntaxe (sshd -t)

```
$ sudo sshd -t
```

Aucune sortie = configuration valide. En cas d'erreur, le script
restaure automatiquement la sauvegarde et s'arrete.

## 3. Pare-feu UFW (ufw status verbose)

```
$ sudo ufw status verbose
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
Anywhere                   DENY IN     192.0.2.0/24
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
```

Tout le trafic entrant est refuse par defaut, sauf SSH (22), HTTP
(80) et HTTPS (443). La plage de test 192.0.2.0/24 est bloquee
(regle placee en premiere position).

## 4. Test de connexion par cle SSH

Une paire de cles ed25519 a ete generee cote client, la cle publique
ajoutee dans `~/.ssh/authorized_keys` du serveur :

```
$ ssh -i ~/.ssh/devoir_key -p 2222 althahir@127.0.0.1
althahir@VM:~$
```

La connexion aboutit **sans mot de passe** : l'auth par cle marche,
ce qui permet de desactiver le mot de passe sans risque de blocage.

## 5. PasswordAuthentication no vs PermitRootLogin no

Pourquoi desactiver le mot de passe est prioritaire :

`PermitRootLogin no` ne protege qu'un seul compte (root). Un
attaquant peut toujours tenter de forcer le mot de passe des autres
comptes (alice, bob...). `PasswordAuthentication no` supprime
l'authentification par mot de passe pour **tous** les comptes : les
attaques par force brute et par dictionnaire (tres frequentes sur le
port 22) deviennent impossibles, car seule une cle cryptographique
permet de se connecter. C'est une protection bien plus large : elle
ferme le vecteur d'attaque principal (mots de passe faibles ou
reutilises) pour tout le serveur, la ou `PermitRootLogin no` ne ferme
qu'une seule porte.

## 6. Autres mesures de durcissement en production

- **Fail2Ban** : bannir les IP apres X echecs de connexion.
- **Changer le port SSH** par defaut (reduit le bruit des scans).
- **AllowUsers / AllowGroups** : limiter les comptes autorises.
- **2FA / TOTP** en complement de la cle.
- **unattended-upgrades** : mises a jour de securite automatiques.
- **Centralisation des logs** et surveillance (cf. logwatcher).
- **Acces restreint** a un VPN ou a des IP de confiance.
- **Desactiver les algorithmes faibles** (ciphers, MAC, KEX).

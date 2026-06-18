# Mission 3 — Système de fichiers & permissions

**Auteur :** Romain Sebastiani | **Date :** 2026-06-18 | **Niveau :** B2

## Objectif

Mettre en place, via `scripts/setup_project.sh`, un espace de travail
partagé
`/srv/devproject` avec des règles d'accès strictes : permissions POSIX,
sticky bit,
SGID et ACL.

## 1. Arborescence et permissions (ls -laR)

```
$ sudo ls -laR /srv/devproject
/srv/devproject:
drwxr-xr-x  6 root root    4096 Jun 18 09:40 .
drwxr-xr-x  3 root root    4096 Jun 18 09:40 ..
drwxrws--T+ 2 root devteam 4096 Jun 18 09:40 docs
drwx------  2 root root    4096 Jun 18 09:40 logs
drwxr-x---  2 root devteam 4096 Jun 18 09:40 releases
drwxrws--T  2 root devteam 4096 Jun 18 09:40 src

/srv/devproject/docs:
drwxrws--T+ 2 root devteam 4096 Jun 18 09:40 .
-rw-r--r--  1 root devteam    0 Jun 18 09:40 ARCHITECTURE.md

/srv/devproject/logs:
drwx------ 2 root root 4096 Jun 18 09:40 .

/srv/devproject/releases:
drwxr-x--- 2 root devteam 4096 Jun 18 09:40 .
-rw-r--r-- 1 root root    0 Jun 18 09:40 v1.0.tar.gz

/srv/devproject/src:
drwxrws--T 2 root devteam 4096 Jun 18 09:40 .
-rw-r--r-- 1 root devteam 0 Jun 18 09:40 main.c
```

Lecture : `src/` et `docs/` sont en `drwxrws--T` (770 + SGID `s` +
sticky `T`),
`releases/` en `750`, `logs/` en `700`. Le `+` sur `docs/` signale une
ACL active.

## 2. Vérification de l'ACL (getfacl)

```
$ getfacl /srv/devproject/docs
# file: srv/devproject/docs
# owner: root
# group: devteam
# flags: -st
user::rwx
user:charlie:r-x
group::rwx
mask::rwx
other::---
```

`flags: -st` confirme le SGID (`s`) et le sticky (`t`). La ligne
`user:charlie:r-x`
est l'ACL qui donne à charlie un accès lecture sur `docs/`.

## 3. Tests de validation

### 3.1 alice crée un fichier dans src/ (SGID)

```
$ sudo -u alice touch /srv/devproject/src/test_alice.txt
$ sudo ls -l /srv/devproject/src/
-rw-r--r-- 1 root  devteam 0 Jun 18 09:40 main.c
-rw-r--r-- 1 alice devteam 0 Jun 18 09:49 test_alice.txt
```

Le fichier créé par alice appartient au groupe **devteam** (et non au
groupe primaire
d'alice) : c'est le SGID qui force l'héritage du groupe du répertoire.

### 3.2 alice tente de supprimer main.c (sticky bit)

```
$ sudo -u alice rm -f /srv/devproject/src/main.c
rm: cannot remove '/srv/devproject/src/main.c': Operation not permitted
```

main.c appartient à root : grâce au sticky bit, alice ne peut pas le
supprimer bien
qu'elle ait le droit d'écriture sur le dossier `src/`.

### 3.3 charlie lit un fichier dans docs/ (ACL)

```
$ sudo -u charlie cat /srv/devproject/docs/ARCHITECTURE.md
# Architecture du projet
```

charlie (groupe ops, hors devteam) peut lire le fichier uniquement grâce
à l'ACL
`user:charlie:r-x` posée sur `docs/`.

### 3.4 charlie ne peut pas accéder à src/ (ACL bien scopée)

```
$ sudo -u charlie cat /srv/devproject/src/main.c
cat: /srv/devproject/src/main.c: Permission denied
```

L'ACL ne concerne que `docs/` : sur `src/`, charlie reste dans la
catégorie « autres »
(`---`) et n'a donc aucun accès.

## 4. Pourquoi le bit SGID est-il utile en contexte collaboratif ?

Sur un répertoire, le bit SGID force tout nouveau fichier ou
sous-dossier à hériter du
**groupe du répertoire** (ici `devteam`), au lieu du groupe primaire de
l'utilisateur
qui le crée. Dans une équipe, c'est essentiel : sans SGID, des membres
ayant des
groupes primaires différents créeraient des fichiers appartenant à des
groupes
différents, et les coéquipiers ne pourraient plus forcément y accéder.
Avec le SGID,
tous les fichiers du projet appartiennent à `devteam`, ce qui garantit
que chaque
membre conserve ses droits (lecture/écriture) sur le travail des autres,
sans avoir à
corriger le groupe manuellement (`chgrp`) après chaque création. La
preuve concrète :
`main.c` (créé par root) et `test_alice.txt` (créé par alice)
appartiennent tous deux
au groupe `devteam`.

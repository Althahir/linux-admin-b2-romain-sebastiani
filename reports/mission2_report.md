# Mission 2 — Gestion des utilisateurs & des groupes

**Auteur :** Romain Sebastiani | **Date :** 2026-06-18 | **Niveau :** B2

## Objectif

Automatiser, via le script `scripts/create_users.sh`, la création des groupes et des
comptes de l'équipe de développement, et la mise en place du répertoire
`/opt/devproject`.

## 1. Exécution du script (premier lancement)

```
$ sudo ./scripts/create_users.sh
=== Creation des groupes ===
[OK] Groupe devteam cree (GID 3001).
[OK] Groupe ops cree (GID 3002).
=== Creation des utilisateurs ===
[OK] Utilisateur alice cree (UID 2001, groupe devteam).
[OK] Utilisateur bob cree (UID 2002, groupe devteam).
[OK] Utilisateur charlie cree (UID 2003, groupe ops).
=== Groupes secondaires ===
[OK] alice ajoutee au groupe secondaire ops.
=== Repertoire projet ===
[OK] /opt/devproject cree (root:devteam, 770).
RECAPITULATIF :
- uid=2001(alice) gid=3001(devteam) groups=3001(devteam),3002(ops)
- uid=2002(bob) gid=3001(devteam) groups=3001(devteam)
- uid=2003(charlie) gid=3002(ops) groups=3002(ops)
drwxrwx--- 2 root devteam 4096 Jun 18 08:52 /opt/devproject
```

## 2. Vérification des comptes (id)

```
$ id alice; id bob; id charlie
uid=2001(alice) gid=3001(devteam) groups=3001(devteam),3002(ops)
uid=2002(bob) gid=3001(devteam) groups=3001(devteam)
uid=2003(charlie) gid=3002(ops) groups=3002(ops)
```

alice appartient à son groupe primaire `devteam` ET au groupe secondaire `ops`.

## 3. Vérification des groupes (/etc/group)

```
$ cat /etc/group | grep -E 'devteam|ops'
devteam:x:3001:
ops:x:3002:alice
```

Le 4e champ de `/etc/group` ne liste que les membres secondaires. `devteam` est vide
car alice et bob l'ont comme groupe primaire ; `ops` liste alice (secondaire) mais pas
charlie qui l'a en primaire.

## 4. Vérification du répertoire de projet

```
$ ls -ld /opt/devproject/
drwxrwx--- 2 root devteam 4096 Jun 18 08:52 /opt/devproject
```

Propriétaire root, groupe devteam, permissions 770 (rwxrwx---) : accès réservé à root
et aux membres de devteam.

## 5. Forçage du changement de mot de passe

```
$ sudo chage -l alice
Last password change                                    : password must be changed
Password expires                                        : password must be changed
```

`chage -d 0` force chaque utilisateur à changer son mot de passe temporaire dès la
première connexion.

## 6. Idempotence — relance du script

Au second lancement, rien n'est recréé et le script ne plante pas :

```
$ sudo ./scripts/create_users.sh
=== Creation des groupes ===
[INFO] Le groupe devteam existe deja.
[INFO] Le groupe ops existe deja.
=== Creation des utilisateurs ===
[INFO] L'utilisateur alice existe deja, creation ignoree.
[INFO] L'utilisateur bob existe deja, creation ignoree.
[INFO] L'utilisateur charlie existe deja, creation ignoree.
```

**Gestion du cas :** avant chaque création, le script teste l'existence de la
ressource
avec `getent group "$GROUPE"` (groupes) et `id "$login"` (utilisateurs). Si elle
existe
déjà, il affiche `[INFO]` et saute la création au lieu de laisser `groupadd`/`useradd`
échouer. Le script est donc **idempotent** : rejouable sans erreur.


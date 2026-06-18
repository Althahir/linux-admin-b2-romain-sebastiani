## DEVOIR ADMINISTRATION LINUX - Niveau B2

**Prenom / Nom :** Romain SEBASTIANI
**Niveau :** B2
**Date du devoir :** 18 juin 2026
**Distribution de test :** Ubuntu - VirtualBox

## PREREQUIS D'EXECUTION

- VM Linux Ubuntu
- Paquets requis : `acl` (setfacl/getfacl), `ufw`, `openssh-server`
- Les scripts doivent etre lancés en root : `sudo ./scripts/{nom-du-script}.sh

## RESUME DES MISSIONS

- **Mission 1 :** Mise en place du dépot GitHub et structure
- **Mission 2 :** Script `create_users.sh` - création des groupes, des utilisateurs et du répertoire `/opt/devproject`
- **Mission 3 :** Script `setup_project.sh` - arborescence partagée avec stickybit, SGID et ACL
- **Mission 4 :** service systemd `logwatcher` surveillant les connexions SSH échouées.
- **Mission 5 :** script `harden_ssh.sh` et configuration UFW pour sécuriser le serveur.

## TABLEAU DE SYNTHESE
   _____________________________________________________________________________________________
  | Mission               | Description                            | Statut   | Points estimés |          
  |-----------------------|----------------------------------------|----------|----------------|
  | M1 — Dépôt GitHub     | Structure, README, commits             | Terminé  |     10 / 10    |
  | M2 — Users & groupes  | `create_users.sh`                      | En cours |      ? / 20    |
  | M3 — Permissions      | `setup_project.sh`                     | En cours |      ? / 20    |
  | M4 — Service systemd  | `logwatcher.sh` + `logwatcher.service` | En cours |      ? / 20    |
  | M5 — Sécurisation SSH | `harden_ssh.sh` + UFW                  | En cours |      ? / 20    |
  ----------------------------------------------------------------------------------------------

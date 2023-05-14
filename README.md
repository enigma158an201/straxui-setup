# setup straxui wallet for linux ?

## Comment utiliser ce depot git straxui-setup ?

## Nota: TOUTES les commandes doivent être entrées sans les symboles $ 
rappels: 
- le symbole $ sert à mettre en évidence l'invite utilisateur SANS droits super utilisateur
- le symbole # sert à mettre en évidence l'invite utilisateur AVEC droits super utilisateur

## Etape 1: récupération du dépôt
### - si premier téléchargement, clone le repo avec la commande `git clone https://url/vers/repo.git`:
```
    $ git clone https://github.com/enigma158an201/straxui-setup.git
```
rappel: la commande `git clone <url>` va créer un dossier `straxui-setup/` dans le dossier ou la commande a été exécutée

### - si deja cloné, il faut se rendre dans le dossier déjà cloné avec la commande `cd` puis raffraichir le repo avec `git pull`
```
    $ cd <[/]chemin/ou/se/trouve/le/repo/straxui-setup/
    $ git pull
```

## Etape 2: exécution des scripts selon besoins

### ATTENTION: pour TOUTES les opérations suivantes, il faut se placer dans le dossier du depot, pour se faire il faut entrer cette commande en l'adaptant:
```
    $ cd <[/]chemin/ou/se/trouve/le/repo/straxui-setup/
```

### - pour basculer le pare-feu de iptables à nftables (optionnel) et ajouter une proposition de config:
```
    $ bash switch-from-iptables-to-nftables-setup-sky.sh
```

### - pour installer le binaire strax sur debian bullseye via le paquet .deb:
```
    $ bash update-or-install-strax-wallet-deb-bullseye.sh
```

### - pour installer le binaire strax dans le $HOME/bin de l'utilisateur via le fichier .tar.gz (autres distro linux):
```
    $ bash install-strax-wallet-gz.sh
```

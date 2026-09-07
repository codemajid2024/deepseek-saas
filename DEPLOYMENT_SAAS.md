# Guide de Déploiement SaaS Privé - DeepSeek Harness

Ce guide vous accompagne pas à pas pour héberger **DeepSeek Harness** sur un serveur distant (VPS type Hetzner, OVH, DigitalOcean, AWS) ou en local avec un nom de domaine sécurisé en HTTPS et une authentification personnelle.

---

## 📋 Prérequis

1. Un **VPS Linux** (Ubuntu 22.04 / 24.04 LTS recommandé) ou un serveur local avec **Docker** et **Docker Compose**.
2. Un **Nom de Domaine** (ex: `dsh.mondomaine.com`) dont l'enregistrement DNS de type `A` pointe vers l'adresse IP publique de votre serveur.
3. Une clé API DeepSeek valide ([platform.deepseek.com](https://platform.deepseek.com/)).

---

## 🚀 Méthode 1 : Déploiement Rapide sur VPS (Automatisé)

### 1. Cloner ou transférer le projet sur le serveur
```bash
git clone https://github.com/deepseek-ai/deepseek-harness.git
cd deepseek-harness
```

### 2. Exécuter le script de déploiement
```bash
chmod +x deploy.sh
./deploy.sh
```
Le script va vous demander :
- Votre **nom d'utilisateur** d'authentification
- Votre **mot de passe** (il sera automatiquement chiffré et sécurisé avec bcrypt)
- Votre **nom de domaine** (ex: `dsh.mondomaine.com`)
- Votre **clé API DeepSeek**

Une fois terminé, Caddy génère automatiquement le certificat SSL Let's Encrypt et l'application est accessible en HTTPS !

---

## 🛠️ Méthode 2 : Configuration Manuelle

### 1. Générer le mot de passe sécurisé
Générez un hash bcrypt pour votre mot de passe administrateur :
```bash
docker run --rm caddy:2.9-alpine caddy hash-password --plaintext "MonMotDePasseTresSecret"
```

### 2. Remplir le fichier `.env`
Copiez le modèle :
```bash
cp .env.example .env
```
Éditez `.env` :
```env
DOMAIN_NAME=dsh.mondomaine.com
ACME_EMAIL=admin@mondomaine.com
AUTH_USER=monutilisateur
AUTH_HASH_PASSWORD=$2a$14$VOTRE_HASH_BCRYPT_ICI
DEEPSEEK_API_KEY=sk-votre-cle-api
```

### 3. Lancer la pile Docker
```bash
docker compose build
docker compose up -d
```

---

## 🔒 Méthode 3 : Option Cloudflare Tunnel (Zero Trust Access)

Si vous ne souhaitez pas ouvrir les ports `80` et `443` sur votre serveur :
1. Créez un **Cloudflare Tunnel** dans votre tableau de bord Cloudflare Zero Trust.
2. Routez le trafic public `https://dsh.mondomaine.com` vers le service local `http://localhost:3080`.
3. Activez **Cloudflare Access** pour ajouter une authentification par Email/Code PIN à usage unique (One-Time PIN) ou Google/GitHub SSO avant d'accéder à l'application.

---

## 💾 Persistance et Sauvegarde des Données

Les données critiques sont sauvegardées dans les volumes Docker :
- `dsh-data` : Contient l'historique des sessions, les mémoires et la configuration des agents.
- `dsh-workspaces` : Vos projets et répertoires de travail manipulés par les agents.
- `caddy-data` : Les certificats SSL.

Pour sauvegarder toutes vos sessions :
```bash
docker run --rm -v dsh-data:/volume -v $(pwd):/backup alpine tar czf /backup/dsh_backup_$(date +%F).tar.gz -C /volume .
```

---

## 🔄 Mise à jour de l'application

Pour mettre à jour votre instance avec les dernières nouveautés :
```bash
git pull
docker compose build --no-cache
docker compose up -d
```

---

## 🩺 Commandes de Maintenance

- **Voir les logs en temps réel** :
  ```bash
  docker compose logs -f
  ```
- **Redémarrer la pile** :
  ```bash
  docker compose restart
  ```
- **Arrêter la pile** :
  ```bash
  docker compose down
  ```

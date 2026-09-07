#!/usr/bin/env bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}======================================================${NC}"
echo -e "${GREEN}   Déploiement SaaS Privé - DeepSeek Harness (DSH)    ${NC}"
echo -e "${BLUE}======================================================${NC}"

# Check Docker & Docker Compose
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Erreur : Docker n'est pas installé. Veuillez installer Docker avant de continuer.${NC}"
    exit 1
fi

# Create .env if not present
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Création du fichier .env depuis .env.example...${NC}"
    cp .env.example .env
    
    # Prompt for credentials
    read -p "Entrez votre nom d'utilisateur admin [admin] : " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}
    
    read -s -p "Entrez votre mot de passe admin : " ADMIN_PASS
    echo ""
    
    read -p "Entrez votre nom de domaine (ex: dsh.mondomaine.com ou localhost) : " DOMAIN
    DOMAIN=${DOMAIN:-localhost}
    
    read -p "Entrez votre clé API DeepSeek (laisser vide si configurée plus tard) : " API_KEY
    
    # Generate bcrypt hash using Caddy container
    echo -e "${BLUE}Génération du mot de passe sécurisé...${NC}"
    HASHED_PASS=$(docker run --rm caddy:2.9-alpine caddy hash-password --plaintext "$ADMIN_PASS")
    
    # Update .env
    sed -i "s|DOMAIN_NAME=.*|DOMAIN_NAME=$DOMAIN|" .env
    sed -i "s|AUTH_USER=.*|AUTH_USER=$ADMIN_USER|" .env
    sed -i "s|AUTH_HASH_PASSWORD=.*|AUTH_HASH_PASSWORD=$HASHED_PASS|" .env
    sed -i "s|DEEPSEEK_API_KEY=.*|DEEPSEEK_API_KEY=$API_KEY|" .env
    
    echo -e "${GREEN}Fichier .env configuré avec succès !${NC}"
fi

echo -e "${BLUE}Construction et démarrage des conteneurs Docker...${NC}"
docker compose build
docker compose up -d

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN} Déploiement terminé avec succès !${NC}"
echo -e " Accédez à votre instance sur : https://$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
echo -e " Identifiants configurés dans votre fichier .env"
echo -e "${GREEN}======================================================${NC}"

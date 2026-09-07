# PowerShell Deployment Helper for DeepSeek Harness

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   Déploiement SaaS Privé - DeepSeek Harness (DSH)    " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Erreur : Docker Desktop n'est pas détecté. Veuillez installer Docker Desktop." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".env")) {
    Write-Host "Création du fichier .env depuis .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    
    $AdminUser = Read-Host "Entrez votre nom d'utilisateur admin [admin]"
    if ([string]::IsNullOrWhiteSpace($AdminUser)) { $AdminUser = "admin" }
    
    $AdminPass = Read-Host -AsSecureString "Entrez votre mot de passe admin"
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPass)
    $PlainPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    $Domain = Read-Host "Entrez votre nom de domaine ou localhost [localhost]"
    if ([string]::IsNullOrWhiteSpace($Domain)) { $Domain = "localhost" }
    
    $ApiKey = Read-Host "Entrez votre clé API DeepSeek (optionnel)"
    
    Write-Host "Génération du hash sécurisé du mot de passe..." -ForegroundColor Cyan
    $HashedPass = docker run --rm caddy:2.9-alpine caddy hash-password --plaintext "$PlainPass"
    
    (Get-Content .env) `
        -replace 'DOMAIN_NAME=.*', "DOMAIN_NAME=$Domain" `
        -replace 'AUTH_USER=.*', "AUTH_USER=$AdminUser" `
        -replace 'AUTH_HASH_PASSWORD=.*', "AUTH_HASH_PASSWORD=$HashedPass" `
        -replace 'DEEPSEEK_API_KEY=.*', "DEEPSEEK_API_KEY=$ApiKey" | Set-Content .env
        
    Write-Host "Fichier .env généré !" -ForegroundColor Green
}

Write-Host "Démarrage des conteneurs..." -ForegroundColor Cyan
docker compose build
docker compose up -d

Write-Host "`nDéploiement terminé avec succès !" -ForegroundColor Green
Write-Host "Accédez à votre instance locale : http://localhost" -ForegroundColor Yellow

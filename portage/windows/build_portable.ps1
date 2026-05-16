# JellyClient — Build + packaging Windows portable ZERO CONFIG
# Usage : .\portage\windows\build_portable.ps1
# Options :
#   -SkipBuild    : ne pas relancer flutter build (utiliser le build existant)
#   -SkipVlc      : ne pas télécharger VLC (si déjà présent dans le dossier)

param(
    [switch]$SkipBuild,
    [switch]$SkipVlc
)

$ErrorActionPreference = "Stop"
$Root    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Release = "$Root\build\windows\x64\runner\Release"
$Dist    = "$Root\dist"
$Bundle  = "$Dist\JellyClient-Windows-portable"
$VlcDir  = "$Bundle\vlc"

# URL VLC portable (mettre à jour si nouvelle version)
$VlcUrl  = "https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.7z"
$VlcZip  = "$Dist\vlc_portable.7z"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  JellyClient — Packaging Windows ZERO CONFIG  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Étape 1 : Build Flutter ─────────────────────────────────────────────────
if (-not $SkipBuild) {
    Write-Host "[1/4] Build Flutter Windows..." -ForegroundColor Yellow
    Set-Location $Root
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERREUR : flutter build a échoué." -ForegroundColor Red
        exit 1
    }
    Write-Host "      Build OK." -ForegroundColor Green
} else {
    Write-Host "[1/4] Build Flutter : ignoré (-SkipBuild)." -ForegroundColor DarkGray
}

if (-not (Test-Path "$Release\jellyclient.exe")) {
    Write-Host "ERREUR : jellyclient.exe introuvable dans $Release" -ForegroundColor Red
    exit 1
}

# ── Étape 2 : Préparer le dossier bundle ─────────────────────────────────────
Write-Host "[2/4] Préparation du bundle..." -ForegroundColor Yellow
if (Test-Path $Bundle) { Remove-Item $Bundle -Recurse -Force }
New-Item -ItemType Directory -Path $Bundle | Out-Null
New-Item -ItemType Directory -Path $Dist   -Force | Out-Null

Copy-Item "$Release\*" $Bundle -Recurse
Write-Host "      Bundle copié." -ForegroundColor Green

# ── Étape 3 : VLC portable ───────────────────────────────────────────────────
if (-not $SkipVlc) {
    Write-Host "[3/4] Intégration VLC portable..." -ForegroundColor Yellow

    # Vérifier si 7-Zip est disponible pour extraire le .7z
    $SevenZip = "C:\Program Files\7-Zip\7z.exe"
    $Has7z    = Test-Path $SevenZip

    if (-not $Has7z) {
        Write-Host "      7-Zip non trouvé — téléchargement de VLC en ZIP standard..." -ForegroundColor DarkYellow
        # Fallback : version ZIP (si disponible sur le miroir)
        $VlcUrl = "https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.zip"
        $VlcZip = "$Dist\vlc_portable.zip"
    }

    # Télécharger VLC si pas déjà en cache
    if (-not (Test-Path $VlcZip)) {
        Write-Host "      Téléchargement VLC portable (~40 MB)..." -ForegroundColor Yellow
        Write-Host "      URL : $VlcUrl" -ForegroundColor DarkGray
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $VlcUrl -OutFile $VlcZip -UseBasicParsing
            Write-Host "      VLC téléchargé." -ForegroundColor Green
        } catch {
            Write-Host "      AVERTISSEMENT : téléchargement VLC échoué." -ForegroundColor DarkYellow
            Write-Host "      L'app fonctionnera si VLC est installé sur le PC." -ForegroundColor DarkGray
            $VlcZip = $null
        }
    } else {
        Write-Host "      VLC en cache, réutilisation." -ForegroundColor DarkGray
    }

    # Extraire VLC dans le bundle
    if ($VlcZip -and (Test-Path $VlcZip)) {
        New-Item -ItemType Directory -Path $VlcDir -Force | Out-Null
        Write-Host "      Extraction VLC..." -ForegroundColor Yellow
        if ($Has7z) {
            & $SevenZip x $VlcZip "-o$VlcDir" -y | Out-Null
        } else {
            Expand-Archive -Path $VlcZip -DestinationPath $VlcDir -Force
        }
        # Remonter d'un niveau si VLC extrait dans un sous-dossier
        $VlcSub = Get-ChildItem $VlcDir -Directory | Select-Object -First 1
        if ($VlcSub -and (Test-Path "$($VlcSub.FullName)\vlc.exe")) {
            Get-ChildItem "$($VlcSub.FullName)\*" | Move-Item -Destination $VlcDir -Force
            Remove-Item $VlcSub.FullName -Recurse -Force
        }
        Write-Host "      VLC intégré dans le bundle." -ForegroundColor Green
    }
} else {
    Write-Host "[3/4] VLC : ignoré (-SkipVlc)." -ForegroundColor DarkGray
}

# ── Étape 4 : Finalisation ────────────────────────────────────────────────────
Write-Host "[4/4] Finalisation..." -ForegroundColor Yellow

# Icône
$IcoSrc = "$PSScriptRoot\assets\jellyclient.ico"
if (Test-Path $IcoSrc) { Copy-Item $IcoSrc "$Bundle\jellyclient.ico" }

# Lanceur simple (1 double-clic)
@'
@echo off
cd /d "%~dp0"
start "" "jellyclient.exe"
'@ | Out-File -FilePath "$Bundle\Lancer JellyClient.bat" -Encoding ASCII

# Script création raccourci Bureau
@"
`$WshShell  = New-Object -ComObject WScript.Shell
`$Desktop   = [System.Environment]::GetFolderPath('Desktop')
`$Lnk       = `$WshShell.CreateShortcut("`$Desktop\JellyClient.lnk")
`$Dir       = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$Lnk.TargetPath       = "`$Dir\jellyclient.exe"
`$Lnk.WorkingDirectory = `$Dir
`$Ico = "`$Dir\jellyclient.ico"
if (Test-Path `$Ico) { `$Lnk.IconLocation = `$Ico }
`$Lnk.Description = "JellyClient - Client Jellyfin"
`$Lnk.Save()
Write-Host "Raccourci JellyClient cree sur le Bureau !" -ForegroundColor Green
Start-Sleep 2
"@ | Out-File -FilePath "$Bundle\Creer raccourci Bureau.ps1" -Encoding UTF8

# LIRE_MOI
$HasVlc = Test-Path "$VlcDir\vlc.exe"
$VlcNote = if ($HasVlc) {
    "VLC est inclus dans ce dossier. Aucune installation requise."
} else {
    "VLC n'a pas pu etre inclus. Installer VLC depuis https://www.videolan.org/"
}

@"
JellyClient pour Windows 11 — Version portable
===============================================
Installation : AUCUNE

DEMARRER (1 double-clic)
--------------------------
  >> Lancer JellyClient.bat <<

RACCOURCI SUR LE BUREAU (optionnel)
-------------------------------------
  Clic droit sur "Creer raccourci Bureau.ps1"
  -> "Executer avec PowerShell"

LECTEUR VIDEO
-------------
  $VlcNote
  L'application detecte VLC automatiquement.

PREMIERE CONNEXION
------------------
  Au premier lancement, entrer l'URL de votre serveur Jellyfin
  ex: https://jellyfin.votredomaine.com
"@ | Out-File -FilePath "$Bundle\LIRE_MOI.txt" -Encoding UTF8

# ZIP
$ZipPath = "$Dist\JellyClient-Windows-portable.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path $Bundle -DestinationPath $ZipPath

$SizeMB = [math]::Round((Get-Item $ZipPath).Length / 1MB, 1)

Write-Host ""
Write-Host "╔═══════════════════════════════╗" -ForegroundColor Green
Write-Host "║         SUCCES                ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  ZIP portable : $ZipPath" -ForegroundColor White
Write-Host "  Taille       : $SizeMB MB" -ForegroundColor White
Write-Host "  VLC inclus   : $(if ($HasVlc) { 'OUI' } else { 'NON (installer VLC sur le PC)' })" -ForegroundColor $(if ($HasVlc) { 'Green' } else { 'Yellow' })
Write-Host ""
Write-Host "  L'utilisateur n'a QU'A :" -ForegroundColor Cyan
Write-Host "    1. Dezipper le ZIP" -ForegroundColor White
Write-Host "    2. Double-cliquer sur 'Lancer JellyClient.bat'" -ForegroundColor White
Write-Host "    3. Se connecter a son serveur Jellyfin" -ForegroundColor White
Write-Host ""

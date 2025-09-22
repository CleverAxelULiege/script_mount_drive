# net use * /delete
# delete every connection to a remote share

$alphabet = @(
    'Z','Y','X','W','V','U','T','S','R','Q','P','O','N','M',
    'L','K','J','I','H','G','F','E','D'
)

$driveLetter = "";
foreach ($letter in $alphabet) {
    try {
        Get-PSDrive -Name $letter -ErrorAction Stop
    } catch {
        $driveLetter = $letter
        break
    }
}

if($driveLetter -eq "") {
    Write-Host "Aucune lettre libre disponible pour un disque, arrêt du programme."
    exit
}

$serverAddress = "\\192.168.0.0\";
Clear-Host
Write-Host ""
Write-Host "### Connecter un disque réseau : $($driveLetter): ###" -ForegroundColor Green
Write-Host "-> Appuyez sur Entrée pour continuer... " -ForegroundColor Green -NoNewline
Read-Host

$options = @(
    [PSCustomObject]@{ shareName = "apparitoriat"; description = "Nouveau apparitorat" }
    [PSCustomObject]@{ shareName = "conge"; description = "Conge" }
    [PSCustomObject]@{ shareName = "commun"; description = "Nouveau commun" }
    [PSCustomObject]@{ shareName = "commun-ped"; description = "Commun ped" }
)

function Select-Option {
    param (
        [array]$Options
    )

    $index = 0

    do {
        Clear-Host
        Write-Host "Sélectionnez un partage :" -ForegroundColor Green
        for ($i = 0; $i -lt $Options.Count; $i++) {
            if ($i -eq $index) {
                Write-Host "-> $($Options[$i].description)" -ForegroundColor Yellow
            }
            else {
                Write-Host "   $($Options[$i].description)"
            }
        }

        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow' {
                if ($index -gt 0) { 
                    $index-- 
                }
                else { 
                    $index = $Options.Count - 1 
                }
            }
            'DownArrow' {
                if ($index -lt $Options.Count - 1) { 
                    $index++ 
                }
                else { 
                    $index = 0 
                }
            }
            'Enter' {
                return $Options[$index]
            }
        }
    } while ($true)
}

while ($true) {
    $selected = Select-Option -Options $options
    Clear-Host
    Write-Host "Vous avez sélectionné : " -ForegroundColor Yellow -NoNewline
    Write-Host $selected.description -ForegroundColor Green

    Write-Host "Souhaitez-vous changer votre sélection ? " -ForegroundColor Yellow -NoNewline
    $retry = Read-Host " [oui/non]"
    if ($retry.Trim().ToLower() -notin @('oui', 'o', 'yes', 'y')) {
        break
    }
}

$serverAddress += $selected.shareName

$connected = $false
while (-not $connected) {
    Clear-Host
    
    Write-Host "Veuillez entrer vos identifiants pour le disque réseau :" -ForegroundColor Yellow
    Write-Host ""
    
    $User = Read-Host -Prompt "Nom d'utilisateur "
    
    if ([string]::IsNullOrWhiteSpace($User)) {
        Write-Host "Nom d'utilisateur invalide." -ForegroundColor Red
        Write-Host "Souhaitez-vous réessayer ? " -ForegroundColor Yellow -NoNewline
        $retry = Read-Host " [oui/non]"
        if ($retry.Trim().ToLower() -notin @('oui', 'o', 'yes', 'y')) {
            Write-Host "Arrêt du programme" -ForegroundColor Red
            Pause
            exit
        }
        continue
    }
    
    $PWord = Read-Host -Prompt 'Mot de passe' -AsSecureString
    
    if (-not $PWord -or $PWord.Length -eq 0) {
        Write-Host "Mot de passe invalide." -ForegroundColor Red
        Write-Host "Souhaitez-vous réessayer ? " -ForegroundColor Yellow -NoNewline
        $retry = Read-Host " [oui/non]"
        if ($retry.Trim().ToLower() -notin @('oui', 'o', 'yes', 'y')) {
            Write-Host "Arrêt du programme" -ForegroundColor Red
            Pause
            exit
        }
        continue
    }
    
    try {
        $credentialParams = @{
            TypeName     = 'System.Management.Automation.PSCredential'
            ArgumentList = $User, $PWord
        }
        $cred = New-Object @credentialParams
    }
    catch {
        Write-Host "Erreur lors de la création des identifiants : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Souhaitez-vous réessayer ? " -ForegroundColor Yellow -NoNewline
        $retry = Read-Host " [oui/non]"
        if ($retry.Trim().ToLower() -notin @('oui', 'o', 'yes', 'y')) {
            Write-Host "Arrêt du programme" -ForegroundColor Red
            Pause
            exit
        }
        continue
    }
    
    Clear-Host
    Write-Host "Vous allez connecter un disque réseau avec ce nom d'utilisateur :" -ForegroundColor Yellow
    Write-Host $cred.UserName -ForegroundColor Cyan
    Write-Host "Est-ce correct ? " -ForegroundColor Yellow -NoNewline
    $answer = Read-Host " [oui/non]"
    
    if ($answer.Trim().ToLower() -notin @('oui', 'o', 'yes', 'y')) {
        continue
    }
    
    Write-Host "Tentative de connexion au disque réseau..." -ForegroundColor Yellow
    
    try {
        New-PSDrive -Name Z -PSProvider FileSystem -Root $serverAddress -Credential $cred -Persist -ErrorAction Stop
        Write-Host "Connexion réussie !" -ForegroundColor Green
        Write-Host "Le disque réseau Z: est maintenant disponible." -ForegroundColor Green
        $connected = $true
    }
    catch {
        Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Souhaitez-vous réessayer ? " -ForegroundColor Yellow -NoNewline
        $retry = Read-Host " [oui/non]"
        if ($retry.Trim().ToLower() -notin @('oui', 'o', 'yes', 'y')) {
            Write-Host "Arrêt du programme" -ForegroundColor Red
            Pause
            exit
        }
    }
}

Write-Host "Script terminé avec succès." -ForegroundColor Green
Pause

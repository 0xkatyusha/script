# Importer le module Active Directory
Import-Module ActiveDirectory

# Fonction pour obtenir les informations de l'utilisateur
function Get-UserInformation {
    $userInfo = @{}
    $userInfo['FirstName'] = Read-Host "Entrez le prénom de l'utilisateur"
    $userInfo['LastName'] = Read-Host "Entrez le nom de famille de l'utilisateur"
    $userInfo['Service'] = Read-Host "Entrez le service de l'utilisateur (ex. IT, HR, Marketing)"
    $userInfo['Username'] = Read-Host "Entrez le nom d'utilisateur (ex. jdoe)"
    $userInfo['Password'] = Read-Host "Entrez le mot de passe pour l'utilisateur (sera masqué)" -AsSecureString
    return $userInfo
}

# Fonction pour créer un utilisateur Active Directory
function Create-ADUser {
    param (
        [Parameter(Mandatory)]
        $UserInfo,
        [Parameter(Mandatory)]
        $OUBaseDN
    )
    $OU = "OU=$($UserInfo.Service),$OUBaseDN"
    $DisplayName = "$($UserInfo.FirstName) $($UserInfo.LastName)"
    $UserPrincipalName = "$($UserInfo.Username)@enzo.lan"

    New-ADUser -Name $DisplayName `
               -GivenName $UserInfo.FirstName `
               -Surname $UserInfo.LastName `
               -SamAccountName $UserInfo.Username `
               -UserPrincipalName $UserPrincipalName `
               -Path $OU `
               -AccountPassword $UserInfo.Password `
               -Enabled $true `
               -ChangePasswordAtLogon $true `
               -PassThru
}

# Fonction pour créer un répertoire nominatif
function Create-UserDirectory {
    param (
        [Parameter(Mandatory)]
        $Username,
        [Parameter(Mandatory)]
        $BasePath
    )
    $UserDirectory = Join-Path -Path $BasePath -ChildPath $Username
    if (-Not (Test-Path $UserDirectory)) {
        New-Item -ItemType Directory -Path $UserDirectory
        Write-Host "Répertoire $UserDirectory créé."
    } else {
        Write-Host "Le répertoire $UserDirectory existe déjà."
    }
    return $UserDirectory
}

# Fonction pour mapper le répertoire comme lecteur réseau
function Map-HomeDrive {
    param (
        [Parameter(Mandatory)]
        $User,
        [Parameter(Mandatory)]
        $DirectoryPath
    )
    Set-ADUser -Identity $User.SamAccountName -HomeDrive "H:" -HomeDirectory $DirectoryPath
    Write-Host "Lecteur réseau configuré pour l'utilisateur $($User.SamAccountName)."
}

# Script principal
try {
    # Récupérer les informations de l'utilisateur
    $UserInfo = Get-UserInformation

    # Base DN pour les OUs (à adapter à votre environnement)
    $OUBaseDN = "DC=enzo,DC=lan"

    # Chemin de base pour les répertoires utilisateurs (à adapter)
    $BasePath = "\\SRV-Enzo\utilisateurs"

    # Création de l'utilisateur
    $User = Create-ADUser -UserInfo $UserInfo -OUBaseDN $OUBaseDN

    # Création du répertoire nominatif
    $UserDirectory = Create-UserDirectory -Username $UserInfo.Username -BasePath $BasePath

    # Mapper le répertoire nominatif comme lecteur réseau
    Map-HomeDrive -User $User -DirectoryPath $UserDirectory

    Write-Host "Utilisateur $($User.SamAccountName) créé et configuré avec succès."
} catch {
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
}

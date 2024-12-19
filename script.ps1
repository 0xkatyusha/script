# Importer le module Active Directory
Import-Module ActiveDirectory

# Fonction pour réinitialiser le mot de passe
function Reset-UserPassword {
    param (
        [Parameter(Mandatory)]
        [string]$Username
    )
    try {
        # Recherche de l'utilisateur dans Active Directory
        $User = Get-ADUser -Identity $Username -ErrorAction Stop

        # Demander un nouveau mot de passe sécurisé
        $NewPassword = Read-Host "Entrez le nouveau mot de passe pour $Username" -AsSecureString

        # Réinitialisation du mot de passe
        Set-ADAccountPassword -Identity $User.SamAccountName -NewPassword $NewPassword -Reset

        # Optionnel : Obliger l'utilisateur à changer son mot de passe à la prochaine connexion
        Set-ADUser -Identity $User.SamAccountName -ChangePasswordAtLogon $true

        Write-Host "Le mot de passe de l'utilisateur $Username a été réinitialisé avec succès." -ForegroundColor Green
    } catch {
        Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Script principal
try {
    # Demander le nom d'utilisateur du collaborateur
    $Username = Read-Host "Entrez le nom d'utilisateur du collaborateur (ex. jdoe)"

    # Appeler la fonction pour réinitialiser le mot de passe
    Reset-UserPassword -Username $Username
} catch {
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
}

# PowerShell script to configure minimal Active Directory settings
# This example assumes that Active Directory Domain Services are already installed
# on the server.

param(
    [string]$DomainName = "example.local",
    [string]$NetBIOSName = "EXAMPLE",
    [string]$DomainMode = "Win2016",
    [string]$ForestMode = "Win2016"
)

Import-Module ActiveDirectory

try {
    # If the domain does not exist, create a new forest
    if (-not (Get-ADDomain -ErrorAction SilentlyContinue)) {
        Install-ADDSForest \
            -DomainName $DomainName \
            -DomainNetbiosName $NetBIOSName \
            -ForestMode $ForestMode \
            -DomainMode $DomainMode \
            -Force $true
    }

    # Organizational Units
    $ouList = @(
        'Users',
        'Groups',
        'Computers',
        'ServiceAccounts'
    )

    foreach ($ou in $ouList) {
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $ou -Path "DC=$(($DomainName -replace '\\.', ',DC='))"
        }
    }

    # Example groups
    $groupList = @(
        'ITAdmins',
        'Managers',
        'HR'
    )

    foreach ($group in $groupList) {
        if (-not (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $group -GroupScope Global -Path "OU=Groups,DC=$(($DomainName -replace '\\.', ',DC='))"
        }
    }

    # Example password policy adjustments (via the default domain policy)
    Import-Module GroupPolicy
    $gpoName = 'Default Domain Policy'
    Set-GPOption -Guid (Get-GPO -Name $gpoName).Id -Domain $DomainName -Comment "Configured by SetupMinimalAD.ps1"

} catch {
    Write-Error $_
}


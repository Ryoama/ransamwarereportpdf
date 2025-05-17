# ApplySecuritySettings.ps1 - Apply security configurations based on security report
# This script interactively applies each configuration step.
# For settings that cannot be modified via registry or Group Policy, messages will
# be displayed instead of changes.

function Confirm-Action($message) {
    $response = Read-Host "$message [Y/N]"
    return $response -match '^[Yy]'
}

# Registry setting for NetBIOS node type
if (Confirm-Action 'Set NetBIOS NodeType to peer-to-peer (0x2)?') {
    New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Name 'NodeType' -Value 2 -Type DWord
    Write-Output 'NetBIOS NodeType configured.'
} else {
    Write-Output 'Skipped NetBIOS NodeType configuration.'
}

# Domain password and account lockout policy
if (Confirm-Action 'Configure domain password and lockout policy?') {
    Import-Module ActiveDirectory
    $domain = (Get-ADDomain).DistinguishedName
    Set-ADDefaultDomainPasswordPolicy -Identity $domain `
        -ComplexityEnabled $true `
        -MinPasswordLength 15 `
        -PasswordHistoryCount 24 `
        -MinPasswordAge (New-TimeSpan -Days 1) `
        -MaxPasswordAge (New-TimeSpan -Days 90) `
        -LockoutThreshold 5 `
        -LockoutDuration (New-TimeSpan -Minutes 30) `
        -LockoutObservationWindow (New-TimeSpan -Minutes 30)
    Write-Output 'Domain password policy configured.'
} else {
    Write-Output 'Skipped domain password policy configuration.'
}

# Built-in Administrator account hardening
if (Confirm-Action 'Rename, randomize password and disable built-in Administrator account?') {
    Import-Module ActiveDirectory
    $admin = Get-ADUser -Filter {ObjectSID -like '*-500'}
    if ($admin) {
        $newName = 'DisabledAdmin'
        Rename-ADObject -Identity $admin.DistinguishedName -NewName $newName
        $password = [System.Web.Security.Membership]::GeneratePassword(25,4)
        $secure = ConvertTo-SecureString $password -AsPlainText -Force
        Set-ADAccountPassword -Identity $admin -NewPassword $secure -Reset
        Disable-ADAccount -Identity $admin
        Write-Output "Administrator account renamed to $newName, password randomized and account disabled."
    } else {
        Write-Output 'Built-in Administrator account not found.'
    }
} else {
    Write-Output 'Skipped built-in Administrator account hardening.'
}

# Disable Guest account
if (Confirm-Action 'Disable Guest account?') {
    Import-Module ActiveDirectory
    $guest = Get-ADUser -Filter {SamAccountName -eq 'Guest'} -ErrorAction SilentlyContinue
    if ($guest) {
        Disable-ADAccount -Identity $guest
        Write-Output 'Guest account disabled.'
    } else {
        Write-Output 'Guest account not found.'
    }
} else {
    Write-Output 'Skipped Guest account disable.'
}

# Restrict NTLM authentication (LmCompatibilityLevel)
if (Confirm-Action 'Set LmCompatibilityLevel to 5 (NTLMv2 only)?') {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -Type DWord -Value 5
    Write-Output 'LmCompatibilityLevel set to 5.'
} else {
    Write-Output 'Skipped LmCompatibilityLevel configuration.'
}

# Reminder for LAPS deployment
if (Confirm-Action 'Display reminder to deploy Local Administrator Password Solution (LAPS)?') {
    Write-Output 'Ensure LAPS is installed and a GPO is configured to manage local administrator passwords.'
}

Write-Output 'Security configuration process completed.'

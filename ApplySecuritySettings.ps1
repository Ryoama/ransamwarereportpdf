# ApplySecuritySettings.ps1 - Apply security configurations based on security report
# This script interactively applies each configuration step.
# For settings that cannot be modified via registry or Group Policy, messages will
# be displayed instead of changes.

function Confirm-Action($message) {
    $response = Read-Host "$message [Y/N]"
    return $response -match '^[Yy]'
}

# Example: Registry setting for NetBIOS node type
if (Confirm-Action 'Set NetBIOS NodeType to peer-to-peer (0x2)?') {
    New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Name 'NodeType' -Value 2 -Type DWord
    Write-Output 'NetBIOS NodeType configured.'
} else {
    Write-Output 'Skipped NetBIOS NodeType configuration.'
}

# Example: Password policy via Group Policy
if (Confirm-Action 'Configure password policy via Default Domain Policy?') {
    Import-Module GroupPolicy
    $gpo = Get-GPO -Name 'Default Domain Policy'
    # Set minimum password length to 12 as an example
    Set-GPRegistryValue -Name $gpo.DisplayName -Key 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -ValueName 'MinimumPasswordLength' -Type DWord -Value 12
    Write-Output 'Password policy configured.'
} else {
    Write-Output 'Skipped password policy configuration.'
}

# Example: Security measure that requires manual action
if (Confirm-Action 'Display reminder to educate employees about phishing?') {
    Write-Output 'Please provide phishing awareness training to all employees.'
}

Write-Output 'Security configuration process completed.'

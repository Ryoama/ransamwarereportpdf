# ApplySecuritySettings.ps1 - Apply security configurations based on security report
# This script interactively applies each configuration step.
# For settings that cannot be modified via registry or Group Policy, messages will
# be displayed instead of changes.
# セキュリティ報告書の内容を基に、対話形式で各設定を実施するスクリプトです。
# レジストリやグループポリシーで変更できない項目は、通知のみを表示します。

function Confirm-Action($message) {
    # 確認メッセージを表示し、Y または y が入力されたら処理を続行します。
    $response = Read-Host "$message [Y/N]"
    return $response -match '^[Yy]'
}

# Registry setting for NetBIOS node type
# NetBIOS のノードタイプをピアツーピア (0x2) に設定します。
if (Confirm-Action 'Set NetBIOS NodeType to peer-to-peer (0x2)?') {
    New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Name 'NodeType' -Value 2 -Type DWord
    Write-Output 'NetBIOS NodeType configured.'
} else {
    Write-Output 'Skipped NetBIOS NodeType configuration.'
}

# Domain password and account lockout policy
# ドメインのパスワードおよびアカウントロックアウトポリシーを強化します。
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
# 組み込み Administrator アカウントの名前変更、パスワードランダム化、無効化を行います。
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
# ゲストアカウントを無効化します。
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
# NTLM 認証を NTLMv2 のみに制限するため、LmCompatibilityLevel を 5 に設定します。
if (Confirm-Action 'Set LmCompatibilityLevel to 5 (NTLMv2 only)?') {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -Type DWord -Value 5
Write-Output 'LmCompatibilityLevel set to 5.'
} else {
    Write-Output 'Skipped LmCompatibilityLevel configuration.'
}

# UAC settings to enforce elevation prompts on the secure desktop
# UAC の昇格プロンプトを常にセキュリティで保護されたデスクトップで表示する設定
if (Confirm-Action 'Configure UAC to always prompt on the secure desktop?') {
    $uacPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    New-Item -Path $uacPath -Force | Out-Null
    Set-ItemProperty -Path $uacPath -Name 'PromptOnSecureDesktop' -Type DWord -Value 1
    Set-ItemProperty -Path $uacPath -Name 'ConsentPromptBehaviorAdmin' -Type DWord -Value 2
    Write-Output 'UAC secure desktop configuration applied.'
} else {
    Write-Output 'Skipped UAC secure desktop configuration.'
}

# Disable SMBv1 protocol and require SMB signing
# SMBv1 を無効化し、サーバー・クライアントともにデジタル署名を必須とします。
if (Confirm-Action 'Disable SMBv1 and require SMB signatures?') {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -RequireSecuritySignature $true -Force
    Set-SmbClientConfiguration -EnableSMB1Protocol $false -RequireSecuritySignature $true
    Write-Output 'SMBv1 disabled and SMB signatures required.'
} else {
    Write-Output 'Skipped SMB hardening.'
}

# Change RDP port and add firewall rule
# RDP の既定ポートを変更し、ファイアウォール規則を更新します。
if (Confirm-Action 'Change RDP port to 3390 and update firewall rule?') {
    $rdpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
    New-Item -Path $rdpPath -Force | Out-Null
    Set-ItemProperty -Path $rdpPath -Name 'PortNumber' -Type DWord -Value 3390
    if (Get-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-In)') {
        Set-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-In)' -LocalPort 3390
    }
    Write-Output 'RDP port changed to 3390.'
} else {
    Write-Output 'Skipped RDP port change.'
}

# Reminder for LAPS deployment
# LAPS (Local Administrator Password Solution) を導入するようリマインドします。
if (Confirm-Action 'Display reminder to deploy Local Administrator Password Solution (LAPS)?') {
    Write-Output 'Ensure LAPS is installed and a GPO is configured to manage local administrator passwords.'
}

Write-Output 'Security configuration process completed.'

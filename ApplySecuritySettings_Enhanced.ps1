# ApplySecuritySettings_Enhanced.ps1 - Enhanced Security Settings based on Ransomware Report
# This script implements comprehensive security settings based on the ransomware investigation report
# 岡山県精神科医療センターのランサムウェア調査報告書に基づいた包括的なセキュリティ設定スクリプト

param(
    [switch]$NonInteractive = $false,
    [switch]$ReportOnly = $false
)

function Confirm-Action($message) {
    if ($NonInteractive) { return $true }
    $response = Read-Host "$message [Y/N]"
    return $response -match '^[Yy]'
}

function Apply-Setting($description, $scriptBlock) {
    Write-Host "`n[設定] $description" -ForegroundColor Cyan
    if ($ReportOnly) {
        Write-Host "レポートモード: 実行されません" -ForegroundColor Yellow
        return
    }
    if (Confirm-Action "この設定を適用しますか？") {
        try {
            & $scriptBlock
            Write-Host "✓ 設定が正常に適用されました" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ エラー: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "スキップされました" -ForegroundColor Gray
    }
}

Write-Host "========================================" -ForegroundColor Blue
Write-Host "拡張セキュリティ設定スクリプト" -ForegroundColor Blue
Write-Host "ランサムウェア調査報告書に基づく設定" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue

# 1. NetBIOS ノードタイプ設定（報告書記載の設定）
Apply-Setting "NetBIOS NodeTypeをピアツーピア (0x2) に設定" {
    New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Name 'NodeType' -Value 2 -Type DWord
}

# 2. ドメインパスワードポリシー強化（報告書での最小長要求は12文字だが、セキュリティ強化のため15文字に設定）
Apply-Setting "ドメインパスワードポリシーの強化（最小長15文字、複雑性要件有効）" {
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
}

# 3. Built-in Administrator アカウントの強化
Apply-Setting "Built-in Administratorアカウントの無効化と強化" {
    Import-Module ActiveDirectory
    $admin = Get-ADUser -Filter {ObjectSID -like '*-500'}
    if ($admin) {
        # パスワードのランダム化（25文字）
        Add-Type -AssemblyName System.Web
        $password = [System.Web.Security.Membership]::GeneratePassword(25,4)
        $secure = ConvertTo-SecureString $password -AsPlainText -Force
        Set-ADAccountPassword -Identity $admin -NewPassword $secure -Reset
        
        # アカウントの無効化
        Disable-ADAccount -Identity $admin
        
        # アカウント名の変更
        $newName = "DisabledBuiltinAdmin"
        Rename-ADObject -Identity $admin.DistinguishedName -NewName $newName
        Set-ADUser -Identity $admin -UserPrincipalName "$newName@$((Get-ADDomain).DNSRoot)"
    }
}

# 4. Guest アカウントの無効化
Apply-Setting "Guestアカウントの無効化" {
    Import-Module ActiveDirectory
    $guest = Get-ADUser -Filter {SamAccountName -eq 'Guest'} -ErrorAction SilentlyContinue
    if ($guest) {
        Disable-ADAccount -Identity $guest
    }
}

# 5. NTLM認証の制限（NTLMv2のみ許可）
Apply-Setting "LmCompatibilityLevelを5に設定（NTLMv2のみ）" {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -Type DWord -Value 5
}

# 6. UAC設定の強化
Apply-Setting "UACをセキュアデスクトップで常に表示" {
    $uacPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    New-Item -Path $uacPath -Force | Out-Null
    Set-ItemProperty -Path $uacPath -Name 'PromptOnSecureDesktop' -Type DWord -Value 1
    Set-ItemProperty -Path $uacPath -Name 'ConsentPromptBehaviorAdmin' -Type DWord -Value 2
    Set-ItemProperty -Path $uacPath -Name 'EnableLUA' -Type DWord -Value 1
}

# 7. SMB設定の強化（SMBv1無効化、署名必須）
Apply-Setting "SMBv1を無効化し、SMB署名を必須に設定" {
    # SMBv1の無効化
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    Set-SmbClientConfiguration -EnableSMB1Protocol $false -Force
    
    # SMB署名の必須化
    Set-SmbServerConfiguration -RequireSecuritySignature $true -Force
    Set-SmbClientConfiguration -RequireSecuritySignature $true -Force
    
    # SMBの暗号化を有効化
    Set-SmbServerConfiguration -EncryptData $true -Force
}

# 8. RDPポートの変更とセキュリティ強化
Apply-Setting "RDPポート変更（3390）とNLA有効化" {
    $rdpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
    
    # ポート番号の変更
    Set-ItemProperty -Path $rdpPath -Name 'PortNumber' -Type DWord -Value 3390
    
    # Network Level Authentication (NLA) の有効化
    Set-ItemProperty -Path $rdpPath -Name 'UserAuthentication' -Type DWord -Value 1
    
    # 最低限の暗号化レベルを設定
    Set-ItemProperty -Path $rdpPath -Name 'MinEncryptionLevel' -Type DWord -Value 3
    
    # ファイアウォールルールの更新
    if (Get-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-In)' -ErrorAction SilentlyContinue) {
        Set-NetFirewallRule -DisplayName 'Remote Desktop - User Mode (TCP-In)' -LocalPort 3390
    }
}

# 9. Windows Defenderの強化設定
Apply-Setting "Windows Defender Attack Surface Reduction (ASR) ルールの有効化" {
    # Office系マクロのブロック
    Add-MpPreference -AttackSurfaceReductionRules_Ids BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550 -AttackSurfaceReductionRules_Actions Enabled
    Add-MpPreference -AttackSurfaceReductionRules_Ids 3B576869-A4EC-4529-8536-B80A7769E899 -AttackSurfaceReductionRules_Actions Enabled
    
    # スクリプト系の悪用防止
    Add-MpPreference -AttackSurfaceReductionRules_Ids 5BEB7EFE-FD9A-4556-801D-275E5FFC04CC -AttackSurfaceReductionRules_Actions Enabled
    
    # プロセス挿入のブロック
    Add-MpPreference -AttackSurfaceReductionRules_Ids 75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84 -AttackSurfaceReductionRules_Actions Enabled
}

# 10. ネットワーク共有の匿名列挙を防止
Apply-Setting "SAMアカウントと共有の匿名列挙を防止" {
    $lsaPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    Set-ItemProperty -Path $lsaPath -Name 'RestrictAnonymous' -Type DWord -Value 1
    Set-ItemProperty -Path $lsaPath -Name 'RestrictAnonymousSAM' -Type DWord -Value 1
    Set-ItemProperty -Path $lsaPath -Name 'EveryoneIncludesAnonymous' -Type DWord -Value 0
}

# 11. セキュアなDNS設定（Quad9）
Apply-Setting "セキュアDNSリゾルバー（Quad9）の設定" {
    $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "9.9.9.9", "149.112.112.112"
    }
}

# 12. リモートデスクトップユーザーの制限
Apply-Setting "リモートデスクトップユーザーグループの管理" {
    # Administratorsグループを除外し、必要なユーザーのみを追加
    Import-Module ActiveDirectory
    $rdpGroup = Get-ADGroup "Remote Desktop Users"
    # 管理者グループがメンバーの場合は削除
    $members = Get-ADGroupMember -Identity $rdpGroup
    foreach ($member in $members) {
        if ($member.Name -eq "Administrators") {
            Remove-ADGroupMember -Identity $rdpGroup -Members $member -Confirm:$false
        }
    }
}

# 13. PowerShell実行ポリシーの制限
Apply-Setting "PowerShell実行ポリシーの強化" {
    Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine -Force
    # PowerShell 7も含む
    if (Test-Path "$env:ProgramFiles\PowerShell\7\pwsh.exe") {
        & "$env:ProgramFiles\PowerShell\7\pwsh.exe" -Command "Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine -Force"
    }
}

# 14. イベントログサイズの拡大
Apply-Setting "重要なイベントログのサイズ拡大（1GB）" {
    $logs = @('Application', 'Security', 'System')
    foreach ($log in $logs) {
        $logPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$log"
        Set-ItemProperty -Path $logPath -Name 'MaxSize' -Type DWord -Value 1073741824
        Set-ItemProperty -Path $logPath -Name 'Retention' -Type DWord -Value 0
    }
}

# 15. Windows Firewall詳細設定
Apply-Setting "Windows Firewall詳細設定の有効化" {
    # すべてのプロファイルでファイアウォールを有効化
    Set-NetFirewallProfile -All -Enabled True
    
    # デフォルトのインバウンドをブロック（アウトバウンドは許可）
    Set-NetFirewallProfile -All -DefaultInboundAction Block -DefaultOutboundAction Allow
    
    # ログ記録の有効化
    Set-NetFirewallProfile -All -LogBlocked True -LogAllowed True -LogFileName "%SystemRoot%\System32\LogFiles\Firewall\pfirewall.log" -LogMaxSizeKilobytes 16384
}

# LAPS（ローカル管理者パスワードソリューション）のリマインダー
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "重要なリマインダー" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "1. LAPS（Local Administrator Password Solution）の導入を検討してください" -ForegroundColor Yellow
Write-Host "2. 802.1X認証の実装を計画してください" -ForegroundColor Yellow
Write-Host "3. 定期的な脆弱性スキャンとパッチ適用を実施してください" -ForegroundColor Yellow
Write-Host "4. セキュリティ監査ログの定期的な確認を行ってください" -ForegroundColor Yellow
Write-Host "5. ユーザー教育（フィッシング対策等）を継続的に実施してください" -ForegroundColor Yellow

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "セキュリティ設定プロセスが完了しました" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# 設定変更のサマリーをイベントログに記録
if (-not $ReportOnly) {
    $source = "SecurityEnhancement"
    if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
        [System.Diagnostics.EventLog]::CreateEventSource($source, "Application")
    }
    [System.Diagnostics.EventLog]::WriteEntry($source, "Enhanced security settings have been applied based on ransomware report recommendations.", [System.Diagnostics.EventLogEntryType]::Information, 1001)
}
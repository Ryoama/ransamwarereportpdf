# ValidateSecuritySettings.ps1 - セキュリティ設定の検証スクリプト
# 適用されたセキュリティ設定を確認し、レポートを生成します

param(
    [string]$OutputPath = "$env:USERPROFILE\Desktop\SecurityValidationReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

function Test-Setting {
    param(
        [string]$Name,
        [scriptblock]$TestScript,
        [string]$ExpectedValue,
        [string]$Category
    )
    
    $result = @{
        Name = $Name
        Category = $Category
        Status = "Unknown"
        ActualValue = "N/A"
        ExpectedValue = $ExpectedValue
        Message = ""
    }
    
    try {
        $testResult = & $TestScript
        if ($testResult -eq $true) {
            $result.Status = "Compliant"
            $result.Message = "設定は正しく適用されています"
        } else {
            $result.Status = "Non-Compliant"
            $result.ActualValue = $testResult
            $result.Message = "設定が期待値と異なります"
        }
    }
    catch {
        $result.Status = "Error"
        $result.Message = $_.Exception.Message
    }
    
    return $result
}

# 検証結果を格納する配列
$validationResults = @()

Write-Host "セキュリティ設定検証を開始します..." -ForegroundColor Cyan

# NetBIOS設定の確認
$validationResults += Test-Setting -Name "NetBIOS NodeType" -Category "Network" -ExpectedValue "2 (P-node)" -TestScript {
    $nodeType = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters' -Name 'NodeType' -ErrorAction SilentlyContinue
    if ($nodeType.NodeType -eq 2) { return $true } else { return "NodeType: $($nodeType.NodeType)" }
}

# NTLM設定の確認
$validationResults += Test-Setting -Name "LmCompatibilityLevel" -Category "Authentication" -ExpectedValue "5 (NTLMv2 only)" -TestScript {
    $lmLevel = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -ErrorAction SilentlyContinue
    if ($lmLevel.LmCompatibilityLevel -eq 5) { return $true } else { return "Level: $($lmLevel.LmCompatibilityLevel)" }
}

# UAC設定の確認
$validationResults += Test-Setting -Name "UAC Secure Desktop" -Category "System Security" -ExpectedValue "1 (Enabled)" -TestScript {
    $uac = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'PromptOnSecureDesktop' -ErrorAction SilentlyContinue
    if ($uac.PromptOnSecureDesktop -eq 1) { return $true } else { return "Value: $($uac.PromptOnSecureDesktop)" }
}

# SMB設定の確認
$validationResults += Test-Setting -Name "SMBv1 Protocol" -Category "Network" -ExpectedValue "Disabled" -TestScript {
    $smbServer = Get-SmbServerConfiguration
    if ($smbServer.EnableSMB1Protocol -eq $false) { return $true } else { return "SMBv1: Enabled" }
}

$validationResults += Test-Setting -Name "SMB Signing (Server)" -Category "Network" -ExpectedValue "Required" -TestScript {
    $smbServer = Get-SmbServerConfiguration
    if ($smbServer.RequireSecuritySignature -eq $true) { return $true } else { return "Not Required" }
}

$validationResults += Test-Setting -Name "SMB Signing (Client)" -Category "Network" -ExpectedValue "Required" -TestScript {
    $smbClient = Get-SmbClientConfiguration
    if ($smbClient.RequireSecuritySignature -eq $true) { return $true } else { return "Not Required" }
}

# RDP設定の確認
$validationResults += Test-Setting -Name "RDP Port" -Category "Remote Access" -ExpectedValue "3390" -TestScript {
    $rdpPort = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'PortNumber' -ErrorAction SilentlyContinue
    if ($rdpPort.PortNumber -eq 3390) { return $true } else { return "Port: $($rdpPort.PortNumber)" }
}

$validationResults += Test-Setting -Name "RDP NLA" -Category "Remote Access" -ExpectedValue "1 (Enabled)" -TestScript {
    $nla = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -ErrorAction SilentlyContinue
    if ($nla.UserAuthentication -eq 1) { return $true } else { return "Value: $($nla.UserAuthentication)" }
}

# 匿名アクセス制限の確認
$validationResults += Test-Setting -Name "Restrict Anonymous" -Category "Access Control" -ExpectedValue "1" -TestScript {
    $anon = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'RestrictAnonymous' -ErrorAction SilentlyContinue
    if ($anon.RestrictAnonymous -eq 1) { return $true } else { return "Value: $($anon.RestrictAnonymous)" }
}

# パスワードポリシーの確認（Active Directoryが利用可能な場合）
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    
    $validationResults += Test-Setting -Name "Password Minimum Length" -Category "Password Policy" -ExpectedValue "15+" -TestScript {
        try {
            $policy = Get-ADDefaultDomainPasswordPolicy
            if ($policy.MinPasswordLength -ge 15) { return $true } else { return "Length: $($policy.MinPasswordLength)" }
        } catch {
            return "AD Module Error"
        }
    }
    
    $validationResults += Test-Setting -Name "Password Complexity" -Category "Password Policy" -ExpectedValue "Enabled" -TestScript {
        try {
            $policy = Get-ADDefaultDomainPasswordPolicy
            if ($policy.ComplexityEnabled -eq $true) { return $true } else { return "Disabled" }
        } catch {
            return "AD Module Error"
        }
    }
    
    $validationResults += Test-Setting -Name "Account Lockout Threshold" -Category "Password Policy" -ExpectedValue "5" -TestScript {
        try {
            $policy = Get-ADDefaultDomainPasswordPolicy
            if ($policy.LockoutThreshold -eq 5) { return $true } else { return "Threshold: $($policy.LockoutThreshold)" }
        } catch {
            return "AD Module Error"
        }
    }
    
    # Built-in Administrator確認
    $validationResults += Test-Setting -Name "Built-in Administrator" -Category "Account Management" -ExpectedValue "Disabled" -TestScript {
        try {
            $admin = Get-ADUser -Filter {ObjectSID -like '*-500'} -Properties Enabled
            if ($admin.Enabled -eq $false) { return $true } else { return "Enabled" }
        } catch {
            return "AD Module Error"
        }
    }
}

# Windows Firewall設定の確認
$validationResults += Test-Setting -Name "Windows Firewall (Domain)" -Category "Firewall" -ExpectedValue "Enabled" -TestScript {
    $fw = Get-NetFirewallProfile -Name Domain
    if ($fw.Enabled -eq $true) { return $true } else { return "Disabled" }
}

$validationResults += Test-Setting -Name "Windows Firewall (Private)" -Category "Firewall" -ExpectedValue "Enabled" -TestScript {
    $fw = Get-NetFirewallProfile -Name Private
    if ($fw.Enabled -eq $true) { return $true } else { return "Disabled" }
}

$validationResults += Test-Setting -Name "Windows Firewall (Public)" -Category "Firewall" -ExpectedValue "Enabled" -TestScript {
    $fw = Get-NetFirewallProfile -Name Public
    if ($fw.Enabled -eq $true) { return $true } else { return "Disabled" }
}

# PowerShell実行ポリシーの確認
$validationResults += Test-Setting -Name "PowerShell Execution Policy" -Category "Application Control" -ExpectedValue "AllSigned" -TestScript {
    $policy = Get-ExecutionPolicy -Scope LocalMachine
    if ($policy -eq "AllSigned") { return $true } else { return "Policy: $policy" }
}

# Windows Defender設定の確認
$validationResults += Test-Setting -Name "Windows Defender Real-time Protection" -Category "Antivirus" -ExpectedValue "Enabled" -TestScript {
    try {
        $defender = Get-MpComputerStatus
        if ($defender.RealTimeProtectionEnabled -eq $true) { return $true } else { return "Disabled" }
    } catch {
        return "Defender Module Error"
    }
}

# レポートの生成
$report = @"
===============================================
セキュリティ設定検証レポート
実行日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')
ホスト名: $env:COMPUTERNAME
===============================================

概要:
総チェック項目数: $($validationResults.Count)
準拠: $($validationResults | Where-Object {$_.Status -eq "Compliant"} | Measure-Object).Count
非準拠: $($validationResults | Where-Object {$_.Status -eq "Non-Compliant"} | Measure-Object).Count
エラー: $($validationResults | Where-Object {$_.Status -eq "Error"} | Measure-Object).Count

詳細結果:
"@

# カテゴリごとに結果をグループ化
$categories = $validationResults | Group-Object -Property Category

foreach ($category in $categories) {
    $report += "`n`n--- $($category.Name) ---`n"
    
    foreach ($result in $category.Group) {
        $statusSymbol = switch ($result.Status) {
            "Compliant" { "✓" }
            "Non-Compliant" { "✗" }
            "Error" { "⚠" }
            default { "?" }
        }
        
        $report += "`n[$statusSymbol] $($result.Name)"
        $report += "`n    期待値: $($result.ExpectedValue)"
        if ($result.Status -eq "Non-Compliant") {
            $report += "`n    実際の値: $($result.ActualValue)"
        }
        $report += "`n    状態: $($result.Status)"
        $report += "`n    メッセージ: $($result.Message)`n"
    }
}

# 推奨事項
$report += "`n`n===============================================`n"
$report += "推奨事項:`n"

if (($validationResults | Where-Object {$_.Status -eq "Non-Compliant"}).Count -gt 0) {
    $report += "`n非準拠の項目が見つかりました。以下の対応を推奨します:`n"
    
    foreach ($item in ($validationResults | Where-Object {$_.Status -eq "Non-Compliant"})) {
        $report += "- $($item.Name): $($item.ExpectedValue)に設定してください`n"
    }
}

if (($validationResults | Where-Object {$_.Status -eq "Error"}).Count -gt 0) {
    $report += "`nエラーが発生した項目:`n"
    
    foreach ($item in ($validationResults | Where-Object {$_.Status -eq "Error"})) {
        $report += "- $($item.Name): $($item.Message)`n"
    }
}

$report += "`n===============================================`n"

# レポートの保存
$report | Out-File -FilePath $OutputPath -Encoding UTF8

# コンソールに概要を表示
Write-Host "`n検証が完了しました" -ForegroundColor Green
Write-Host "準拠: $($validationResults | Where-Object {$_.Status -eq "Compliant"} | Measure-Object).Count" -ForegroundColor Green
Write-Host "非準拠: $($validationResults | Where-Object {$_.Status -eq "Non-Compliant"} | Measure-Object).Count" -ForegroundColor Red
Write-Host "エラー: $($validationResults | Where-Object {$_.Status -eq "Error"} | Measure-Object).Count" -ForegroundColor Yellow
Write-Host "`nレポートを保存しました: $OutputPath" -ForegroundColor Cyan

# 非準拠項目の一覧表示
if (($validationResults | Where-Object {$_.Status -eq "Non-Compliant"}).Count -gt 0) {
    Write-Host "`n非準拠の項目:" -ForegroundColor Red
    foreach ($item in ($validationResults | Where-Object {$_.Status -eq "Non-Compliant"})) {
        Write-Host "  - $($item.Name)" -ForegroundColor Yellow
    }
}
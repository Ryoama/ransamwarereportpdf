# PowerShell script to configure minimal Active Directory settings
# This example assumes that Active Directory Domain Services are already installed
# on the server.
# 最小限の Active Directory 設定を行うためのスクリプトです。
# 事前に AD DS がインストールされているサーバーで実行することを想定しています。

param(
    [string]$DomainName = "example.local",  # ドメイン名
    [string]$NetBIOSName = "EXAMPLE",       # NetBIOS 名
    [string]$DomainMode = "Win2016",        # ドメイン機能レベル
    [string]$ForestMode = "Win2016"         # フォレスト機能レベル
)

Import-Module ActiveDirectory

try {
    # If the domain does not exist, create a new forest
    # ドメインが存在しない場合は新しいフォレストを作成します。
    if (-not (Get-ADDomain -ErrorAction SilentlyContinue)) {
        Install-ADDSForest \
            -DomainName $DomainName \
            -DomainNetbiosName $NetBIOSName \
            -ForestMode $ForestMode \
            -DomainMode $DomainMode \
            -Force $true
    }

    # Organizational Units
    # 基本的な OU を作成します。
    $ouList = @(
        'Users',           # ユーザー用
        'Groups',          # グループ用
        'Computers',       # コンピューター用
        'ServiceAccounts'  # サービスアカウント用
    )

    foreach ($ou in $ouList) {
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $ou -Path "DC=$(($DomainName -replace '\\.', ',DC='))"
        }
    }

    # Example groups
    # サンプルのグループを作成します。
    $groupList = @(
        'ITAdmins',  # IT 管理者
        'Managers',  # 管理職
        'HR'         # 人事部
    )

    foreach ($group in $groupList) {
        if (-not (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $group -GroupScope Global -Path "OU=Groups,DC=$(($DomainName -replace '\\.', ',DC='))"
        }
    }

    # Example password policy adjustments (via the default domain policy)
    # 既定のドメインポリシーにコメントを追加する例です。
    Import-Module GroupPolicy
    $gpoName = 'Default Domain Policy'
    Set-GPOption -Guid (Get-GPO -Name $gpoName).Id -Domain $DomainName -Comment "Configured by SetupMinimalAD.ps1"

} catch {
    Write-Error $_
}


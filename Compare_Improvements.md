# スクリプト改善点の比較

## 元のスクリプト vs 拡張版スクリプトの比較

### 機能比較表

| 機能 | 元のスクリプト | 拡張版スクリプト |
|------|--------------|----------------|
| パラメータ化 | なし | あり（-NonInteractive, -ReportOnly） |
| エラーハンドリング | 基本的 | 包括的（Try-Catch） |
| ログ出力 | なし | イベントログ記録 |
| カラー表示 | なし | あり |
| 設定項目数 | 約10項目 | 15項目以上 |
| 検証機能 | なし | 専用検証スクリプト |
| レポート生成 | なし | 詳細レポート生成 |

### 新規追加されたセキュリティ設定

1. **Windows Defender ASR（Attack Surface Reduction）**
   - Officeマクロの実行制御
   - スクリプトベースの攻撃防止
   - プロセス挿入のブロック

2. **セキュアDNS設定**
   - Quad9 DNSリゾルバーの設定
   - マルウェア・フィッシングサイトのブロック

3. **詳細なログ設定**
   - イベントログサイズの拡張（1GB）
   - Windows Firewallログの有効化

4. **PowerShell制御**
   - 実行ポリシーをAllSignedに設定
   - PowerShell 7も含めた設定

5. **ネットワークセキュリティの強化**
   - SMB暗号化の有効化
   - 匿名アクセスの詳細制限
   - RDP最低暗号化レベルの設定

### コード品質の改善

**元のスクリプト:**
```powershell
if (Confirm-Action 'Set NetBIOS NodeType to peer-to-peer (0x2)?') {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\...' -Name 'NodeType' -Value 2
    Write-Output 'NetBIOS NodeType configured.'
}
```

**拡張版スクリプト:**
```powershell
Apply-Setting "NetBIOS NodeTypeをピアツーピア (0x2) に設定" {
    New-Item -Path 'HKLM:\SYSTEM\...' -Force | Out-Null
    Set-ItemProperty -Path 'HKLM:\SYSTEM\...' -Name 'NodeType' -Value 2 -Type DWord
}
```

### パスワードポリシーの強化

| 項目 | 元の設定 | 拡張版の設定 |
|------|---------|------------|
| 最小長 | 報告書通り（12文字） | 15文字に強化 |
| Built-in Admin | パスワード変更のみ | 名前変更・無効化・25文字パスワード |
| Guest | 無効化 | 無効化（同じ） |

### 実行オプションの追加

```powershell
# 元のスクリプト
.\ApplySecuritySettings.ps1  # 対話形式のみ

# 拡張版スクリプト
.\ApplySecuritySettings_Enhanced.ps1 -NonInteractive  # 自動実行
.\ApplySecuritySettings_Enhanced.ps1 -ReportOnly      # 確認のみ
```

### 検証機能の追加

拡張版では専用の検証スクリプトにより、以下が可能：

- 設定の準拠性チェック
- 非準拠項目の特定
- 修正推奨事項の提示
- エクスポート可能なレポート

### まとめ

拡張版スクリプトは、元のスクリプトの基本機能を維持しながら、以下の点で大幅に改善されています：

1. **より多くのセキュリティ設定**：報告書の推奨事項をより網羅的に実装
2. **運用性の向上**：パラメータ化、レポートモード、検証機能
3. **エラー処理**：より堅牢なエラーハンドリング
4. **可視性**：カラー出力、詳細なログ、レポート生成
5. **保守性**：モジュール化された設計、詳細なコメント

これらの改善により、より安全で運用しやすいセキュリティ設定の実装が可能になりました。
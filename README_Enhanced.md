# 拡張版セキュリティ設定スクリプト

岡山県精神科医療センターのランサムウェア調査報告書に基づいて、より包括的なセキュリティ設定を実装したスクリプト群です。

## 新規追加ファイル

### 1. ApplySecuritySettings_Enhanced.ps1
元のスクリプトを大幅に拡張した、包括的なセキュリティ設定スクリプトです。

**主な機能拡張:**
- パラメータ化による柔軟な実行（`-NonInteractive`、`-ReportOnly`）
- エラーハンドリングの強化
- より多くのセキュリティ設定項目の追加
  - Windows Defender ASR（Attack Surface Reduction）ルール
  - セキュアDNS（Quad9）の設定
  - イベントログサイズの拡張
  - Windows Firewall詳細設定
  - PowerShell実行ポリシーの強化
  - 匿名アクセスの制限強化
- 設定適用のロギング機能
- カラー出力による視認性の向上

**使用方法:**
```powershell
# 対話形式で実行
.\ApplySecuritySettings_Enhanced.ps1

# 非対話形式で実行（すべての設定を自動適用）
.\ApplySecuritySettings_Enhanced.ps1 -NonInteractive

# レポートモード（実際の変更は行わず、何が変更されるかを確認）
.\ApplySecuritySettings_Enhanced.ps1 -ReportOnly
```

### 2. Security_Requirements_Enhanced.md
報告書の内容を詳細に分析し、より具体的な要件として整理した文書です。

**含まれる内容:**
- 詳細なパスワードポリシー要件
- ネットワークセキュリティ設定の具体的な値
- Windows Defenderの詳細設定
- ログとモニタリングの要件
- 実装の優先順位
- 注意事項と推奨事項

### 3. ValidateSecuritySettings.ps1
適用されたセキュリティ設定を検証し、包括的なレポートを生成するスクリプトです。

**主な機能:**
- 全セキュリティ設定の自動検証
- 準拠/非準拠の判定
- 詳細なレポート生成
- 非準拠項目に対する推奨事項の提示
- エクスポート可能なテキストレポート

**使用方法:**
```powershell
# デフォルトの場所にレポートを生成
.\ValidateSecuritySettings.ps1

# 特定の場所にレポートを保存
.\ValidateSecuritySettings.ps1 -OutputPath "C:\Reports\SecurityValidation.txt"
```

## 改善点の詳細

### 1. セキュリティ強化
- パスワード最小長を15文字に拡張（報告書の12文字から強化）
- Windows Defender ASRルールの追加
- DNS設定にセキュアリゾルバー（Quad9）を追加
- PowerShell実行ポリシーの強化

### 2. 運用性の向上
- パラメータ化による柔軟な実行オプション
- レポートモードによる事前確認機能
- 検証スクリプトによる設定確認の自動化
- エラーハンドリングとロギングの強化

### 3. 可読性と保守性
- カラー出力による視認性向上
- モジュール化された関数設計
- 詳細なコメントと日本語説明
- 一貫性のあるコーディングスタイル

## 実行順序（推奨）

1. **事前検証**
   ```powershell
   .\ValidateSecuritySettings.ps1
   ```
   現在の設定状態を確認

2. **レポートモードで確認**
   ```powershell
   .\ApplySecuritySettings_Enhanced.ps1 -ReportOnly
   ```
   変更内容を事前確認

3. **設定の適用**
   ```powershell
   .\ApplySecuritySettings_Enhanced.ps1
   ```
   対話形式で設定を適用

4. **事後検証**
   ```powershell
   .\ValidateSecuritySettings.ps1
   ```
   設定が正しく適用されたことを確認

## 注意事項

- これらのスクリプトは管理者権限で実行する必要があります
- Active Directoryドメインコントローラーで実行することを前提としています
- 医療システムとの互換性を事前に確認してください
- 重要な本番環境では、必ずテスト環境で事前検証を行ってください

## 今後の拡張予定

- LAPS（Local Administrator Password Solution）の自動設定
- 802.1X認証の設定支援
- Syslogサーバーとの連携設定
- セキュリティベースラインの自動適用
- 定期的な脆弱性スキャンの自動化
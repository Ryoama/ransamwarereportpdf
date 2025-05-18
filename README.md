# ransamwarereportpdf

このリポジトリは、岡山県精神科医療センターで発生したランサムウェア事案の報告書をもとに、Active Directory 環境の最小構成やセキュリティ設定の要点をまとめた資料を提供します。

## 基本ファイル
- `AD_Minimal_Requirements.md`: ADを構築する際の最低限の設定例
- `AD_Security_Summary.md`: 報告書から抽出したセキュリティ要件のまとめ
- `Security_Requirements.md`: グループポリシーなど具体的な設定例
- `SetupMinimalAD.ps1`: 最小構成のAD環境をセットアップするサンプルスクリプト
- `ApplySecuritySettings.ps1`: 対話形式で各種セキュリティ設定を適用するスクリプト

## 拡張版（推奨）
- `ApplySecuritySettings_Enhanced.ps1`: より包括的なセキュリティ設定スクリプト（パラメータ対応）
- `Security_Requirements_Enhanced.md`: 詳細なセキュリティ要件定義書
- `ValidateSecuritySettings.ps1`: セキュリティ設定の検証とレポート生成
- `README_Enhanced.md`: 拡張版の詳細な使用方法
- `Compare_Improvements.md`: 元版と拡張版の比較

## レポートファイル
- `report1_utf8.txt`: 岡山県精神科医療センターランサムウェア事案調査報告書（前半）
- `report2_utf8.txt`: 岡山県精神科医療センターランサムウェア事案調査報告書（後半）

これらを参考に、実際の環境に合わせて調整しご活用ください。拡張版のスクリプトはより多くの推奨設定を含んでおり、運用面でも改善されています。

# ransamwarereportpdf

このリポジトリは、岡山県精神科医療センターで発生したランサムウェア事案の報告書をもとに、Active Directory 環境の最小構成やセキュリティ設定の要点をまとめた資料を提供します。

- `AD_Minimal_Requirements.md`: ADを構築する際の最低限の設定例
- `AD_Security_Summary.md`: 報告書から抽出したセキュリティ要件のまとめ
- `Security_Requirements.md`: グループポリシーなど具体的な設定例
- `SetupMinimalAD.ps1`: 最小構成のAD環境をセットアップするサンプルスクリプト
- `ApplySecuritySettings.ps1`: 対話形式で各種セキュリティ設定を適用するスクリプト

これらを参考に、実際の環境に合わせて調整しご活用ください。

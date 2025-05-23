# Active Directory 最低限の設定要件

本ドキュメントは報告書を参考にした例示であり、実際の環境に合わせて調整してください。

## 設定項目一覧

1. **ドメインとフォレストの作成**
   - ドメイン名および NetBIOS 名の指定
   - フォレスト機能レベルとドメイン機能レベルの設定
2. **組織単位 (OU) の作成**
   - Users
   - Groups
   - Computers
   - ServiceAccounts
3. **グループの作成**
   - ITAdmins
   - Managers
   - HR
4. **パスワードポリシーの設定**
   - 既定のドメインポリシーを編集し、複雑さや最小長などを定義

## 補足

- スクリプト実行には ActiveDirectory 及び GroupPolicy モジュールが必要です。
- 既存環境に適用する際は、設定内容を十分に検証してから実施してください。


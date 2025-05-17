# Active Directory セキュリティ要件まとめ

以下は `report1_utf8.txt` および `report2_utf8.txt` から抽出した、Active Directory に設定すべき主なセキュリティ項目の要件を整理したものです。

## パスワードおよびアカウント管理
- Built-In Administrator アカウントを無効化し、管理者は個別のIDを使用し16桁以上のパスワードを設定する【F:report1_utf8.txt†L3-L6】。
- アカウントロックアウトを有効化し、5回連続失敗でロックアウトする【F:report1_utf8.txt†L2-L6】。
- ローカル管理者パスワードを自動管理するため LAPS を導入し、パスワード使い回しを防止する【F:report1_utf8.txt†L27-L36】。
- Active Directory グループポリシーで短いパスワードを禁止し、最低桁数を12文字以上に設定する【F:report2_utf8.txt†L3-L6】【F:Security_Requirements.md†L8-L10】。

## 権限およびポリシー設定
- ドメインユーザーを Built-in Administrators グループに所属させない【F:report2_utf8.txt†L9-L12】。
- UAC を常時「セキュリティで保護されたデスクトップで同意を要求する」に設定し、特権昇格時の確認を徹底する【F:report2_utf8.txt†L13-L19】。
- グループポリシーで SAM アカウントと共有の匿名列挙を禁止する【F:report1_utf8.txt†L17-L19】。
- NTLMv1 を禁止し、デジタル署名を必須とするなど CIS Benchmark 準拠の設定を施す【F:report1_utf8.txt†L20-L31】。
- Microsoft Defender の各種設定変更をローカルで行えないようグループポリシーで制御する【F:report1_utf8.txt†L20-L31】。

## 接続・認証強化
- リモートデスクトップ接続は既定ポートを変更し、接続元制限とロックアウトを適用する【F:report1_utf8.txt†L7-L13】【F:report1_utf8.txt†L20-L31】。
- スマートカードや Windows Hello for Business を活用した多要素認証を導入する【F:report1_utf8.txt†L32-L36】。
- VPN装置の脆弱性管理を実施し、接続元IP制限を行う【F:report2_utf8.txt†L24-L31】。

## その他の推奨設定
- SMBファイル共有にはデジタル署名を要求し、クライアントでの共有は原則禁止する【F:report1_utf8.txt†L32-L48】。
- Windows Update をポリシーで有効化し最新の脆弱性修正を適用する【F:report2_utf8.txt†L22-L27】。
- ウイルス対策ソフトのアンインストールにはパスワード設定を行う【F:report1_utf8.txt†L1-L5】。

以上の設定を組織のActive Directory環境に適用することで、報告書で指摘された脅威への耐性を高めることができます。

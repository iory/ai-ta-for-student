# 変更履歴

版は `VERSION` と git のタグ (`v0.1.0` など) で表す．`ta version` で入っている版を確かめられる．

## 0.1.0 (2026-11-13)

- 最初の公開版．`ta` (質問・`fix`・`run`・`review`・`call`・`context`・`usage`・`doctor`・`login`・`setup`・`version`)，
  失敗したコマンドを記録する bash のフック，Python の例外を記録するフック．
- `curl ... | bash` でインストールできる (`AITA_VERSION=v0.1.0` で版を指定)．
- TA への指示: 資料に `ri.*` で書く方法があるときはまずそれを示す．spawner の `Failed to acquire lock ... Attempt 1 of 5` だけでは失敗と判断しない．

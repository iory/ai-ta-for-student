# 変更履歴

版は `VERSION` と git のタグ (`v0.1.0` など) で表す．`ta version` で入っている版を確かめられる．

## 0.1.1 (2026-11-14)

- `ta review` は人の TA の確認を前提にしない．コードから分かる項目に問題がなければそう答え，
  コードから分からない項目 (周りに人や机が無いか，電源を切れる人がそばにいるか) は学生に確かめるよう書く．
- `ta review` が参照する資料の名前を `robot-programming-2-2026.md` に直した (存在しない `jedy-demos-2026.md` を指していた)．

## 0.1.0 (2026-11-13)

- 最初の公開版．`ta` (質問・`fix`・`run`・`review`・`call`・`context`・`usage`・`doctor`・`login`・`setup`・`version`)，
  失敗したコマンドを記録する bash のフック，Python の例外を記録するフック．
- `curl ... | bash` でインストールできる (`AITA_VERSION=v0.1.0` で版を指定)．
- TA への指示: 資料に `ri.*` で書く方法があるときはまずそれを示す．spawner の `Failed to acquire lock ... Attempt 1 of 5` だけでは失敗と判断しない．

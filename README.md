# ai-ta-for-student

ロボットプログラミング演習 (robot-programming) の **AI TA** を学生の PC で使うためのもの．
`ta` コマンドで Claude Code が起動し，演習資料をもとに質問に答える．
エラーが出たときは `ta fix` で，直前のエラー・ターミナルの画面・ROS のログをまとめて渡せる．

## 必要なもの

- Ubuntu (bash)．ROS 2 Jazzy と演習資料 (`~/ros2_ws/src/robot-programming`) を入れてあること
- インターネット接続
- GitHub アカウント (演習のアンケートで登録したもの)

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/iory/ai-ta-for-student/main/install.sh | bash
source ~/.bashrc
ta login              # 表示されたコードを github.com/login/device に入力して承認する
ta doctor             # 接続・キー・資料の場所を確認する (全部 ✓ になればよい)
```

- `install.sh` は `ta` コマンド，bash のフック，Python の例外を記録するフック，Claude Code (無ければ) を入れる．
  中身を見てから入れたいときは `git clone https://github.com/iory/ai-ta-for-student` して `./install.sh` でも同じ．
- `ta: command not found` と出るときは `~/.local/bin` が PATH に入っていない．
  `export PATH=$HOME/.local/bin:$PATH` を `~/.bashrc` に足す (普通にログインした Ubuntu では自動で入る)．
- 初めて起動したフォルダでは「このフォルダを信頼するか」と聞かれるので **Yes, I trust this folder** を選ぶ．
- 演習資料が見つからないと言われたら `AITA_DOCS=<.../robot-programming/docs>` で場所を指定する．

## 版と更新

- `ta version` で入っている版を確かめられる (`ta doctor` の 1 行目にも出る)．変更点は [CHANGELOG.md](CHANGELOG.md)．
- 新しい版にするには，インストールのコマンドをもう一度実行する (キーと設定はそのまま残る)．
- 決まった版を入れるときは版を指定する (版の一覧は [Releases](https://github.com/iory/ai-ta-for-student/releases) / タグ)．

```bash
curl -fsSL https://raw.githubusercontent.com/iory/ai-ta-for-student/main/install.sh | AITA_VERSION=v0.1.0 bash
```

## 使い方

| コマンド | すること |
|---|---|
| `ta` / `ta "質問"` | AI TA と会話を始める．演習資料を読んで答える |
| `ta fix [メモ]` | 直前のエラーを集めて直し方を聞く: 最後に失敗したコマンド，`ta run` の出力，tmux / byobu の画面，最新の launch のログ，Python の Traceback，ROS の環境変数 (どれも 30 分以内のもの) |
| `ta run <コマンド>` | コマンドの出力を全部記録しながら実行する．長い出力を `ta fix` に渡したいときに使う |
| `ta review <ファイル.py>` | 実機で動かす前のチェック項目に照らしてコードを見てもらう |
| `ta call [メッセージ]` | 人の TA・教員を呼ぶ．エラーの情報も一緒に届く |
| `ta context` | `ta fix` が送る内容を表示するだけ (何も送らない) |
| `ta usage` | 今日の利用額と上限 |
| `ta setup <キーファイル>` | 配られたキーファイルで設定する (`ta login` を使わない場合) |
| `ta version` | 入っている版 |

- コマンドが失敗すると `[ai-ta] exit N — "ta fix" で…` という 1 行が出る．`AITA_QUIET=1` で消せる．
- AI TA がコマンドを実行したりファイルを書き換えたりするときは，毎回確認を求める (`~/enshu` の中のファイルの書き換えと，資料を読むコマンドは確認なしで行う)．
  Gazebo での確認 (起動，プログラムの実行) は AI TA が実行することがある．
  実機を動かすコマンドは，周りに人や机が無いか・電源を切れる人がそばにいるかを学生に聞いてから実行する．
- 実機で動かす前に，`ta review` でコードを見てもらうとよい．
- 焦げたにおい・煙・発熱・けがなど危ないときは，AI に聞く前にロボットの電源を切り，`ta call` か近くの TA を呼ぶ．

## 記録について

- 質問と AI TA の答えは記録され，教員と TA が見る (演習の改善と，困っている人を見つけるため)．初めて `ta` を起動したときにも表示される．
- `ta fix` / `ta call` で送る前に，キーやパスワードらしい文字列は伏せ字にする．
- キーは `~/.config/ai-ta/env` にある．人に見せたり，ファイルやチャットに貼ったりしない．

## アンインストール

`~/.local/bin/ta`，`~/.local/share/ai-ta`，`~/.config/ai-ta`，`~/.bashrc` に足された ai-ta の行，
Python のユーザ site-packages の `aita_pyhook.py` と `aita-pyhook.pth` を消す．

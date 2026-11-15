# ai-ta-for-student

知能ロボット行動プログラミング演習 (robot-programming) の **AI TA** を学生の PC で使うためのもの．
`ta` コマンドで Claude Code が起動し，演習資料をもとに質問に答える．
エラーが出たときは `ta fix` で，直前のエラー・ターミナルの画面・ROS のログをまとめて渡せる．

## 必要なもの

- Ubuntu (bash または zsh)．ROS 2 Jazzy と演習資料 (`~/ros2_ws/src/robot-programming`) を入れてあること
  - fish など，ほかのシェルには対応していない．演習中はターミナルで `bash` と打って bash で作業する．
    ほかのシェルに対応させたい人は，AI を使ってぜひ PR を送ってほしい ([ta-hook.zsh](ta-hook.zsh) が参考になる)．
- インターネット接続
- GitHub アカウント (演習のアンケートで登録したもの)

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/iory/ai-ta-for-student/main/install.sh | bash
source ~/.bashrc       # zsh なら source ~/.zshrc
ta login              # 表示されたコードを github.com/login/device に入力して承認する
ta doctor             # 接続・キー・資料の場所を確認する (全部 ✓ になればよい)
```

- 学科の PC と自分の PC など，1 人 3 台まで，それぞれの PC で `ta login` できる (PC ごとにキーが出る．同じ PC でやり直すとその PC の分だけ発行し直す．4 台目で `ta login` すると，いちばん古い PC のキーが無効になる)．
- `install.sh` は `ta` コマンド，bash (と zsh) のフック，Python の例外を記録するフック，Claude Code (無ければ) を入れる．
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
| `ta --continue` / `ta --resume` | 前の会話の続きから始める (`--resume` は一覧から選ぶ．ID も付けられる) |
| `ta fix [メモ]` | 直前のエラーを集めて直し方を聞く: 最後に失敗したコマンド，`ta run` の出力，tmux / byobu の画面 (同じセッションの全ウィンドウ，エラーのある画面が先)，最新の launch のログ，Python の Traceback，ROS の環境変数 (どれも 30 分以内のもの) |
| `ta run <コマンド>` | コマンドの出力を全部記録しながら実行する．長い出力を `ta fix` に渡したいときに使う |
| `ta review <ファイル.py>` | 実機で動かす前のチェック項目に照らしてコードを見てもらう |
| `ta call [メッセージ]` | 人の TA・教員を呼ぶ．エラーの情報も一緒に届く |
| `ta context` | `ta fix` が送る内容を表示するだけ (何も送らない) |
| `ta usage` | 今日の利用額と上限，カメラ画像を AI に送る機能 (VLM) に同意したか |
| `ta uninstall` | AI TA を消す (演習が終わったら．[アンインストール](#アンインストール)) |
| `ta setup <キーファイル>` | 配られたキーファイルで設定する (`ta login` を使わない場合) |
| `ta version` | 入っている版 |

- コマンドが失敗すると `[ai-ta] exit N — "ta fix" で…` という 1 行が出る．Ctrl-C や `timeout` で止めたとき (exit 130, 124，`ros2` コマンドの 2 と 254) は出ない．`AITA_QUIET=1` で消せる．
- 会話を終えると Claude Code が `ta --resume <ID>` と表示する (Claude Code 2.1.323 以降)．続きは `ta --continue` か `ta --resume` で始める．`claude --resume …` から再開すると AI TA の設定を通らない．
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

演習が終わったら次を実行する．

```bash
ta uninstall      # 消すものを表示して確認してから消す (-y で確認なし)
```

- `~/.bashrc` に足した ai-ta の行 (元の `~/.bashrc` は `~/.bashrc.ai-ta-backup` に残す)，Python の例外を記録するフック (`aita_pyhook.py`，`aita-pyhook.pth`)，`~/.local/share/ai-ta`，`~/.config/ai-ta` (キーと AI TA との会話)，`~/.cache/ai-ta`，`~/.local/bin/ta` を消す．
- Claude Code は，`install.sh` が入れたとき (0.2.5 以降) だけ一緒に消す．前から入っていたものは残す．`--claude` を付けると必ず消す．
- 消し忘れても，キーの有効期限を過ぎると `[ai-ta] exit N` の表示と Python の例外の記録は止まる (`ta doctor` / `ta login` がキーの期限を `~/.config/ai-ta/expires` に書く)．
- サーバーにある質問と答えの記録は消えない．

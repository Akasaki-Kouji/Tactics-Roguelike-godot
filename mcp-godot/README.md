# mcp-godot

Godot エンジンのヘッドレス実行ツールを提供する MCP サーバー

## 機能

このMCPサーバーは以下のツールを提供します:
- Godotプロジェクトをヘッドレスモードで実行（ウィンドウなし、音声なし）
- Godotプロジェクトを各種プラットフォーム向けにエクスポート
- GDScriptファイルの実行
- Godotエンジンのバージョン情報取得

## インストール

```bash
cd mcp-godot
npm install
```

## 設定方法

### Claude Desktop の設定

Claude Desktop の設定ファイルに以下を追加してください:

**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["C:\\Users\\soumu\\Downloads\\Tactics\\fe-like\\mcp-godot\\index.js"],
      "env": {
        "GODOT_PATH": "C:\\Godot\\godot.exe"
      }
    }
  }
}
```

**注意**: Godotのパスは `C:\Godot` に設定されています。Godot実行ファイルの正確なパス（例: `C:\Godot\godot.exe`）に合わせて `GODOT_PATH` を調整してください。

## 利用可能なツール

### godot_headless_run
Godotプロジェクトをヘッドレスモードで実行します。

**パラメータ:**
- `project_path`（必須）: Godotプロジェクトディレクトリのパス
- `script`（任意）: 実行するメインスクリプト
- `scene`（任意）: 実行するシーンファイル（例: "res://main.tscn"）
- `args`（任意）: 追加のコマンドライン引数

### godot_export
Godotプロジェクトを特定のプラットフォーム向けにエクスポートします。

**パラメータ:**
- `project_path`（必須）: Godotプロジェクトディレクトリのパス
- `preset`（必須）: エクスポートプリセット名（例: "Windows Desktop", "Linux/X11", "HTML5"）
- `output_path`（必須）: エクスポートされたプロジェクトの出力ファイルパス

### godot_script_run
GDScriptファイルをヘッドレスモードで実行します。

**パラメータ:**
- `project_path`（必須）: Godotプロジェクトディレクトリのパス
- `script_path`（必須）: 実行するGDScriptファイルのパス

### godot_version
Godotエンジンのバージョン情報を取得します。

## 使用方法

### 方法1: Claude Desktop (GUI) で使用

Claude Desktop で設定後、自然言語でコマンドを使用できます:

- "Godotプロジェクトを /path/to/project からヘッドレスモードで実行して"
- "Godotプロジェクトを 'Windows Desktop' プリセットで build/game.exe にエクスポートして"
- "インストールされているGodotのバージョンは？"
- "プロジェクト内のスクリプト res://scripts/test.gd を実行して"

### 方法2: CLI で直接使用

`cli.js` を使用してコマンドラインから直接Godotを操作できます:

```bash
# バージョン確認
node cli.js version

# プロジェクトをヘッドレス実行
node cli.js run "C:\path\to\project"

# シーンを指定して実行
node cli.js run "C:\path\to\project" --scene res://main.tscn

# スクリプトを実行
node cli.js script "C:\path\to\project" res://scripts/test.gd

# プロジェクトをエクスポート
node cli.js export "C:\path\to\project" "Windows Desktop" "C:\output\game.exe"

# ヘルプ表示
node cli.js help
```

**使用例の実行:**
```bash
# 使用例のバッチファイルを実行
examples.bat
```

**環境変数の設定:**
```bash
# Godotのパスをカスタマイズする場合
set GODOT_PATH=C:\Godot\Godot_v4.5-stable_win64.exe
node cli.js version
```

## 必要環境

- Node.js 18以上
- Godot Engine（`C:\Godot` にインストール済み）

## ライセンス

MIT

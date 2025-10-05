@echo off
REM Godot CLI ツール使用例

echo ========================================
echo Godot バージョン確認
echo ========================================
node cli.js version

echo.
echo ========================================
echo ヘルプ表示
echo ========================================
node cli.js help

REM 以下は実際のプロジェクトパスに置き換えて使用してください

REM echo.
REM echo ========================================
REM echo プロジェクトをヘッドレス実行
REM echo ========================================
REM node cli.js run "C:\path\to\your\project"

REM echo.
REM echo ========================================
REM echo シーンを指定して実行
REM echo ========================================
REM node cli.js run "C:\path\to\your\project" --scene res://main.tscn

REM echo.
REM echo ========================================
REM echo スクリプトを実行
REM echo ========================================
REM node cli.js script "C:\path\to\your\project" res://scripts/test.gd

REM echo.
REM echo ========================================
REM echo プロジェクトをエクスポート
REM echo ========================================
REM node cli.js export "C:\path\to\your\project" "Windows Desktop" "C:\path\to\output\game.exe"

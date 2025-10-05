#!/usr/bin/env node

import { spawn } from "child_process";
import { promisify } from "util";
import { exec } from "child_process";

const execAsync = promisify(exec);

// Godot executable path
const GODOT_PATH = process.env.GODOT_PATH || "C:\\Godot\\Godot_v4.5-stable_win64.exe";

function runGodotCommand(args) {
  return new Promise((resolve, reject) => {
    console.log(`実行中: ${GODOT_PATH} ${args.join(" ")}`);

    const godot = spawn(GODOT_PATH, args);
    let stdout = "";
    let stderr = "";

    godot.stdout.on("data", (data) => {
      const text = data.toString();
      stdout += text;
      process.stdout.write(text);
    });

    godot.stderr.on("data", (data) => {
      const text = data.toString();
      stderr += text;
      process.stderr.write(text);
    });

    godot.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`Godot exited with code ${code}`));
      } else {
        resolve({ stdout, stderr });
      }
    });

    godot.on("error", (err) => {
      reject(new Error(`Failed to start Godot: ${err.message}`));
    });
  });
}

async function normalRun(projectPath, options = {}) {
  const args = ["--path", projectPath];

  if (options.scene) {
    args.push(options.scene);
  } else if (options.script) {
    args.push("--script", options.script);
  }

  if (options.args) {
    args.push(...options.args);
  }

  try {
    await runGodotCommand(args);
    console.log("\n✓ 実行が完了しました");
  } catch (error) {
    console.error(`\n✗ エラー: ${error.message}`);
    process.exit(1);
  }
}

async function headlessRun(projectPath, options = {}) {
  const args = ["--headless", "--path", projectPath];

  if (options.scene) {
    args.push(options.scene);
  } else if (options.script) {
    args.push("--script", options.script);
  }

  if (options.args) {
    args.push(...options.args);
  }

  try {
    await runGodotCommand(args);
    console.log("\n✓ ヘッドレス実行が完了しました");
  } catch (error) {
    console.error(`\n✗ エラー: ${error.message}`);
    process.exit(1);
  }
}

async function exportProject(projectPath, preset, outputPath) {
  const args = [
    "--headless",
    "--path", projectPath,
    "--export-release", preset,
    outputPath,
  ];

  try {
    await runGodotCommand(args);
    console.log(`\n✓ エクスポートが完了しました: ${outputPath}`);
  } catch (error) {
    console.error(`\n✗ エラー: ${error.message}`);
    process.exit(1);
  }
}

async function runScript(projectPath, scriptPath) {
  const args = [
    "--headless",
    "--path", projectPath,
    "--script", scriptPath,
  ];

  try {
    await runGodotCommand(args);
    console.log("\n✓ スクリプト実行が完了しました");
  } catch (error) {
    console.error(`\n✗ エラー: ${error.message}`);
    process.exit(1);
  }
}

async function getVersion() {
  try {
    const { stdout } = await execAsync(`"${GODOT_PATH}" --version`);
    console.log(`Godot バージョン: ${stdout.trim()}`);
  } catch (error) {
    console.error(`エラー: ${error.message}`);
    process.exit(1);
  }
}

function showHelp() {
  console.log(`
Godot CLI ツール

使い方:
  node cli.js <command> [options]

コマンド:
  run <project_path>              プロジェクトを通常モードで実行（ウィンドウ表示）
    --scene <scene_path>          実行するシーンを指定 (例: res://main.tscn)
    --script <script_path>        実行するスクリプトを指定
    --headless                    ヘッドレスモードで実行
    --args <arg1> <arg2> ...      追加の引数

  export <project_path> <preset> <output_path>
                                  プロジェクトをエクスポート
    例: node cli.js export ./project "Windows Desktop" ./build/game.exe

  script <project_path> <script_path>
                                  スクリプトを実行

  version                         Godotのバージョンを表示

環境変数:
  GODOT_PATH                      Godot実行ファイルのパス
                                  (デフォルト: ${GODOT_PATH})

例:
  node cli.js run ./my_project
  node cli.js run ./my_project --scene res://main.tscn
  node cli.js run ./my_project --headless
  node cli.js export ./my_project "Windows Desktop" ./build/game.exe
  node cli.js script ./my_project res://scripts/test.gd
  node cli.js version
`);
}

// メイン処理
const args = process.argv.slice(2);
const command = args[0];

(async () => {
  try {
    switch (command) {
      case "run": {
        const projectPath = args[1];
        if (!projectPath) {
          console.error("エラー: project_path が必要です");
          showHelp();
          process.exit(1);
        }

        const options = {};
        let useHeadless = false;
        for (let i = 2; i < args.length; i++) {
          if (args[i] === "--scene") {
            options.scene = args[++i];
          } else if (args[i] === "--script") {
            options.script = args[++i];
          } else if (args[i] === "--headless") {
            useHeadless = true;
          } else if (args[i] === "--args") {
            options.args = args.slice(i + 1);
            break;
          }
        }

        if (useHeadless) {
          await headlessRun(projectPath, options);
        } else {
          await normalRun(projectPath, options);
        }
        break;
      }

      case "export": {
        const [, projectPath, preset, outputPath] = args;
        if (!projectPath || !preset || !outputPath) {
          console.error("エラー: project_path, preset, output_path が必要です");
          showHelp();
          process.exit(1);
        }
        await exportProject(projectPath, preset, outputPath);
        break;
      }

      case "script": {
        const [, projectPath, scriptPath] = args;
        if (!projectPath || !scriptPath) {
          console.error("エラー: project_path, script_path が必要です");
          showHelp();
          process.exit(1);
        }
        await runScript(projectPath, scriptPath);
        break;
      }

      case "version":
        await getVersion();
        break;

      case "help":
      case "--help":
      case "-h":
        showHelp();
        break;

      default:
        console.error(`エラー: 不明なコマンド '${command}'`);
        showHelp();
        process.exit(1);
    }
  } catch (error) {
    console.error(`エラー: ${error.message}`);
    process.exit(1);
  }
})();

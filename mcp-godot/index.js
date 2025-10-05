#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";
import { promisify } from "util";
import { exec } from "child_process";

const execAsync = promisify(exec);

const server = new Server(
  {
    name: "mcp-godot",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Godot executable path (can be customized via environment variable)
const GODOT_PATH = process.env.GODOT_PATH || "godot";

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "godot_headless_run",
        description: "Run Godot project in headless mode (no window, no audio)",
        inputSchema: {
          type: "object",
          properties: {
            project_path: {
              type: "string",
              description: "Path to the Godot project directory containing project.godot",
            },
            script: {
              type: "string",
              description: "Optional: Main script to run",
            },
            scene: {
              type: "string",
              description: "Optional: Scene file to run (e.g., res://main.tscn)",
            },
            args: {
              type: "array",
              items: { type: "string" },
              description: "Additional command-line arguments for Godot",
            },
          },
          required: ["project_path"],
        },
      },
      {
        name: "godot_export",
        description: "Export Godot project for a specific platform",
        inputSchema: {
          type: "object",
          properties: {
            project_path: {
              type: "string",
              description: "Path to the Godot project directory",
            },
            preset: {
              type: "string",
              description: "Export preset name (e.g., 'Windows Desktop', 'Linux/X11', 'HTML5')",
            },
            output_path: {
              type: "string",
              description: "Output file path for the exported project",
            },
          },
          required: ["project_path", "preset", "output_path"],
        },
      },
      {
        name: "godot_script_run",
        description: "Run a GDScript file in headless mode",
        inputSchema: {
          type: "object",
          properties: {
            project_path: {
              type: "string",
              description: "Path to the Godot project directory",
            },
            script_path: {
              type: "string",
              description: "Path to the GDScript file to execute",
            },
          },
          required: ["project_path", "script_path"],
        },
      },
      {
        name: "godot_version",
        description: "Get Godot engine version",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "godot_headless_run": {
        const { project_path, script, scene, args: extraArgs = [] } = args;

        const godotArgs = [
          "--headless",
          "--path", project_path,
        ];

        if (scene) {
          godotArgs.push(scene);
        } else if (script) {
          godotArgs.push("--script", script);
        }

        godotArgs.push(...extraArgs);

        const result = await runGodotCommand(godotArgs);

        return {
          content: [
            {
              type: "text",
              text: `Godot headless execution completed:\n\n${result}`,
            },
          ],
        };
      }

      case "godot_export": {
        const { project_path, preset, output_path } = args;

        const godotArgs = [
          "--headless",
          "--path", project_path,
          "--export-release", preset,
          output_path,
        ];

        const result = await runGodotCommand(godotArgs);

        return {
          content: [
            {
              type: "text",
              text: `Export completed:\n\n${result}`,
            },
          ],
        };
      }

      case "godot_script_run": {
        const { project_path, script_path } = args;

        const godotArgs = [
          "--headless",
          "--path", project_path,
          "--script", script_path,
        ];

        const result = await runGodotCommand(godotArgs);

        return {
          content: [
            {
              type: "text",
              text: `Script execution completed:\n\n${result}`,
            },
          ],
        };
      }

      case "godot_version": {
        const { stdout } = await execAsync(`${GODOT_PATH} --version`);

        return {
          content: [
            {
              type: "text",
              text: `Godot version: ${stdout.trim()}`,
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

function runGodotCommand(args) {
  return new Promise((resolve, reject) => {
    const godot = spawn(GODOT_PATH, args);
    let stdout = "";
    let stderr = "";

    godot.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    godot.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    godot.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`Godot exited with code ${code}\n${stderr}`));
      } else {
        resolve(stdout || stderr || "Command completed successfully");
      }
    });

    godot.on("error", (err) => {
      reject(new Error(`Failed to start Godot: ${err.message}`));
    });
  });
}

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP Godot server running on stdio");
}

main().catch((error) => {
  console.error("Server error:", error);
  process.exit(1);
});

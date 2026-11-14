import { homedir } from "node:os";
import { join } from "node:path";

const data = process.env.XDG_DATA_HOME || join(homedir(), ".local/share");
const config = process.env.XDG_CONFIG_HOME || join(homedir(), ".config");
const acpx = join(data, "opencode/acp-client/node_modules/.bin/acpx");
const copilot = join(data, "zed/external_agents/registry/npx/github-copilot-cli/node_modules/.bin/copilot");
const commonArgs = [
  "--approve-reads", "--no-terminal", "--non-interactive-permissions", "deny",
  "--auth-policy", "skip", "--timeout", "65", "--format", "quiet",
  "--mcp-config", join(config, "opencode/personal/acp-mcp.json"),
];

const tools = [
  {
    name: "consult_antigravity",
    role: "antigravity-advisor",
    label: "Antigravity",
    command: "/usr/bin/agy acp --sandbox",
    options: ["--config-option", "mode=plan"],
  },
  {
    name: "consult_copilot",
    role: "copilot-review",
    label: "GitHub Copilot",
    command: `${copilot} --acp --stdio --mode plan --disable-builtin-mcps --available-tools=view,grep,glob`,
    options: [],
  },
];

export async function registerConsultations(ctx) {
  await ctx.tool.transform((editor) => {
    for (const {name, label, command, options} of tools) {
      editor.add({
        name,
        description: `Send one scoped, read-only question to ${label} via ACP.`,
        input: {
          type: "object",
          properties: { question: { type: "string", minLength: 1, maxLength: 6000 } },
          required: ["question"],
          additionalProperties: false,
        },
        options: { codemode: false },
        async execute({ question }, call) {
          await ctx.permission.assert({
            sessionID: call.sessionID,
            agent: call.agent,
            source: { type: "tool", messageID: call.messageID, id: call.id },
            action: name,
            resources: ["*"],
            save: [],
          });
          const prompt = "Read-only consultation. Inspect only relevant project files. Do not modify files or run mutating commands. Return concise findings with file and line references when relevant.\n\n" + question;
          const child = Bun.spawn([acpx, "--agent", command, ...commonArgs, "exec", ...options, "--file", "-"], {
            cwd: ctx.location.directory,
            stdin: new Blob([prompt]),
            stdout: "pipe",
            stderr: "pipe",
            signal: AbortSignal.any([call.signal, AbortSignal.timeout(75_000)]),
          });
          const [output, error, code] = await Promise.all([
            new Response(child.stdout).text(), new Response(child.stderr).text(), child.exited,
          ]);
          if (code !== 0) {
            return { content: `${label} consultation exited with status ${code}. ${error.trim().slice(0, 1000)}` };
          }
          return { content: output.trim().slice(0, 9000) || `${label} returned no response.` };
        },
      });
    }
  });

  await ctx.session.hook("context", (event) => {
    const active = event.agent?.id ?? event.agent;
    const advisor = tools.find(({ role }) => role === active);
    if (advisor) {
      for (const name of Object.keys(event.tools)) {
        if (name !== advisor.name) delete event.tools[name];
      }
      return;
    }
    for (const {name} of tools) delete event.tools[name];
  });
}

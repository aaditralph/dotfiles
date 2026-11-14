import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { Plugin } from "@opencode/plugin";
import { registerConsultations } from "./consult.js";

const run = promisify(execFile);
const lookup = /^(?:where (?:is|are|does|do)|which file (?:defines|contains|exports)|(?:find|locate|list|show me) (?:the )?(?:files?|paths?|definition|declaration|imports?|exports?|callers?|references?|usages?)(?:\s|$))/i;
const higherRisk = /\b(?:auth(?:entication|orization)?|clerk|rbac|permissions?|security|credentials?|secrets?|tokens?|production|deploy\w*|migrat\w*|schema|data loss|concurren\w*|performance|lighthouse|accessibility|screenshots?|regressions?|root cause|architecture|kernel|systemd|ssh|refactor\w*|audit\w*|entire|whole|across|multiple|all files|and then|and also)\b/i;
const routineCopy = /^(?:summarize|explain|reword|rewrite|format)\s+(?:this (?:paragraph|snippet|text|message|function|error|log)|the following (?:code|snippet|paragraph)|(?:the )?(?:readme|changelog|docstring|comment|heading|label|\S+\.md)\b)/i;
const routineEdit = /^(?:fix|correct|update|change|rename|add|remove)\s+(?:the |a |one )?(?:typo|docstring|comment|button (?:label|text)|heading|label|log message)\b/i;

function classify(prompt) {
  const text = prompt.text.trim();
  if (!text || text.length > 700 || prompt.files?.length || prompt.agents?.length || prompt.skills?.length || higherRisk.test(text)) {
    return "quality";
  }
  if (lookup.test(text) && !/\b(?:fix|edit|replace|implement|delete|remove|change|write|git|commit|branch|diff)\b/i.test(text)) {
    return "local";
  }
  if (routineCopy.test(text) || routineEdit.test(text)) return "nim";
  return "quality";
}

function isBusy(session) {
  return (session.time.busy ?? 0) > (session.time.idle ?? 0);
}

function reference(model) {
  return model && model.providerID + "/" + model.id;
}

function selection(ref) {
  const slash = ref.indexOf("/");
  return { providerID: ref.slice(0, slash), id: ref.slice(slash + 1) };
}

export default Plugin.define({
  id: "personal.model-routing",
  async setup(ctx) {
    await registerConsultations(ctx);
    const { local, nim, quality } = ctx.options;
    const launcher = join(homedir(), ".local/bin/local-llm");
    const localProvider = selection(local).providerID;
    const localTools = new Set(["glob", "grep", "read"]);
    let startup;
    const routing = new Set();

    function ensureLocal() {
      startup ??= (async () => {
        try {
          const response = await fetch("http://127.0.0.1:18081/health", { signal: AbortSignal.timeout(500) });
          if (response.ok) return true;
        } catch {
          // The existing launcher starts the server on AC power.
        }
        try {
          await run(launcher, ["start"], { timeout: 15_000 });
          return true;
        } catch {
          return false;
        }
      })().finally(() => { startup = undefined; });
      return startup;
    }

    await ctx.session.hook("prompt", async ({ sessionID, prompt, delivery }) => {
      if (delivery === "queue" || routing.has(sessionID)) return;
      routing.add(sessionID);
      try {
        const session = await ctx.session.get({ sessionID });
        if (session.parentID || isBusy(session) || (session.agent && session.agent !== "auto")) return;

        const current = reference(session.model);
        const key = "route/" + sessionID;
        const previous = await ctx.storage.get(key);
        if (session.model?.variant && session.model.variant !== "default") return;
        if (previous && current !== previous) return;
        if (!previous) {
          // The terminal creates Auto sessions with the configured default already selected.
          if (current && (session.agent !== "auto" || current !== quality[1])) return;
          if ((await ctx.session.context({ sessionID })).length) return;
        }
        if (previous && quality.includes(previous)) return;

        const available = new Set((await ctx.model.list()).data.map(reference));
        const lane = classify(prompt);
        const strong = quality.find((model) => available.has(model));
        const quick = available.has(nim) ? nim : undefined;
        let next = lane === "quality" ? strong : quick ?? strong;
        if (lane === "local" && available.has(local) && await ensureLocal()) next = local;
        if (!next || next === current) return;

        const latest = await ctx.session.get({ sessionID });
        if (isBusy(latest) || latest.agent !== session.agent || reference(latest.model) !== current) return;
        await ctx.session.switchModel({ sessionID, model: selection(next) });
        await ctx.storage.set(key, next);
      } catch (error) {
        console.warn("Personal model routing could not choose a model:", error?.name ?? "Error");
      } finally {
        routing.delete(sessionID);
      }
    });

    await ctx.session.hook("context", (event) => {
      const agent = event.agent?.id ?? event.agent;
      if (agent !== "auto" || reference(event.model) !== local) return;
      for (const name of Object.keys(event.tools)) {
        if (!localTools.has(name)) delete event.tools[name];
      }
      event.options.maxTokens = 768;
      event.system.push({
        type: "text",
        text: "This is a read-only code lookup. Use narrow grep or glob queries and read only the relevant lines. Return paths and line numbers. Say if evidence is missing.",
      });
    }, { providerID: localProvider });

    await ctx.session.hook("http.request", async () => {
      if (!await ensureLocal()) {
        throw new Error("Local model unavailable. Check AC power or select a cloud model.");
      }
    }, { providerID: localProvider });
  },
});

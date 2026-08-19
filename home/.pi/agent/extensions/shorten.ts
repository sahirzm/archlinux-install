// shorten — append a pre-turn system-prompt rule that suppresses
// self-correction explanations and other low-value narration.
//
// Hooks `before_agent_start` (fires after the user submits a prompt,
// before the agent loop) and appends a rule to the system prompt so it
// applies on every turn regardless of model or provider.

// Minimal local typing — avoids depending on @earendil-works/pi-coding-agent
// type resolution in this (non-node) repo. The real ExtensionAPI is injected
// by pi's jiti loader at runtime; types are erased and not needed there.
interface BeforeAgentStartEvent {
  systemPrompt: string;
}

interface ExtensionApi {
  on(
    event: "before_agent_start",
    handler: (event: BeforeAgentStartEvent) => Promise<unknown> | unknown,
  ): void;
}

const RULE = [
  "",
  "## Output discipline (enforced by extension `shorten`)",
  "",
  "Skip self-correction explanations and process narration entirely. Concretely:",
  "- Do NOT narrate your steps (\"Let me read…\", \"Now I'll fix…\", \"Next I'll…\").",
  "- Do NOT explain advisory/lint/autofix messages or describe cleanup you performed.",
  "- Do NOT recap what you changed, what was wrong before, or why you corrected it, unless the user asks.",
  "- Do NOT add caveats, \"behavior notes\", or follow-up explanations the user did not request.",
  "- State only the final result and any blocker the user must act on. If the work is done, a one-line confirmation is enough.",
  "- Never pad responses to seem thorough. Shorter is correct here; terseness is not rudeness.",
].join("\n");

export default function (pi: ExtensionApi) {
  pi.on("before_agent_start", (event) => {
    return { systemPrompt: event.systemPrompt + "\n" + RULE };
  });
}

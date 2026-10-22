import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("refine-launch", {
    description: "Extracts prompt inside <prompt> tags and launches a fresh session",
    handler: async (_args, ctx) => {
      // 1. Read history from current session BEFORE replacing it
      const branch = ctx.sessionManager.getBranch();

      // Detect the currently active pi-open-agents agent (if any) so it can be
      // re-applied in the fresh session. pi-open-agents persists it as custom
      // entries: "active_agent" (on apply/clear) and "open-agents-state" (on
      // turn_start). The latest entry of either type wins; a null/undefined
      // name means no agent is active.
      const agentEntry = [...branch]
        .reverse()
        .find(
          (entry: any) =>
            entry.type === "custom" &&
            (entry.customType === "open-agents-state" || entry.customType === "active_agent"),
        );
      const activeAgentName: string | undefined = (agentEntry as any)?.data?.name ?? undefined;

      const lastAssistantEntry = [...branch]
        .reverse()
        .find((entry) => entry.type === "message" && entry.message.role === "assistant");

      if (!lastAssistantEntry || lastAssistantEntry.type !== "message") {
        ctx.ui.notify("Error: No agent messages found in this session.", "error");
        return;
      }

      const content = lastAssistantEntry.message.content;

      // Extract raw text
      const rawText = typeof content === "string" 
        ? content 
        : content.map((part: any) => part.text || "").join("\n");

      // 2. Extract prompt inside <prompt>...</prompt>
      const promptMatch = rawText.match(/<prompt>([\s\S]*?)<\/prompt>/i);

      if (!promptMatch) {
        ctx.ui.notify("Error: No <prompt>...</prompt> tags found in the latest message.", "error");
        return;
      }

      const cleanPrompt = promptMatch[1].trim();

      if (!cleanPrompt) {
        ctx.ui.notify("Error: The extracted <prompt> block was empty.", "error");
        return;
      }

      ctx.ui.notify("Spawning fresh session...", "info");

      // 3. Create fresh session and execute post-replacement work inside withSession
      await ctx.newSession({
        withSession: async (replacementCtx) => {
          // Re-apply the previously active agent by dispatching pi-open-agents'
          // /agent command (runs the command handler directly, no LLM turn).
          // Guarded by getCommands() so it's a no-op when pi-open-agents isn't loaded.
          if (
            activeAgentName &&
            replacementCtx.getCommands().some((cmd) => cmd.name === "agent")
          ) {
            await replacementCtx.sendUserMessage(`/agent ${activeAgentName}`, {
              expandPromptTemplates: true,
            });
          }
          // Use replacementCtx and pi in the fresh session context
          await replacementCtx.sendUserMessage(cleanPrompt);
        },
      });
    },
  });
}
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("refine-launch", {
    description: "Extracts prompt inside <prompt> tags and launches a fresh session",
    handler: async (_args, ctx) => {
      // 1. Read history from current session BEFORE replacing it
      const branch = ctx.sessionManager.getBranch();

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
          // Use replacementCtx and pi in the fresh session context
          await replacementCtx.sendUserMessage(cleanPrompt);
        },
      });
    },
  });
}
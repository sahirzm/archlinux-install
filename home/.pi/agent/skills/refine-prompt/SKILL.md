---
name: refine-prompt
description: Guides a brainstorming session to produce a complete task prompt wrapped in <prompt> tags
---

# Prompt Refinement & Brainstorming Protocol

When this skill is invoked:
1. Act as a principal software architect and prompt engineering expert.
2. Engage in a deep-dive brainstorming session to explore requirements, edge cases, system boundaries, and test criteria.
3. Do **NOT** execute any file modifications or write production code during this session—focus purely on architecture, context gathering, and specification.

### Final Output Requirements
When the user indicates they are satisfied or asks for the final prompt:
- Output a single, standalone prompt payload.
- Ensure it includes: **Title/Context**, **Problem Statement**, **Detailed Tasks**, **Acceptance Criteria**, and **Verification Commands**.
- **CRITICAL:** You MUST enclose the entire final prompt strictly inside `<prompt>` and `</prompt>` tags. 
- Any conversational questions or commentary MUST remain OUTSIDE the `<prompt>` tags.

Example structure:
Here is your finalized prompt:

<prompt>
## Refined prompt

### Context
...

### Tasks
...

### Acceptance Criteria
...
</prompt>

Ready to execute? Run `/refine-launch` to start a fresh session!
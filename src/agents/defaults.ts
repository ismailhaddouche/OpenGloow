// Defaults for agent metadata when upstream does not supply them.
// Model id uses pi-ai's built-in Anthropic catalog.
export const DEFAULT_PROVIDER = "google";
export const DEFAULT_MODEL = "gemini-3-pro-preview";
// Context window: Gemini 1.5 Pro supports ~2M tokens
export const DEFAULT_CONTEXT_TOKENS = 2_000_000;

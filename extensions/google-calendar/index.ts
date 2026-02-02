import { Extension, type ExtensionContext } from "@agentclientprotocol/sdk";
import { google } from "googleapis";

export default class GoogleCalendarExtension extends Extension {
    name = "google-calendar";
    description = "Google Calendar integration for creating and listing events.";

    async activate(ctx: ExtensionContext) {
        // This requires authentication to be handled, possibly reusing Google auth from other components or explicit setup
        // For now, these are placeholder tools representing the intent.

        ctx.tool({
            name: "calendar_list_events",
            description: "List upcoming events from the user's primary calendar.",
            inputSchema: {
                type: "object",
                properties: {
                    maxResults: { type: "number", description: "Max number of events to return" },
                },
            },
            handler: async (input) => {
                return { content: [{ type: "text", text: "Listing events is not yet fully implemented. Needs OAuth setup." }] };
            },
        });

        ctx.tool({
            name: "calendar_create_event",
            description: "Create a new event in the user's primary calendar.",
            inputSchema: {
                type: "object",
                properties: {
                    summary: { type: "string" },
                    startTime: { type: "string", description: "ISO date string" },
                    endTime: { type: "string", description: "ISO date string" },
                },
                required: ["summary", "startTime", "endTime"],
            },
            handler: async (input) => {
                return { content: [{ type: "text", text: `Creating event '${input.summary}' is not yet fully implemented. Needs OAuth setup.` }] };
            },
        });
    }
}

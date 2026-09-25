// sync-nudge — silent data push {"type":"sync"} to a user's other devices. See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

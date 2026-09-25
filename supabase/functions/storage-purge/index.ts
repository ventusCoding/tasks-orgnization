// storage-purge — deletes unreferenced attachment objects queued by the purge jobs. See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

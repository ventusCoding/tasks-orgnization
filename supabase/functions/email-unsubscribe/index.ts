// email-unsubscribe — signed one-click unsubscribe from digest emails. See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

// health — liveness/configuration probe. See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

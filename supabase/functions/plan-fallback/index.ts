// plan-fallback — daily server-side planning for users whose devices stopped uploading plans. See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

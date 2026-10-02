// email-events — email provider webhook (bounces, complaints). See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

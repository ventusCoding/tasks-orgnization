// push-dispatch — claims due notification jobs and delivers them (inbox + FCM). See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

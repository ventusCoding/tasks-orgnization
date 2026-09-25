// account-delete — deletes the caller's storage objects, devices, jobs and auth user. See handler.ts.
import { createHandler } from "./handler.ts";

Deno.serve(createHandler());

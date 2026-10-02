// End-to-end push pipeline (T7.4.15) against the LOCAL Supabase stack: real migrations, RPCs, guards
// and inbox convergence; only FCM is mocked (a scripted PushSender). Opt-in: run with
//   EVERSLOT_E2E=1 SUPABASE_URL=http://127.0.0.1:54321 SUPABASE_SECRET_KEY=<local secret> \
//   deno test -A push-dispatch/e2e_test.ts
// (CI exports the values from `supabase status -o env`). Every scenario uses its own fresh user.

import type { FcmMessage, FcmSendResult, PushSender } from "../_shared/fcm.ts";
import { createAdminClient } from "../_shared/supabase.ts";
import { assert, assertEquals } from "../_shared/test_utils.ts";
import { postgres } from "../_shared/test_deps.ts";
import { runDispatch } from "./dispatcher.ts";
import { createSupabaseDispatchStore } from "./store.ts";

const enabled = Deno.env.get("EVERSLOT_E2E") === "1";
const DB_URL = Deno.env.get("SUPABASE_DB_URL") ?? "postgresql://postgres:postgres@127.0.0.1:54322/postgres";

type Sql = ReturnType<typeof postgres>;

/** Scripted FCM: answers per token, records every message. */
class ScriptedSender implements PushSender {
  sent: FcmMessage[] = [];
  constructor(private readonly answers: Record<string, FcmSendResult> = {}) {}
  send(message: FcmMessage): Promise<FcmSendResult> {
    this.sent.push(message);
    return Promise.resolve(
      this.answers[message.token ?? ""] ??
        { ok: true, kind: "ok", messageId: `projects/p/messages/${this.sent.length}` },
    );
  }
  to(token: string) {
    return this.sent.filter((m) => m.token === token);
  }
}

async function createUser(sql: Sql): Promise<string> {
  const id = crypto.randomUUID();
  await sql`
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change, email_change_token_current, phone_change, phone_change_token,
      reauthentication_token, is_anonymous)
    values ('00000000-0000-0000-0000-000000000000', ${id}, 'authenticated', 'authenticated',
      ${`e2e-${id}@everslot.local`}, '', now(), '{"provider":"email","providers":["email"]}',
      '{"time_zone":"UTC","locale":"en"}', now(), now(), '', '', '', '', '', '', '', '', false)`;
  return id;
}

/** Runs `fn` inside a transaction authenticated as [userId] (auth.uid() for the RPCs). */
function asUser<T>(sql: Sql, userId: string, fn: (tx: Sql) => Promise<T>): Promise<T> {
  return sql.begin(async (tx) => {
    const claims = JSON.stringify({ sub: userId, role: "authenticated", aud: "authenticated" });
    await tx`select set_config('request.jwt.claims', ${claims}, true), set_config('role', 'authenticated', true)`;
    return await fn(tx as unknown as Sql);
  }) as Promise<T>;
}

interface DeviceSpec {
  token: string;
  lastSeenHoursAgo?: number;
  coverageHours?: number | null;
  scheduleRev?: number | null;
  platform?: "android" | "ios";
}

async function addDevice(sql: Sql, userId: string, d: DeviceSpec): Promise<string> {
  const id = crypto.randomUUID();
  await asUser(
    sql,
    userId,
    (tx) =>
      tx`select app.register_device(${id}, ${d.platform ?? "android"}, 'E2E', '15', '1.0', 1, 'en', 'UTC')`,
  );
  await sql`
    update app.devices set
      push_token = ${d.token}, push_token_updated_at = now(), push_enabled = true,
      local_notifications_enabled = true, capabilities = '{"exactAlarm": true}'::jsonb,
      last_seen_at = now() - make_interval(hours => ${d.lastSeenHoursAgo ?? 1}),
      local_coverage_until = ${
    d.coverageHours == null ? null : sql`now() + make_interval(hours => ${d.coverageHours})`
  },
      schedule_rev = ${d.scheduleRev ?? null}
    where id = ${id}`;
  return id;
}

interface JobSpec {
  key: string;
  minutesAgo?: number;
  expiresInMinutes?: number;
  guard?: Record<string, unknown>;
}

async function upload(sql: Sql, userId: string, deviceId: string, rev: number, jobs: JobSpec[]) {
  const payload = jobs.map((j) => ({
    dedupe_key: j.key,
    target_key: "task:e2e",
    fire_at: new Date(Date.now() - (j.minutesAgo ?? 1) * 60_000).toISOString(),
    expires_at: new Date(Date.now() + (j.expiresInMinutes ?? 30) * 60_000).toISOString(),
    payload: { title: `E2E ${j.key}`, body: "Body", type: "reminder", section: "planner" },
    guard: j.guard ?? { kind: "always" },
    importance: "default",
  }));
  const [row] = await asUser(
    sql,
    userId,
    (tx) =>
      tx`select app.replace_notification_jobs(${deviceId}, ${rev}, array['task:e2e'], ${
        sql.json(payload as never)
      }) as r`,
  );
  return row.r as { status: string };
}

async function dispatch(sender: PushSender) {
  const client = createAdminClient()!;
  return await runDispatch({ store: createSupabaseDispatchStore(client), sender, budgetMs: 20_000 });
}

const jobOf = async (sql: Sql, userId: string, key: string) =>
  (await sql`select * from private.notification_jobs where user_id = ${userId} and dedupe_key = ${key}`)[0];

const deliveriesOf = async (sql: Sql, jobId: string) =>
  await sql`select device_id, outcome, error_code from private.push_deliveries where job_id = ${jobId}`;

Deno.test({
  name: "E2E push pipeline against local Supabase (T7.4.15)",
  ignore: !enabled,
  sanitizeResources: false,
  sanitizeOps: false,
  async fn(t) {
    const sql = postgres(DB_URL, { max: 4, onnotice: () => {} });
    const users: string[] = [];
    const user = async () => {
      const u = await createUser(sql);
      users.push(u);
      return u;
    };
    try {
      // -- Scenario setup (all uploaded first, then one dispatcher run handles every due job). ----------
      const covered = await user();
      const coveredDev = await addDevice(sql, covered, {
        token: "tok-covered",
        coverageHours: 24,
        scheduleRev: 50,
      });
      assertEquals((await upload(sql, covered, coveredDev, 50, [{ key: "k-covered" }])).status, "ok");

      const stale = await user();
      const staleDev = await addDevice(sql, stale, {
        token: "tok-stale",
        coverageHours: 24,
        scheduleRev: 50,
        lastSeenHoursAgo: 96,
      });
      await upload(sql, stale, staleDev, 50, [{ key: "k-stale" }]);

      const olderRev = await user();
      const olderDev = await addDevice(sql, olderRev, {
        token: "tok-older",
        coverageHours: 24,
        scheduleRev: 10,
      });
      await upload(sql, olderRev, olderDev, 50, [{ key: "k-older" }]);

      const guarded = await user();
      const guardedDev = await addDevice(sql, guarded, { token: "tok-guard" });
      // A nag whose base reminder was acknowledged on another device (inbox acted).
      await sql`insert into app.notifications (id, user_id, dedupe_key, category, fire_at, title, acted_at, created_at, updated_at)
                values (app.uuid_v5('base-acted'), ${guarded}, 'base-acted', 'reminder', now(), 'x', now(), now(), now())`;
      await upload(sql, guarded, guardedDev, 50, [
        { key: "k-nag", guard: { kind: "inbox_not_acted", dedupeKey: "base-acted" } },
      ]);

      const expired = await user();
      const expiredDev = await addDevice(sql, expired, { token: "tok-expired" });
      await upload(sql, expired, expiredDev, 50, [{
        key: "k-expired",
        minutesAgo: 60,
        expiresInMinutes: -5,
      }]);

      const unregistered = await user();
      const unregDev = await addDevice(sql, unregistered, { token: "tok-unregistered" });
      await upload(sql, unregistered, unregDev, 50, [{ key: "k-unreg" }]);

      const quota = await user();
      const quotaDev = await addDevice(sql, quota, { token: "tok-quota" });
      await upload(sql, quota, quotaDev, 50, [{ key: "k-quota" }]);

      const primary = await user();
      const phone = await addDevice(sql, primary, { token: "tok-phone" });
      const tablet = await addDevice(sql, primary, { token: "tok-tablet" });
      await sql`insert into app.user_settings (id, user_id, namespace, value, created_at, updated_at)
                values (gen_random_uuid(), ${primary}, 'notifications',
                        ${sql.json({ multiDevicePolicy: "primary", primaryDeviceId: phone })}, now(), now())`;
      await upload(sql, primary, phone, 50, [{ key: "k-primary" }]);

      const converge = await user();
      const convergeDev = await addDevice(sql, converge, { token: "tok-converge" });
      // The device already wrote the inbox row locally (and the user read it) before the server run.
      await sql`insert into app.notifications (id, user_id, dedupe_key, category, fire_at, title, read_at, created_at, updated_at)
                values (app.uuid_v5('k-converge'), ${converge}, 'k-converge', 'reminder', now(), 'local', now(), now(), now())`;
      await upload(sql, converge, convergeDev, 50, [{ key: "k-converge" }]);

      const sender = new ScriptedSender({
        "tok-unregistered": { ok: false, kind: "unregistered", tokenInvalid: true, retryable: false },
        "tok-quota": {
          ok: false,
          kind: "quota_exceeded",
          tokenInvalid: false,
          retryable: true,
          retryAfterSeconds: 120,
        },
      });
      const summary = await dispatch(sender);
      assert(summary.claimed >= 9, `claimed ${summary.claimed}`);

      await t.step("a device covering the instance locally gets no push", async () => {
        assertEquals(sender.to("tok-covered").length, 0);
        const job = await jobOf(sql, covered, "k-covered");
        assertEquals(job.status, "skipped");
        assertEquals((await deliveriesOf(sql, job.id))[0].outcome, "skipped_local");
      });

      await t.step("a device not seen for > 72 h is pushed despite its coverage", async () => {
        assertEquals(sender.to("tok-stale").length, 1);
        assertEquals((await jobOf(sql, stale, "k-stale")).status, "sent");
      });

      await t.step("a device whose schedule predates the plan (older schedule_rev) is pushed", () => {
        assertEquals(sender.to("tok-older").length, 1);
      });

      await t.step("a false guard (nag acknowledged elsewhere) skips the push", async () => {
        assertEquals(sender.to("tok-guard").length, 0);
        const job = await jobOf(sql, guarded, "k-nag");
        assertEquals(job.status, "skipped");
        assertEquals((await deliveriesOf(sql, job.id)).length, 0);
      });

      await t.step("an expired job is dropped", async () => {
        assertEquals(sender.to("tok-expired").length, 0);
        assertEquals((await jobOf(sql, expired, "k-expired")).status, "expired");
      });

      await t.step("UNREGISTERED nulls the device token", async () => {
        const [d] = await sql`select push_token from app.devices where id = ${unregDev}`;
        assertEquals(d.push_token, null);
      });

      await t.step("QUOTA_EXCEEDED is retried after Retry-After", async () => {
        const job = await jobOf(sql, quota, "k-quota");
        assertEquals(job.status, "pending");
        const wait = (Date.parse(job.next_retry_at) - Date.now()) / 1000;
        assert(wait >= 100 && wait <= 130, `retry in ${wait}s`);
      });

      await t.step("primary-only policy pushes the phone, never the tablet", async () => {
        assertEquals(sender.to("tok-phone").length, 1);
        assertEquals(sender.to("tok-tablet").length, 0);
        const job = await jobOf(sql, primary, "k-primary");
        const tabletDelivery = (await deliveriesOf(sql, job.id)).find((d) => d.device_id === tablet);
        assertEquals(tabletDelivery?.outcome, "skipped_policy");
      });

      await t.step("a stale source_rev upload is rejected", async () => {
        assertEquals(
          (await upload(sql, covered, coveredDev, 60, [{ key: "k-future", minutesAgo: -60 }])).status,
          "ok",
        );
        const older = await upload(sql, covered, coveredDev, 55, [{
          key: "k-future-older",
          minutesAgo: -60,
        }]);
        assertEquals(older.status, "stale");
        assertEquals((await jobOf(sql, covered, "k-future")).source_rev, "60");
      });

      await t.step(
        "the inbox keeps one row and the user's read state after local + server writes",
        async () => {
          const rows = await sql`select read_at, delivered_via from app.notifications
                               where user_id = ${converge} and dedupe_key = 'k-converge'`;
          assertEquals(rows.length, 1);
          assert(rows[0].read_at !== null, "read state kept");
        },
      );

      await t.step("a second run delivers nothing twice", async () => {
        const again = new ScriptedSender();
        await dispatch(again);
        for (const tok of ["tok-stale", "tok-older", "tok-phone"]) assertEquals(again.to(tok).length, 0);
      });
    } finally {
      for (const u of users) await sql`delete from auth.users where id = ${u}`;
      await sql.end();
    }
  },
});

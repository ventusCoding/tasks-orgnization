import { assertEquals } from "../_shared/test_utils.ts";
import { purgeStorage, type StorageDeletion, type StoragePurgePorts } from "./handler.ts";

Deno.test("purgeStorage removes queued objects per bucket and reports failures", async () => {
  const queue: StorageDeletion[] = [
    { id: 1, bucket: "attachments", path: "u/a/1.jpg" },
    { id: 2, bucket: "attachments", path: "u/a/2.jpg" },
    { id: 3, bucket: "legacy", path: "u/b/3.jpg" },
  ];
  const removed: string[] = [];
  const done: Array<{ ids: number[]; errors: Record<string, string> }> = [];
  const ports: StoragePurgePorts = {
    claim: () => Promise.resolve(queue.splice(0, queue.length)),
    remove: (bucket, paths) => {
      if (bucket === "legacy") return Promise.reject(new Error("bucket not found"));
      removed.push(...paths);
      return Promise.resolve();
    },
    done: (ids, errors) => {
      done.push({ ids, errors });
      return Promise.resolve();
    },
  };
  const summary = await purgeStorage(ports);
  assertEquals(summary, { removed: 2, failed: 1 });
  assertEquals(removed, ["u/a/1.jpg", "u/a/2.jpg"]);
  assertEquals(done, [{ ids: [1, 2, 3], errors: { "3": "bucket not found" } }]);
});

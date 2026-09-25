// Account deletion (T1.5.12): storage objects → devices/jobs → auth user (cascades every app row).
// Idempotent: a second run finds no objects and an already-deleted user.

export interface AccountDeletionPorts {
  /** Every object path under `<prefix>/` in the attachments bucket (recursive). */
  listObjects(prefix: string): Promise<string[]>;
  removeObjects(paths: string[]): Promise<void>;
  /** Deletes devices and notification jobs (app.account_delete_prepare). */
  prepare(userId: string): Promise<void>;
  deleteUser(userId: string): Promise<"deleted" | "not_found">;
  /** Revokes Sign in with Apple tokens when linked (needs the Apple client secret). */
  revokeAppleTokens?(userId: string): Promise<"revoked" | "not_linked" | "not_configured">;
}

export interface AccountDeletionResult {
  userId: string;
  objectsDeleted: number;
  userDeleted: boolean;
  alreadyDeleted: boolean;
  apple: "revoked" | "not_linked" | "not_configured";
}

export const REMOVE_BATCH = 100;

export async function deleteAccount(
  ports: AccountDeletionPorts,
  userId: string,
): Promise<AccountDeletionResult> {
  const paths = await ports.listObjects(userId);
  for (let i = 0; i < paths.length; i += REMOVE_BATCH) {
    await ports.removeObjects(paths.slice(i, i + REMOVE_BATCH));
  }
  const apple = ports.revokeAppleTokens ? await ports.revokeAppleTokens(userId) : "not_configured";
  await ports.prepare(userId);
  const outcome = await ports.deleteUser(userId);
  return {
    userId,
    objectsDeleted: paths.length,
    userDeleted: outcome === "deleted",
    alreadyDeleted: outcome === "not_found",
    apple,
  };
}

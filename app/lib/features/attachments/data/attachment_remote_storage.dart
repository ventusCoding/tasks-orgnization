import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:everslot/core/errors/app_exception.dart' show NetworkException;
import 'package:everslot/features/attachments/domain/attachment_limits.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tusc/tusc.dart';

/// Progress callback `(sentBytes, totalBytes)`.
typedef TransferProgress = void Function(int sent, int total);

/// Binary storage for attachments (arch §6.7). Separate from row sync: only the upload queue and
/// the downloader talk to it. `null` in local-only mode (Supabase not configured).
abstract class AttachmentRemoteStorage {
  /// Uploads [file] to `bucket/path`. Retries of the same path overwrite (no duplicates).
  ///
  /// Files larger than [AttachmentLimits.resumableThreshold] use resumable (TUS) uploads;
  /// [resumeUrl] continues a previous one and [onResumeUrl] reports the URL to persist.
  Future<void> upload({
    required String bucket,
    required String path,
    required File file,
    required String mimeType,
    TransferProgress? onProgress,
    String? resumeUrl,
    void Function(String url)? onResumeUrl,
  });

  /// Downloads `bucket/path`.
  Future<Uint8List> download({required String bucket, required String path});
}

/// Supabase Storage implementation (standard uploads + TUS via `tusc` for large files).
class SupabaseAttachmentStorage implements AttachmentRemoteStorage {
  SupabaseAttachmentStorage(this._client, {required this.supabaseUrl});

  final SupabaseClient _client;
  final String supabaseUrl;

  /// `https://<ref>.supabase.co` → `https://<ref>.storage.supabase.co/storage/v1/upload/resumable`
  /// (direct storage host, arch §6.7); local stacks keep their host.
  static String resumableEndpoint(String supabaseUrl) {
    final uri = Uri.parse(supabaseUrl);
    final host = uri.host;
    if (host.endsWith('.supabase.co') && !host.contains('.storage.')) {
      final ref = host.split('.').first;
      return 'https://$ref.storage.supabase.co/storage/v1/upload/resumable';
    }
    final base = supabaseUrl.endsWith('/') ? supabaseUrl.substring(0, supabaseUrl.length - 1) : supabaseUrl;
    return '$base/storage/v1/upload/resumable';
  }

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required File file,
    required String mimeType,
    TransferProgress? onProgress,
    String? resumeUrl,
    void Function(String url)? onResumeUrl,
  }) async {
    final size = await file.length();
    if (size <= AttachmentLimits.resumableThreshold) {
      onProgress?.call(0, size);
      try {
        await _client.storage
            .from(bucket)
            .upload(path, file, fileOptions: FileOptions(contentType: mimeType, upsert: true));
      } on StorageException catch (e) {
        throw NetworkException('upload failed: ${e.message}', cause: e);
      }
      onProgress?.call(size, size);
      return;
    }
    await _uploadResumable(
      bucket: bucket,
      path: path,
      file: file,
      mimeType: mimeType,
      onProgress: onProgress,
      resumeUrl: resumeUrl,
      onResumeUrl: onResumeUrl,
    );
  }

  Future<void> _uploadResumable({
    required String bucket,
    required String path,
    required File file,
    required String mimeType,
    TransferProgress? onProgress,
    String? resumeUrl,
    void Function(String url)? onResumeUrl,
  }) async {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) throw const NetworkException('not signed in');
    final headers = <String, String>{'authorization': 'Bearer $token', 'x-upsert': 'true'};
    TusClient build({String? uploadUrl}) => TusClient(
      file: XFile(file.path),
      url: uploadUrl == null ? resumableEndpoint(supabaseUrl) : null,
      uploadUrl: uploadUrl,
      chunkSize: AttachmentLimits.tusChunkSize,
      headers: headers,
      metadata: {'bucketName': bucket, 'objectName': path, 'contentType': mimeType, 'cacheControl': '3600'},
    );
    final client = build(uploadUrl: resumeUrl);
    final done = Completer<void>();
    var reportedUrl = false;
    await client.startUpload(
      onProgress: (count, total, _) {
        if (!reportedUrl && client.uploadUrl.isNotEmpty) {
          reportedUrl = true;
          onResumeUrl?.call(client.uploadUrl);
        }
        onProgress?.call(count, total);
      },
      onComplete: (_) {
        if (!done.isCompleted) done.complete();
      },
      onError: (error) {
        if (!done.isCompleted) done.completeError(NetworkException('tus: ${error.message}', cause: error));
      },
      onTimeout: () {
        if (!done.isCompleted) done.completeError(const NetworkException('tus timeout'));
      },
    );
    if (!done.isCompleted) done.complete();
    await done.future;
  }

  @override
  Future<Uint8List> download({required String bucket, required String path}) async {
    try {
      return await _client.storage.from(bucket).download(path);
    } on StorageException catch (e) {
      throw NetworkException('download failed: ${e.message}', cause: e);
    }
  }
}

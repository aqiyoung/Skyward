import 'package:skyward/common/common.dart';
import 'package:flutter/services.dart';

/// One poll of the system download manager for a download it owns.
class DownloadStatus {
  const DownloadStatus({
    required this.state,
    required this.downloadedBytes,
    required this.totalBytes,
  });

  /// 'running', 'successful', 'failed', 'paused', 'pending', or 'unknown'.
  final String state;

  final int downloadedBytes;

  /// -1 when the download manager does not know the total yet.
  final int totalBytes;

  bool get isSuccessful => state == 'successful';

  bool get isFailed => state == 'failed';

  /// Null while the total is unknown, so the progress bar stays indeterminate.
  double? get progress {
    if (totalBytes <= 0) {
      return null;
    }
    return (downloadedBytes / totalBytes).clamp(0, 1).toDouble();
  }

  static DownloadStatus fromMap(Map<dynamic, dynamic> map) {
    final state = map['status'];
    final downloaded = map['downloadedBytes'];
    final total = map['totalBytes'];
    return DownloadStatus(
      state: state is String ? state : 'unknown',
      downloadedBytes: downloaded is int ? downloaded : 0,
      totalBytes: total is int ? total : -1,
    );
  }
}

/// The system download manager: the file lands in the device's Downloads
/// folder and the system shows its own progress and a retry. The app polls
/// this manager, so its own progress dialog stays the visible one and the
/// system notification is only a fallback.
class SystemDownloader {
  SystemDownloader._();

  static final instance = SystemDownloader._();

  static const _methodChannel = MethodChannel('$packageName/download');

  /// The ABI the device runs, which names the package that fits it.
  Future<String?> supportedAbi() {
    return _methodChannel.invokeMethod<String>('supportedAbi');
  }

  /// Hands the file to the system download manager and returns its id.
  /// When [expectedSha256] is given, the native side verifies the
  /// downloaded file against it before opening the installer, and refuses
  /// to install on mismatch.
  Future<int?> download({
    required String url,
    required String fileName,
    String? expectedSha256,
  }) {
    return _methodChannel.invokeMethod<int>('download', {
      'url': url,
      'fileName': fileName,
      if (expectedSha256 != null) 'expectedSha256': expectedSha256,
    });
  }

  /// The current state of a download started with [download].
  Future<DownloadStatus?> status(int downloadId) async {
    final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'status',
      {'downloadId': downloadId},
    );
    if (result == null) {
      return null;
    }
    return DownloadStatus.fromMap(result);
  }

  /// Cancels a download started with [download].
  Future<bool?> cancel(int downloadId) {
    return _methodChannel.invokeMethod<bool>('cancel', {
      'downloadId': downloadId,
    });
  }

  /// Opens the system installer for a finished download. This is a no-op
  /// when the download-complete receiver already opened it, so polling code
  /// can call it as a backup without opening the installer twice.
  Future<bool?> install(int downloadId) {
    return _methodChannel.invokeMethod<bool>('install', {
      'downloadId': downloadId,
    });
  }
}

final systemDownloader = system.isAndroid ? SystemDownloader.instance : null;

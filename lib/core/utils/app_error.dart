import 'package:dio/dio.dart';

class AppError {
  static String message(Object e) {
    if (e is! DioException) return e.toString();

    final data = e.response?.data;
    if (data is Map) {
      // 1) Prefer field errors FIRST (claim-form, etc.)
      final errs = data['errors'];
      if (errs is Map && errs.isNotEmpty) {
        final msgs = <String>[];
        for (final entry in errs.entries) {
          final val = entry.value;
          if (val is List && val.isNotEmpty) {
            // take all lines to be explicit (e.g., type + allowed types)
            msgs.addAll(val.map((v) => v.toString()));
          } else if (val is String && val.isNotEmpty) {
            msgs.add(val);
          }
        }
        if (msgs.isNotEmpty) return msgs.join('\n');
      }

      // 2) Fall back to top-level message IF present
      final msg = data['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) return msg;
    }

    // 3) Then any plain string set on the DioException
    final err = e.error;
    if (err is String && err.trim().isNotEmpty) return err;

    return 'Something went wrong';
  }
}
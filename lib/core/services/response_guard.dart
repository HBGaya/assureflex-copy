class ResponseGuard {
  /// Returns `data` when status==true, otherwise throws an Exception with message/errors.
  static dynamic unwrap(Map<String, dynamic> body) {
    final status = body['status'] == true;
    if (!status) {
      final msg = body['message']?.toString() ?? 'Request failed';
      // If there are validation errors, append the first one
      final errs = body['errors'];
      if (errs is Map && errs.isNotEmpty) {
        final firstKey = errs.keys.first;
        final firstVal = errs[firstKey];
        final firstErr = (firstVal is List && firstVal.isNotEmpty)
            ? firstVal.first.toString()
            : firstVal?.toString();
        throw Exception(firstErr ?? msg);
      }
      throw Exception(msg);
    }
    return body['data'];
  }
}
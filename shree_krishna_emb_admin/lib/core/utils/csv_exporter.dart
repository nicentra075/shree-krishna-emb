import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Lightweight CSV builder + browser download helper.
///
/// No heavy `csv` dependency — we RFC-4180 quote fields ourselves and trigger
/// a browser download via an anchor + data URL (web only). On non-web or if the
/// download fails, the caller can fall back to [CsvExporter.copyToClipboard].
class CsvExporter {
  CsvExporter._();

  /// Escapes a single CSV cell: wraps in quotes when it contains a comma,
  /// quote or newline, doubling embedded quotes.
  static String escapeCell(Object? value) {
    final s = value?.toString() ?? '';
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Builds a CSV string from a header row + data rows.
  static String build(List<String> header, List<List<Object?>> rows) {
    final buffer = StringBuffer();
    buffer.writeln(header.map(escapeCell).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(escapeCell).join(','));
    }
    return buffer.toString();
  }

  /// Triggers a browser download of [csv] as [filename] (web only).
  /// Returns true if the download was started.
  static bool download(String csv, String filename) {
    if (!kIsWeb) return false;
    try {
      final bytes = utf8.encode(csv);
      final base64Data = base64Encode(bytes);
      final dataUrl = 'data:text/csv;charset=utf-8;base64,$base64Data';
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = dataUrl
        ..download = filename
        ..style.display = 'none';
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clipboard fallback when a download isn't possible.
  static Future<void> copyToClipboard(String csv) {
    return Clipboard.setData(ClipboardData(text: csv));
  }
}

import 'package:intl/intl.dart';

/// Display formatting utilities for numbers, dates, and currency
class AppFormatters {
  AppFormatters._();

  /// Formats amount as Indian Rupees currency (₹)
  static String currency(double amount) {
    return '₹${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        )}';
  }

  /// Formats date as "15 Apr 2024"
  static String date(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  /// Formats datetime as "15 Apr 2024, 2:30 PM"
  static String dateTime(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  /// Formats time as "2:30 PM"
  static String time(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Formats relative time ("3 days ago", "Just now")
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return AppFormatters.date(date);
    }
  }

  /// Formats file size (bytes) as human-readable (1.2 MB)
  static String fileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int suffixIndex = 0;

    while (size > 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  /// Formats order status for display
  static String orderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// Formats phone number to readable format (123-456-7890)
  static String phone(String number) {
    final cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10) return number;
    return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
  }

  /// Capitalize first letter of each word
  static String capitalize(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int length) {
    if (text.length <= length) return text;
    return '${text.substring(0, length)}...';
  }
}

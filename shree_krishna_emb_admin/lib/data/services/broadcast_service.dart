import 'package:cloud_functions/cloud_functions.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show CloudFunctionNames;

/// Sends an ad-hoc announcement to every user via the `broadcastNotification`
/// admin-only callable Cloud Function. The function fans the message out as
/// an FCM topic push and writes an inbox entry for every user, returning the
/// number of users it reached.
abstract class BroadcastService {
  Future<int> send(String title, String body);
}

class FunctionsBroadcastService implements BroadcastService {
  final FirebaseFunctions _functions;

  FunctionsBroadcastService({required FirebaseFunctions functions})
    : _functions = functions;

  @override
  Future<int> send(String title, String body) async {
    final callable = _functions.httpsCallable(
      CloudFunctionNames.broadcastNotification,
    );
    final res = await callable.call<Map<String, dynamic>>({
      'title': title,
      'body': body,
    });
    return (res.data['recipientCount'] as num?)?.toInt() ?? 0;
  }
}

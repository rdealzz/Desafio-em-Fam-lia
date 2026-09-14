import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversões defensivas entre os tipos dinâmicos do Firestore e o Dart.
///
/// Documentos antigos, campos ausentes ou `FieldValue.serverTimestamp()` ainda
/// não resolvido não podem derrubar a tela — por isso tudo tem fallback.
class FirestoreUtils {
  const FirestoreUtils._();

  static DateTime? toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static DateTime toDateTimeOrNow(dynamic value) =>
      toDateTime(value) ?? DateTime.now();

  static int toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String toStringValue(dynamic value, {String fallback = ''}) {
    if (value is String) return value;
    return value?.toString() ?? fallback;
  }

  static List<String> toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const <String>[];
  }

  static Map<String, dynamic> toMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}

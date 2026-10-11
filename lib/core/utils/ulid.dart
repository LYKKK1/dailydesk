import 'package:ulid/ulid.dart';

String newUlid() => Ulid().toString();

int nowMs() => DateTime.now().toUtc().millisecondsSinceEpoch;

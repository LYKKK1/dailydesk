import 'dart:convert';
import 'dart:io';

import 'package:dailydesk/core/network/http_client_factory.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class DeconTodo {
  DeconTodo(this.title, this.priority, this.estimatedPomodoros, this.dueTime);

  final String title;
  final int priority;
  final int estimatedPomodoros;
  final String? dueTime;
}

class DeconSop {
  DeconSop(this.title, this.time);

  final String title;
  final String time;
}

class DeconMemo {
  DeconMemo(this.content, this.tag);

  final String content;
  final String? tag;
}

class Deconstruction {
  Deconstruction(this.analysis, this.todos, this.sops, this.memos);

  final String analysis;
  final List<DeconTodo> todos;
  final List<DeconSop> sops;
  final List<DeconMemo> memos;
}

Deconstruction parseDeconstruction(String json) {
  dynamic decoded;
  try {
    decoded = jsonDecode(_stripCodeFence(json));
  } catch (_) {
    return _emptyDeconstruction();
  }

  if (decoded is! Map) return _emptyDeconstruction();

  return Deconstruction(
    _stringValue(decoded['analysis']),
    _mapItems(decoded['todos'])
        .map(
          (item) => DeconTodo(
            _stringValue(item['title']),
            _clampInt(item['priority'], 0, 3, 1),
            _clampInt(item['estimated_pomodoros'], 1, 3, 1),
            _nullableString(item['due_time']),
          ),
        )
        .toList(growable: false),
    _mapItems(decoded['sops'])
        .map(
          (item) => DeconSop(
            _stringValue(item['title']),
            _nullableString(item['time']) ?? '09:00',
          ),
        )
        .toList(growable: false),
    _mapItems(decoded['memos'])
        .map(
          (item) => DeconMemo(
            _stringValue(item['content']),
            _nullableString(item['tag']),
          ),
        )
        .toList(growable: false),
  );
}

class AiService {
  static const systemPrompt = '''
你是 GTD 拆解助手。将用户口语化思路按以下 JSON Schema 输出（仅输出 JSON）：
{
  "analysis": "一句话总结",
  "todos": [{"title": str, "priority": 0-3, "estimated_pomodoros": 1-3, "due_time": "HH:mm" | null}],
  "sops": [{"title": str, "time": "HH:mm"}],
  "memos": [{"content": str, "tag": "arch"|"ui"|"idea"|"work"|"flash"}]
}
''';

  static Future<List<String>> fetchModels({
    required String baseUrl,
    required String apiKey,
    String? proxy,
    http.Client? client,
  }) async {
    final requestClient = _requestClient(proxy: proxy, injected: client);
    try {
      final response = await requestClient.get(
        _endpoint(baseUrl, 'models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw HttpException('models 拉取失败: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! List) return const [];

      return (decoded['data'] as List)
          .whereType<Map>()
          .map((item) => _nullableString(item['id']))
          .whereType<String>()
          .toList(growable: false);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static Future<Deconstruction> deconstructIdea({
    required String idea,
    required String baseUrl,
    required String apiKey,
    required String model,
    String? proxy,
    http.Client? client,
  }) async {
    final requestClient = _requestClient(proxy: proxy, injected: client);
    try {
      final response = await requestClient
          .post(
            _endpoint(baseUrl, 'chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': idea},
              ],
              'temperature': 0,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw HttpException(
          '拆解失败: ${response.statusCode} ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map ||
          decoded['choices'] is! List ||
          (decoded['choices'] as List).isEmpty) {
        throw const FormatException('模型响应缺少 choices');
      }
      final firstChoice = (decoded['choices'] as List).first;
      if (firstChoice is! Map || firstChoice['message'] is! Map) {
        throw const FormatException('模型响应缺少 message');
      }
      final content = (firstChoice['message'] as Map)['content'];
      if (content is! String) {
        throw const FormatException('模型响应缺少文本 content');
      }

      return parseDeconstruction(content);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static http.Client _requestClient({
    required String? proxy,
    required http.Client? injected,
  }) =>
      injected ?? IOClient(HttpClientFactory.create(proxyUrl: proxy));

  static Uri _endpoint(String baseUrl, String path) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', '不能为空');
    }
    return Uri.parse('$normalized/$path');
  }
}

Deconstruction _emptyDeconstruction() =>
    Deconstruction('', const [], const [], const []);

Iterable<Map> _mapItems(dynamic raw) =>
    raw is List ? raw.whereType<Map>() : const <Map>[];

String _stringValue(dynamic value) => value is String ? value.trim() : '';

String? _nullableString(dynamic value) {
  final parsed = _stringValue(value);
  return parsed.isEmpty ? null : parsed;
}

int _clampInt(dynamic value, int min, int max, int fallback) {
  final parsed = value is num ? value.toInt() : fallback;
  return parsed.clamp(min, max);
}

String _stripCodeFence(String value) {
  final trimmed = value.trim();
  if (!trimmed.startsWith('```')) return trimmed;

  final firstLineEnd = trimmed.indexOf('\n');
  if (firstLineEnd == -1) return trimmed;

  var content = trimmed.substring(firstLineEnd + 1);
  final closingFence = content.lastIndexOf('```');
  if (closingFence != -1) {
    content = content.substring(0, closingFence);
  }
  return content.trim();
}

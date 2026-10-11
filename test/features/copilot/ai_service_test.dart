import 'dart:convert';

import 'package:dailydesk/core/network/http_client_factory.dart';
import 'package:dailydesk/features/copilot/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _sampleJson = '''
{
  "analysis": "发版前夕的核心攻坚与健康作息建议",
  "todos": [
    {"title": "编译双端安装包并冒烟测试", "priority": 0, "estimated_pomodoros": 3, "due_time": "14:00"},
    {"title": "编写发版日志", "priority": 1, "estimated_pomodoros": 1, "due_time": "16:00"}
  ],
  "sops": [
    {"title": "☕ 午后站立拉伸与饮水 300ml", "time": "16:00"}
  ],
  "memos": [
    {"content": "检查多网卡环境 mDNS 广播绑定", "tag": "arch"}
  ]
}
''';

void main() {
  test('解析结构化拆解 JSON（spec 5.11-3 Schema）', () {
    final result = parseDeconstruction(_sampleJson);

    expect(result.analysis, contains('发版'));
    expect(result.todos.length, 2);
    expect(result.todos.first.priority, 0);
    expect(result.todos.first.estimatedPomodoros, 3);
    expect(result.todos.first.dueTime, '14:00');
    expect(result.sops.single.time, '16:00');
    expect(result.memos.single.tag, 'arch');
  });

  test('空字段容错：缺数组不抛异常', () {
    final result = parseDeconstruction('{"analysis": "x"}');

    expect(result.todos, isEmpty);
    expect(result.sops, isEmpty);
    expect(result.memos, isEmpty);
  });

  test('非法 JSON 返回空拆解而不抛异常', () {
    final result = parseDeconstruction('not json');

    expect(result.analysis, isEmpty);
    expect(result.todos, isEmpty);
    expect(result.sops, isEmpty);
    expect(result.memos, isEmpty);
  });

  test('代理默认值与显式直连', () {
    expect(HttpClientFactory.defaultProxy, 'http://127.0.0.1:7890');
    expect(
      HttpClientFactory.proxyDirective(proxyUrl: null),
      'PROXY 127.0.0.1:7890',
    );
    expect(HttpClientFactory.proxyDirective(proxyUrl: ''), 'DIRECT');

    final proxied = HttpClientFactory.create();
    proxied.close();

    final direct = HttpClientFactory.create(proxyUrl: '');
    expect(direct.autoUncompress, isTrue);
    direct.close();
  });

  test('fetchModels 使用注入客户端并解析 data id', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'data': [
            {'id': 'deepseek-chat'},
            {'id': 'deepseek-reasoner'},
          ],
        }),
        200,
      );
    });

    final models = await AiService.fetchModels(
      baseUrl: 'https://api.example.com/v1/',
      apiKey: 'secret',
      client: client,
    );

    expect(models, ['deepseek-chat', 'deepseek-reasoner']);
    expect(captured.method, 'GET');
    expect(captured.url.toString(), 'https://api.example.com/v1/models');
    expect(captured.headers['Authorization'], 'Bearer secret');
  });

  test('deconstructIdea 使用注入客户端解析 choices content', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': _sampleJson},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final result = await AiService.deconstructIdea(
      idea: '明天发版，下午记得拉伸',
      baseUrl: 'https://api.example.com/v1',
      apiKey: 'secret',
      model: 'test-model',
      client: client,
    );

    expect(result.todos.length, 2);
    expect(captured.method, 'POST');
    expect(
        captured.url.toString(), 'https://api.example.com/v1/chat/completions');
    expect(captured.headers['Authorization'], 'Bearer secret');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], 'test-model');
    expect(body['response_format'], {'type': 'json_object'});
  });
}

import 'dart:io';

class HttpClientFactory {
  static const defaultProxy = 'http://127.0.0.1:7890';

  static String proxyDirective({String? proxyUrl}) {
    final raw = (proxyUrl ?? defaultProxy).trim();
    if (raw.isEmpty) return 'DIRECT';

    final uri = Uri.tryParse(raw);
    if (uri != null && uri.host.isNotEmpty) {
      final port = uri.hasPort ? uri.port : _defaultPort(uri.scheme);
      return 'PROXY ${uri.host}:$port';
    }

    return 'PROXY $raw';
  }

  static HttpClient create({String? proxyUrl}) {
    final client = HttpClient();
    final directive = proxyDirective(proxyUrl: proxyUrl);
    client.findProxy = (_) => directive;

    if (directive != 'DIRECT') {
      client.badCertificateCallback = (cert, host, port) => host == '127.0.0.1';
    }
    return client;
  }

  static int _defaultPort(String scheme) => scheme == 'https' ? 443 : 80;
}

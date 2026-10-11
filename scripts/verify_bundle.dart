import 'dart:io';

const int _maxApkBytes = 25 * 1024 * 1024;
const int _maxWindowsZipBytes = 40 * 1024 * 1024;

const Set<String> _allowedProviderHosts = {
  'api.openai.com',
  'api.deepseek.com',
  'api.groq.com',
  'api.moonshot.cn',
};

void main(List<String> arguments) {
  final options = _VerifyOptions.parse(arguments);
  if (options.help) {
    _printUsage();
    return;
  }

  var passed = true;

  if (!options.skipSize) {
    passed &= _verifySizes(options);
  } else {
    stdout.writeln('SKIP: bundle size checks');
  }

  if (!options.skipUrlWhitelist) {
    passed &= _verifyUrlWhitelist(options.root);
  } else {
    stdout.writeln('SKIP: URL whitelist check');
  }

  if (!options.skipVersion) {
    passed &= _verifyVersion(options);
  } else {
    stdout.writeln('SKIP: version consistency check');
  }

  if (!passed) {
    exitCode = 1;
  }
}

bool _verifySizes(_VerifyOptions options) {
  var passed = true;

  final apkFiles = <File>[
    ...options.apkFiles.map((path) => _resolveFile(options.root, path)),
    if (options.apkFiles.isEmpty)
      ..._discoverFiles(
        '${options.root}${Platform.pathSeparator}build'
        '${Platform.pathSeparator}app${Platform.pathSeparator}outputs'
        '${Platform.pathSeparator}flutter-apk',
        (path) => path.toLowerCase().endsWith('-release.apk'),
      ),
  ];
  final windowsZips = <File>[
    ...options.windowsZipFiles.map((path) => _resolveFile(options.root, path)),
    if (options.windowsZipFiles.isEmpty)
      ...[
        ..._discoverFiles(
          '${options.root}${Platform.pathSeparator}artifacts',
          (path) =>
              path.toLowerCase().endsWith('-win-x64.zip') &&
              path.toLowerCase().contains('dailydesk'),
        ),
        ..._discoverFiles(
          '${options.root}${Platform.pathSeparator}build'
          '${Platform.pathSeparator}windows',
          (path) =>
              path.toLowerCase().endsWith('-win-x64.zip') &&
              path.toLowerCase().contains('dailydesk'),
        ),
      ],
  ];

  if (apkFiles.isEmpty) {
    stdout.writeln(
      'FAIL: no release APK found; pass --apk PATH or build the APKs first',
    );
    passed = false;
  }
  for (final apk in apkFiles) {
    passed &= _verifyFileSize(apk, _maxApkBytes, 'APK');
  }

  if (windowsZips.isEmpty) {
    stdout.writeln(
      'FAIL: no Windows portable zip found; pass --windows-zip PATH',
    );
    passed = false;
  }
  for (final zip in windowsZips) {
    passed &= _verifyFileSize(zip, _maxWindowsZipBytes, 'Windows zip');
  }

  return passed;
}

bool _verifyFileSize(File file, int maximumBytes, String label) {
  if (!file.existsSync()) {
    stdout.writeln('FAIL: $label does not exist: ${file.path}');
    return false;
  }

  final bytes = file.lengthSync();
  final size = _formatMiB(bytes);
  final limit = _formatMiB(maximumBytes);
  if (bytes > maximumBytes) {
    stdout.writeln(
      'FAIL: $label $size exceeds $limit limit: ${file.path}',
    );
    return false;
  }

  stdout.writeln('OK: $label size $size <= $limit: ${file.path}');
  return true;
}

bool _verifyUrlWhitelist(String root) {
  final libDirectory = Directory('$root${Platform.pathSeparator}lib');
  if (!libDirectory.existsSync()) {
    stdout.writeln('FAIL: lib directory not found under $root');
    return false;
  }

  final violations = <String>[];
  var literals = 0;
  final urlPattern = RegExp(r'''https?://[^\s'"`<>]+''');

  for (final entity in libDirectory.listSync(recursive: true)) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.dart')) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      for (final match in urlPattern.allMatches(lines[index])) {
        literals++;
        final literal = _trimUrl(match.group(0)!);
        final uri = Uri.tryParse(literal);
        if (uri == null || !_isAllowedUrl(uri)) {
          violations.add('${entity.path}:${index + 1}: $literal');
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('OK: URL whitelist ($literals literals checked)');
    return true;
  }

  stdout.writeln('FAIL: URL whitelist violations:');
  for (final violation in violations) {
    stdout.writeln('  $violation');
  }
  return false;
}

bool _isAllowedUrl(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host.isEmpty) {
    return false;
  }

  final address = InternetAddress.tryParse(host);
  if (host == 'localhost' || (address != null && address.isLoopback)) {
    return true;
  }

  return uri.scheme == 'https' && _allowedProviderHosts.contains(host);
}

String _trimUrl(String value) =>
    value.replaceFirst(RegExp(r'[.,;:!?)\]}]+$'), '');

bool _verifyVersion(_VerifyOptions options) {
  final pubspecVersion = _readPubspecVersion(options.root);
  if (pubspecVersion == null) {
    stdout.writeln('FAIL: version not found in pubspec.yaml');
    return false;
  }

  final tag = options.tag ?? _resolveTag(options.root);
  if (tag == null || tag.isEmpty) {
    stdout.writeln('FAIL: no release tag found; pass --tag vX.Y.Z');
    return false;
  }

  final tagVersion = _normalizeVersion(tag);
  final packageVersion = _normalizeVersion(pubspecVersion);
  if (tagVersion != packageVersion) {
    stdout.writeln(
      'FAIL: tag $tag does not match pubspec version $pubspecVersion',
    );
    return false;
  }

  stdout.writeln('OK: tag $tag matches pubspec version $pubspecVersion');
  return true;
}

String? _readPubspecVersion(String root) {
  final pubspec = File('$root${Platform.pathSeparator}pubspec.yaml');
  if (!pubspec.existsSync()) {
    return null;
  }

  final match = RegExp(
    r'^version:\s*([^\s#]+)',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  return match?.group(1);
}

String? _resolveTag(String root) {
  final githubRefType = Platform.environment['GITHUB_REF_TYPE'];
  final githubRefName = Platform.environment['GITHUB_REF_NAME'];
  if (githubRefType == 'tag' &&
      githubRefName != null &&
      githubRefName.isNotEmpty) {
    return githubRefName;
  }

  for (final arguments in <List<String>>[
    ['describe', '--tags', '--exact-match'],
    ['describe', '--tags'],
  ]) {
    final result = Process.runSync(
      'git',
      ['-C', root, ...arguments],
      runInShell: Platform.isWindows,
    );
    if (result.exitCode == 0) {
      final value = result.stdout.toString().trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

String _normalizeVersion(String value) {
  var normalized = value.trim();
  if (normalized.startsWith('v') || normalized.startsWith('V')) {
    normalized = normalized.substring(1);
  }
  return normalized.split('+').first;
}

List<File> _discoverFiles(
  String directoryPath,
  bool Function(String path) matches,
) {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    return const <File>[];
  }

  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => matches(file.path))
      .toList(growable: false);
}

File _resolveFile(String root, String path) {
  final file = File(path);
  return file.isAbsolute
      ? file
      : File('$root${Platform.pathSeparator}$path');
}

String _formatMiB(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MiB';

void _printUsage() {
  stdout.writeln('''
DailyDesk bundle verifier

Usage:
  dart run scripts/verify_bundle.dart [options]

Options:
  --apk PATH             Release APK to check; repeat for split APKs.
  --windows-zip PATH     Windows portable zip to check; repeat if needed.
  --tag TAG              Release tag to compare with pubspec version.
  --skip-size            Skip APK/zip existence and size assertions.
  --skip-url-whitelist   Skip source URL whitelist scanning.
  --skip-version         Skip tag/version consistency checks.
  -h, --help             Show this help.
''');
}

class _VerifyOptions {
  const _VerifyOptions({
    required this.root,
    required this.apkFiles,
    required this.windowsZipFiles,
    required this.tag,
    required this.skipSize,
    required this.skipUrlWhitelist,
    required this.skipVersion,
    required this.help,
  });

  final String root;
  final List<String> apkFiles;
  final List<String> windowsZipFiles;
  final String? tag;
  final bool skipSize;
  final bool skipUrlWhitelist;
  final bool skipVersion;
  final bool help;

  static _VerifyOptions parse(List<String> arguments) {
    final apkFiles = <String>[];
    final windowsZipFiles = <String>[];
    var root = Directory.current.path;
    String? tag;
    var skipSize = false;
    var skipUrlWhitelist = false;
    var skipVersion = false;
    var help = false;

    String requireValue(int index, String option) {
      if (index + 1 >= arguments.length) {
        stderr.writeln('Missing value for $option');
        exit(64);
      }
      return arguments[index + 1];
    }

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--apk') {
        apkFiles.add(requireValue(index, argument));
        index++;
      } else if (argument.startsWith('--apk=')) {
        apkFiles.add(argument.substring('--apk='.length));
      } else if (argument == '--windows-zip') {
        windowsZipFiles.add(requireValue(index, argument));
        index++;
      } else if (argument.startsWith('--windows-zip=')) {
        windowsZipFiles.add(argument.substring('--windows-zip='.length));
      } else if (argument == '--tag') {
        tag = requireValue(index, argument);
        index++;
      } else if (argument.startsWith('--tag=')) {
        tag = argument.substring('--tag='.length);
      } else if (argument == '--root') {
        root = requireValue(index, argument);
        index++;
      } else if (argument.startsWith('--root=')) {
        root = argument.substring('--root='.length);
      } else if (argument == '--skip-size') {
        skipSize = true;
      } else if (argument == '--skip-url-whitelist') {
        skipUrlWhitelist = true;
      } else if (argument == '--skip-version') {
        skipVersion = true;
      } else if (argument == '-h' || argument == '--help') {
        help = true;
      } else {
        stderr.writeln('Unknown option: $argument');
        exit(64);
      }
    }

    return _VerifyOptions(
      root: Directory(root).absolute.path,
      apkFiles: apkFiles,
      windowsZipFiles: windowsZipFiles,
      tag: tag,
      skipSize: skipSize,
      skipUrlWhitelist: skipUrlWhitelist,
      skipVersion: skipVersion,
      help: help,
    );
  }
}

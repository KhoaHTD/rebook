// Máy chủ demo một cổng: phục vụ bản web đã build và chuyển tiếp API / WebSocket về backend.
//
//   /api/**  → backend (bỏ tiền tố /api)       ví dụ /api/listings → http://localhost:8080/listings
//   /ws/**   → backend WebSocket (giữ nguyên)  ví dụ /ws/sessions/1
//   còn lại  → file trong build/web (có fallback index.html cho go_router)
//
// Cả web và API cùng một origin nên đặt một tunnel (cloudflared / ngrok) trước cổng này là đủ,
// không cần cấu hình CORS và địa chỉ tunnel đổi cũng không phải build lại web.
//
//   dart run tool/demo_server.dart [--port 8000] [--backend http://localhost:8080] [--root build/web]
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _hopByHop = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
};

/// Backend chỉ nhận origin localhost nên khi chuyển tiếp phải bỏ origin của trình duyệt.
const _dropRequestHeaders = {
  ..._hopByHop,
  'host',
  'origin',
  'referer',
  'accept-encoding',
  'content-length',
};

const _types = {
  'html': 'text/html; charset=utf-8',
  'js': 'text/javascript; charset=utf-8',
  'mjs': 'text/javascript; charset=utf-8',
  'json': 'application/json; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'txt': 'text/plain; charset=utf-8',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'gif': 'image/gif',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  'otf': 'font/otf',
  'ttf': 'font/ttf',
  'woff': 'font/woff',
  'woff2': 'font/woff2',
  'map': 'application/json',
};

/// File phải luôn tải lại để bản build mới có hiệu lực ngay (service worker giữ cache rất dai).
const _noCache = {
  'index.html',
  'flutter_service_worker.js',
  'flutter_bootstrap.js',
  'version.json',
  'manifest.json',
  'main.dart.js',
};

late final Uri _backend;
late final Directory _root;
final _client = HttpClient()..autoUncompress = false;

Future<void> main(List<String> args) async {
  String? opt(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final port = int.tryParse(opt('--port') ?? '') ?? 8000;
  _backend = Uri.parse(opt('--backend') ?? 'http://localhost:8080');
  _root = Directory(opt('--root') ?? 'build/web');
  if (!File('${_root.path}/index.html').existsSync()) {
    stderr.writeln(
      'Không thấy ${_root.path}/index.html. Build web trước: '
      'flutter build web --dart-define-from-file=env/tunnel.json',
    );
    exit(2);
  }

  final server = await HttpServer.bind(
    InternetAddress.anyIPv6,
    port,
    v6Only: false,
  );
  stdout.writeln(
    'Demo server: http://localhost:$port  →  API ${_backend.origin}',
  );
  await for (final req in server) {
    unawaited(_handle(req));
  }
}

Future<void> _handle(HttpRequest req) async {
  try {
    final path = req.uri.path;
    if (path == '/__health') {
      req.response
        ..headers.contentType = ContentType.text
        ..write('ok');
      await req.response.close();
    } else if (path == '/api' || path.startsWith('/api/')) {
      await _proxyHttp(req);
    } else if (path.startsWith('/ws/') &&
        WebSocketTransformer.isUpgradeRequest(req)) {
      await _proxyWebSocket(req);
    } else {
      await _serveStatic(req);
    }
  } on Object catch (e) {
    stderr.writeln('${req.method} ${req.uri}: $e');
    try {
      req.response.statusCode = HttpStatus.badGateway;
      await req.response.close();
    } on Object {
      // Phản hồi đã bắt đầu gửi: không còn gì để làm.
    }
  }
}

Future<void> _proxyHttp(HttpRequest req) async {
  final target = _backend.replace(
    path: req.uri.path.substring('/api'.length).isEmpty
        ? '/'
        : req.uri.path.substring('/api'.length),
    query: req.uri.hasQuery ? req.uri.query : null,
  );
  final HttpClientRequest out;
  try {
    out = await _client.openUrl(req.method, target);
  } on SocketException {
    return _fail(req, 'Backend chưa chạy ở ${_backend.origin}');
  }
  out.followRedirects = false;
  req.headers.forEach((name, values) {
    if (_dropRequestHeaders.contains(name)) return;
    for (final v in values) {
      out.headers.add(name, v);
    }
  });
  if (req.contentLength >= 0) out.contentLength = req.contentLength;
  await out.addStream(req);
  final HttpClientResponse resp;
  try {
    resp = await out.close();
  } on Object catch (e) {
    return _fail(req, 'Backend không phản hồi: $e');
  }

  final res = req.response..statusCode = resp.statusCode;
  resp.headers.forEach((name, values) {
    if (_hopByHop.contains(name) || name == 'content-length') return;
    for (final v in values) {
      res.headers.add(name, v);
    }
  });
  if (resp.contentLength >= 0) res.contentLength = resp.contentLength;
  await resp.pipe(res);
}

Future<void> _fail(HttpRequest req, String message) async {
  req.response
    ..statusCode = HttpStatus.badGateway
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'code': 'BAD_GATEWAY', 'message': message}));
  await req.response.close();
}

Future<void> _proxyWebSocket(HttpRequest req) async {
  final target = _backend.replace(
    scheme: _backend.scheme == 'https' ? 'wss' : 'ws',
    path: req.uri.path,
    query: req.uri.hasQuery ? req.uri.query : null,
  );
  final WebSocket upstream;
  try {
    upstream = await WebSocket.connect(target.toString());
  } on Object {
    req.response.statusCode = HttpStatus.badGateway;
    await req.response.close();
    return;
  }
  final client = await WebSocketTransformer.upgrade(req);
  // Tunnel ngắt kết nối im lặng sau ~100 giây; ping định kỳ để giữ phòng đấu giá sống.
  client.pingInterval = const Duration(seconds: 25);

  client.listen(
    upstream.add,
    onDone: () => upstream.close(),
    onError: (Object _) => upstream.close(),
  );
  upstream.listen(
    client.add,
    onDone: () => client.close(),
    onError: (Object _) => client.close(),
  );
}

Future<void> _serveStatic(HttpRequest req) async {
  if (req.method != 'GET' && req.method != 'HEAD') {
    req.response.statusCode = HttpStatus.methodNotAllowed;
    return req.response.close();
  }
  final segments = Uri.decodeFull(req.uri.path)
      .split('/')
      .where((s) => s.isNotEmpty)
      .toList();
  if (segments.any((s) => s == '..' || s.contains('\\'))) {
    req.response.statusCode = HttpStatus.badRequest;
    return req.response.close();
  }

  var file = File([_root.path, ...segments].join('/'));
  if (!file.existsSync()) {
    // Có đuôi file mà không thấy = thật sự 404; không đuôi = route của go_router.
    if (segments.isNotEmpty && segments.last.contains('.')) {
      req.response.statusCode = HttpStatus.notFound;
      return req.response.close();
    }
    file = File('${_root.path}/index.html');
  } else if (FileSystemEntity.isDirectorySync(file.path)) {
    file = File('${file.path}/index.html');
  }

  final name = file.uri.pathSegments.last;
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  final res = req.response
    ..headers.set('content-type', _types[ext] ?? 'application/octet-stream')
    ..contentLength = await file.length();
  if (_noCache.contains(name)) {
    res.headers.set('cache-control', 'no-store');
  }
  if (req.method == 'HEAD') return res.close();
  await res.addStream(file.openRead());
  await res.close();
}

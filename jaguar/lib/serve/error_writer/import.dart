library jaguar.src.serve.error_writer;

import 'dart:async';
import 'dart:io';
import 'package:stack_trace/stack_trace.dart';
import 'package:jaguar/jaguar.dart';

/// Error writer interface
///
/// Error writer is used by [Jaguar] server to write 404 and 500 errors
abstract class ErrorWriter {
  /// Makes [Response] for 404 error
  FutureOr<void> make404(Context ctx);

  /// Makes [Response] for 500 error
  FutureOr<void> make500(Context ctx, Object error, [StackTrace stack]);
}

class DefaultErrorWriter implements ErrorWriter {
  /// Makes [Response] for 404 error
  ///
  /// Respects 'accept' request header and returns corresponding [Response]
  void make404(Context ctx) {
    final String accept = ctx.req.headers.value(HttpHeaders.acceptHeader) ?? '';
    final List<String> acceptList = accept.split(',');

    if (acceptList.contains('text/html')) {
      final resp =
          Response(_write404Html(ctx), statusCode: HttpStatus.notFound);
      resp.headers.contentType = ContentType.html;
      ctx.response = resp;
      return;
    } else if (acceptList.contains('application/json') ||
        acceptList.contains('text/json')) {
      ctx.response = Response.json({
        'Path': ctx.path,
        'Method': ctx.method,
        'Message': 'Not found!',
      }, statusCode: HttpStatus.notFound);
      return;
    } /* TODO else if (acceptList.contains('application/xml')) {
      ctx.response = Response.xml({
        'Path': ctx.path,
        'Method': ctx.method,
        'Message': 'Not found!',
      }, statusCode: HttpStatus.NOT_FOUND);
      return;
    } */
    else {
      ctx.response =
          Response(_write404Html(ctx), statusCode: HttpStatus.notFound)
            ..headers.contentType = ContentType.html;
      return;
    }
  }

  /// Makes [Response] for 500 error
  ///
  /// Respects 'accept' request header and returns corresponding [Response]
  void make500(Context ctx, Object error, [StackTrace stack]) {
    final String accept = ctx.req.headers.value(HttpHeaders.acceptHeader) ?? '';
    final List<String> acceptList = accept.split(',');

    if (acceptList.contains('text/html')) {
      final resp = Response(_write500Html(ctx, error, stack),
          statusCode: HttpStatus.notFound);
      resp.headers.contentType = ContentType.html;
      ctx.response = resp;
      return;
    } else if (acceptList.contains('application/json') ||
        acceptList.contains('text/json')) {
      final data = <String, dynamic>{
        'error': error.toString(),
      };
      if (stack != null)
        data['stack'] =
            new Trace.from(stack).frames.map((f) => f.toString()).toList();

      ctx.response = Response.json(data, statusCode: 500);
    } /* TODO else if (acceptList.contains('application/xml')) {
      final data = <String, dynamic>{
        'error': error.toString(),
      };
      if (stack != null) data['stack'] = Trace.format(stack);

      return Response.xml(data, statusCode: 500);
    } */
    else {
      final resp = Response(_write500Html(ctx, error, stack), statusCode: 500);
      resp.headers.contentType = ContentType.html;
      ctx.response = resp;
    }
  }
}

/// Creates body for 404 html response
String _write404Html(Context ctx) => '''
<!DOCTYPE>
<html>
<head>
  <title>404 - Not found!</title>
  <style>
    body, html {
      margin: 0px;
      padding: 0px;
      border: 0px;
      font-family: monospace, sans-serif;
      background-color: #e4e4e4;
    }
    .content {
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    }
    .title {
      font-size: 30px;
      margin: 10px 0px;
    }
    .info {
      font-size: 16px;
      margin: 5px 0px;
    }
  </style>
</head>
<body>
  <div class="content">
    <div class="title">Not found!</div>
    <div class="info">Path: <i>${ctx.path}</i></div>
    <div class="info">Method: <i>${ctx.method}</i></div>
  </div>
</body>
</html>
''';

/// Creates body for 500 html response
String _write500Html(Context ctx, Object error, [StackTrace stack]) {
  String stackInfo = "";
  if (stack != null) {
    stackInfo = '''
    <div class="info">
    <div class="info-title">Stack</div>
      <pre>${Trace.format(stack)}</pre>
    </div>
    ''';
  }

  return '''
<!DOCTYPE>
<html>
<head>
  <title>Server error</title>
  <style>
    body, html {
      margin: 0px;
      padding: 0px;
      border: 0px;
      background-color: #e4e4e4;
    }
    .header {
      font-family: Helvetica,Arial;
      font-size: 20px;
      line-height: 25px;
      background-color: rgba(204, 49, 0, 0.94);
      color: #F8F8F8;
      overflow: hidden;
      padding: 10px 10px;
      box-sizing: border-box;
      font-weight: bold;
    }
    .footer {
      padding-left:20px;
      height:20px;
      font-family:Helvetica,Arial;
      font-size:12px;
      color:#5E5E5E;
      margin-top: 10px;
    }
    .content {
      font-family:Helvetica,Arial;
      font-size:18px;
    }
    .info {
      border-bottom: 1px solid rgba(0, 0, 0, 0.21);
      padding: 15px;
      box-sizing: border-box;
    }
    .info-title {
      font-size: 20px;
      font-weight: bold;
      margin-bottom: 5px;
    }
    pre {
      margin: 0px;
    }
  </style>
</head>
<body>
  <div class="header" style="">Server error!</div>
  <div class="content">
    <div class="info">
      <div class="info-title">Message</div>
      <div>$error</div>
    </div>
    $stackInfo
    <div class="info">
      <div class="info-title">Request</div>
      <div>Resource: ${ctx.path}</div>
      <div>Method: ${ctx.method}</div>
    </div>
  </div>
  <div class="footer">Jaguar Server - 2016 - <a href="https://github.com/jaguar-dart">https://github.com/jaguar-dart</a></div>
</body>
</html>
''';
}

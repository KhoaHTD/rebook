import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Trình duyệt tải được file.
bool get canDownloadFiles => true;

/// Tạo Blob từ [content] rồi bấm một thẻ `<a download>` vô hình để trình duyệt lưu file [filename].
Future<bool> downloadTextFile(
  String filename,
  String content, {
  String mime = 'text/csv',
}) async {
  try {
    final blobCtor = globalContext.getProperty<JSFunction>('Blob'.toJS);
    final options = JSObject()..['type'] = '$mime;charset=utf-8'.toJS;
    final blob = blobCtor.callAsConstructor<JSObject>(
      [content.toJS].toJS,
      options,
    );
    final url = globalContext
        .getProperty<JSObject>('URL'.toJS)
        .callMethod<JSString>('createObjectURL'.toJS, blob)
        .toDart;
    final doc = globalContext.getProperty<JSObject>('document'.toJS);
    final a = doc.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
    a['href'] = url.toJS;
    a['download'] = filename.toJS;
    a.callMethod<JSAny?>('click'.toJS);
    globalContext
        .getProperty<JSObject>('URL'.toJS)
        .callMethod<JSAny?>('revokeObjectURL'.toJS, url.toJS);
    return true;
  } on Object {
    return false;
  }
}

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Future<String?> saveAndShareXlsx(Uint8List bytes, String fileName) async {
  try {
    final web.Blob blob = web.Blob(
      <JSAny>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: _xlsxMime),
    );
    final String objectUrl = web.URL.createObjectURL(blob);
    final web.HTMLAnchorElement anchor = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 10),
        () => web.URL.revokeObjectURL(objectUrl),
      ),
    );
    return null;
  } catch (e) {
    return 'Não foi possível baixar o arquivo Excel: $e';
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Future<String?> saveAndShareXlsx(Uint8List bytes, String fileName) async {
  try {
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    final ShareResult result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: _xlsxMime)],
        fileNameOverrides: [fileName],
        subject: 'Relatório CashCtrl',
        text: 'Relatório de desempenho gerado pelo CashCtrl.',
        title: 'Relatório CashCtrl',
      ),
    );
    if (result.status == ShareResultStatus.unavailable) {
      return 'Compartilhamento indisponível neste dispositivo.';
    }
    return null;
  } catch (e) {
    return 'Não foi possível salvar o arquivo Excel: $e';
  }
}

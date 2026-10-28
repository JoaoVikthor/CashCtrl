import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/transaction.dart';
import 'format.dart';

export 'report_export_web.dart' if (dart.library.io) 'report_export_native.dart';

const List<String> _monthAbbreviations = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

NumFormat get _moneyFormat => NumFormat.custom(formatCode: '#,##0.00');

CellStyle _headerStyle() => CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#E8EFEA'),
      backgroundColorHex: ExcelColor.fromHexString('#165A41'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

CellStyle _labelStyle() => CellStyle(bold: true);

CellStyle _moneyStyle({bool bold = false}) => CellStyle(
      numberFormat: _moneyFormat,
      horizontalAlign: HorizontalAlign.Right,
      bold: bold,
    );

String _pad(int value) => value < 10 ? '0$value' : '$value';

String _dateTimeLabel(DateTime d) =>
    '${formatDate(d)} ${_pad(d.hour)}:${_pad(d.minute)}';

String _monthLabel(DateTime d) =>
    '${_monthAbbreviations[d.month - 1]}/${d.year}';

void _writeText(
  Sheet sheet,
  int row,
  int column,
  String value,
  CellStyle? style,
) {
  final cell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
  );
  cell.value = TextCellValue(value);
  if (style != null) cell.cellStyle = style;
}

void _writeNumber(
  Sheet sheet,
  int row,
  int column,
  double value, {
  CellStyle? style,
}) {
  final cell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
  );
  cell.value = DoubleCellValue(value);
  cell.cellStyle = style ?? _moneyStyle();
}

void _writeHeader(Sheet sheet, List<String> titles) {
  for (var i = 0; i < titles.length; i++) {
    _writeText(sheet, 0, i, titles[i], _headerStyle());
  }
}

Uint8List buildReportWorkbook({
  required List<AppTransaction> transactions,
  required String periodLabel,
}) {
  final Excel excel = Excel.createExcel();
  final Sheet resumo = excel['Resumo'];
  final Sheet mensal = excel['Mensal'];
  final Sheet transacoes = excel['Transações'];

  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }
  excel.setDefaultSheet('Resumo');

  double totalReceitas = 0;
  double totalCustos = 0;
  for (final t in transactions) {
    if (t.type.isReceita) {
      totalReceitas += t.amount;
    } else {
      totalCustos += t.amount;
    }
  }
  final double lucro = totalReceitas - totalCustos;
  final double margem = totalReceitas > 0 ? (lucro / totalReceitas) * 100 : 0;

  _writeText(
    resumo,
    0,
    0,
    'Relatório de Desempenho - CashCtrl',
    CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#B89775'),
    ),
  );
  _writeText(resumo, 2, 0, 'Período', _labelStyle());
  _writeText(resumo, 2, 1, periodLabel, null);
  _writeText(resumo, 3, 0, 'Lucro Líquido', _labelStyle());
  _writeNumber(resumo, 3, 1, lucro, style: _moneyStyle(bold: true));
  _writeText(resumo, 4, 0, 'Margem (%)', _labelStyle());
  _writeNumber(resumo, 4, 1, margem, style: _moneyStyle(bold: true));
  _writeText(resumo, 5, 0, 'Total Receitas', _labelStyle());
  _writeNumber(resumo, 5, 1, totalReceitas);
  _writeText(resumo, 6, 0, 'Total Custos', _labelStyle());
  _writeNumber(resumo, 6, 1, totalCustos);
  _writeText(resumo, 8, 0, 'Transações no período', _labelStyle());
  _writeNumber(
    resumo,
    8,
    1,
    transactions.length.toDouble(),
    style: CellStyle(
      numberFormat: NumFormat.custom(formatCode: '0'),
      horizontalAlign: HorizontalAlign.Right,
    ),
  );
  _writeText(resumo, 9, 0, 'Gerado em', _labelStyle());
  _writeText(resumo, 9, 1, _dateTimeLabel(DateTime.now()), null);
  resumo.setColumnWidth(0, 30);
  resumo.setColumnWidth(1, 22);

  _writeHeader(mensal, ['Mês', 'Receitas', 'Custos', 'Resultado']);
  final DateTime now = DateTime.now();
  var row = 1;
  double totalMensalReceitas = 0;
  double totalMensalCustos = 0;
  for (var i = 5; i >= 0; i--) {
    final DateTime reference = DateTime(now.year, now.month - i);
    double receitas = 0;
    double custos = 0;
    for (final t in transactions) {
      if (t.date.year == reference.year && t.date.month == reference.month) {
        if (t.type.isReceita) {
          receitas += t.amount;
        } else {
          custos += t.amount;
        }
      }
    }
    totalMensalReceitas += receitas;
    totalMensalCustos += custos;
    _writeText(mensal, row, 0, _monthLabel(reference), null);
    _writeNumber(mensal, row, 1, receitas);
    _writeNumber(mensal, row, 2, custos);
    _writeNumber(
      mensal,
      row,
      3,
      receitas - custos,
      style: _moneyStyle(bold: true),
    );
    row++;
  }
  _writeText(mensal, row, 0, 'Total', _labelStyle());
  _writeNumber(
    mensal,
    row,
    1,
    totalMensalReceitas,
    style: _moneyStyle(bold: true),
  );
  _writeNumber(
    mensal,
    row,
    2,
    totalMensalCustos,
    style: _moneyStyle(bold: true),
  );
  _writeNumber(
    mensal,
    row,
    3,
    totalMensalReceitas - totalMensalCustos,
    style: _moneyStyle(bold: true),
  );
  mensal.setColumnWidth(0, 18);
  mensal.setColumnWidth(1, 16);
  mensal.setColumnWidth(2, 16);
  mensal.setColumnWidth(3, 16);

  _writeHeader(transacoes, [
    'Data',
    'Tipo',
    'Categoria',
    'Descrição',
    'Forma de Pagamento',
    'Valor',
  ]);
  final List<AppTransaction> ordenadas = List<AppTransaction>.from(transactions)
    ..sort((a, b) => b.date.compareTo(a.date));
  var txRow = 1;
  for (final t in ordenadas) {
    _writeText(transacoes, txRow, 0, formatDate(t.date), null);
    _writeText(transacoes, txRow, 1, t.type.label, null);
    _writeText(transacoes, txRow, 2, t.category, null);
    _writeText(transacoes, txRow, 3, t.description, null);
    _writeText(transacoes, txRow, 4, t.paymentMethod.label, null);
    _writeNumber(
      transacoes,
      txRow,
      5,
      t.type.isReceita ? t.amount : -t.amount,
    );
    txRow++;
  }
  transacoes.setColumnWidth(0, 14);
  transacoes.setColumnWidth(1, 12);
  transacoes.setColumnWidth(2, 22);
  transacoes.setColumnWidth(3, 42);
  transacoes.setColumnWidth(4, 24);
  transacoes.setColumnWidth(5, 16);

  final List<int>? encoded = excel.encode();
  if (encoded == null) {
    throw StateError('Não foi possível gerar o arquivo Excel.');
  }
  return Uint8List.fromList(encoded);
}

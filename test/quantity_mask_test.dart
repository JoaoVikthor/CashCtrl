import 'package:ctrlcash/utils/quantity_mask.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuantityMask.shiftFor', () {
    test('un e pct usam 1 casa decimal', () {
      expect(QuantityMask.shiftFor('un'), 1);
      expect(QuantityMask.shiftFor('pct'), 1);
      expect(QuantityMask.shiftFor(' UN '), 1);
    });

    test('g e ml usam 0 casas decimais', () {
      expect(QuantityMask.shiftFor('g'), 0);
      expect(QuantityMask.shiftFor('ml'), 0);
      expect(QuantityMask.shiftFor(' G'), 0);
    });

    test('kg, l e litro usam 2 casas decimais', () {
      expect(QuantityMask.shiftFor('kg'), 2);
      expect(QuantityMask.shiftFor('l'), 2);
      expect(QuantityMask.shiftFor('L'), 2);
      expect(QuantityMask.shiftFor('litro'), 2);
    });

    test('unidade desconhecida usa 0 casas', () {
      expect(QuantityMask.shiftFor('x'), 0);
    });
  });

  group('QuantityMask.display', () {
    test('modo unidade', () {
      expect(QuantityMask.display('5', 'un'), '0,5');
      expect(QuantityMask.display('50', 'un'), '5,0');
      expect(QuantityMask.display('501', 'un'), '50,1');
      expect(QuantityMask.display('1234', 'un'), '123,4');
      expect(QuantityMask.display('', 'un'), '0');
    });

    test('modo grama', () {
      expect(QuantityMask.display('5', 'g'), '5');
      expect(QuantityMask.display('60', 'g'), '60');
      expect(QuantityMask.display('', 'g'), '0');
    });

    test('modo quilograma', () {
      expect(QuantityMask.display('500', 'kg'), '5,00');
      expect(QuantityMask.display('5000', 'kg'), '50,00');
      expect(QuantityMask.display('25000', 'kg'), '250,00');
      expect(QuantityMask.display('5', 'kg'), '0,05');
    });

    test('modo mililitro', () {
      expect(QuantityMask.display('250', 'ml'), '250');
      expect(QuantityMask.display('5', 'ml'), '5');
    });
  });

  group('QuantityMask.toValue', () {
    test('unidade', () {
      expect(QuantityMask.toValue('0,5', 'un'), 0.5);
      expect(QuantityMask.toValue('5,0', 'un'), 5.0);
      expect(QuantityMask.toValue('50,1', 'un'), 50.1);
    });

    test('grama', () {
      expect(QuantityMask.toValue('50', 'g'), 50.0);
      expect(QuantityMask.toValue('5', 'g'), 5.0);
    });

    test('quilograma', () {
      expect(QuantityMask.toValue('5,00', 'kg'), 5.0);
      expect(QuantityMask.toValue('250,00', 'kg'), 250.0);
      expect(QuantityMask.toValue('0,05', 'kg'), 0.05);
    });

    test('vazio retorna zero', () {
      expect(QuantityMask.toValue('', 'un'), 0.0);
      expect(QuantityMask.toValue('', 'g'), 0.0);
    });
  });

  group('QuantityMask.fromValue', () {
    test('unidade', () {
      expect(QuantityMask.fromValue(0.5, 'un'), '5');
      expect(QuantityMask.fromValue(5.0, 'un'), '50');
    });

    test('grama', () {
      expect(QuantityMask.fromValue(60.0, 'g'), '60');
      expect(QuantityMask.fromValue(5.0, 'g'), '5');
    });

    test('quilograma', () {
      expect(QuantityMask.fromValue(0.5, 'kg'), '50');
      expect(QuantityMask.fromValue(5.0, 'kg'), '500');
      expect(QuantityMask.fromValue(250.0, 'kg'), '25000');
    });

    test('zero retorna string vazia', () {
      expect(QuantityMask.fromValue(0.0, 'un'), '');
      expect(QuantityMask.fromValue(0.0, 'g'), '');
    });
  });

  group('round-trip', () {
    test('display -> toValue -> fromValue preserva digitos', () {
      const unit = 'un';
      const displayText = '5,0';
      final value = QuantityMask.toValue(displayText, unit);
      final digits = QuantityMask.fromValue(value, unit);
      expect(QuantityMask.display(digits, unit), displayText);
    });

    test('round-trip kg', () {
      const unit = 'kg';
      const displayText = '250,00';
      final value = QuantityMask.toValue(displayText, unit);
      final digits = QuantityMask.fromValue(value, unit);
      expect(QuantityMask.display(digits, unit), displayText);
    });
  });

  group('QuantityMask.nextDisplay', () {
    test('digita sequencia em unidade', () {
      expect(QuantityMask.nextDisplay('', '5', 'un'), '0,5');
      expect(QuantityMask.nextDisplay('5', '0,50', 'un'), '5,0');
      expect(QuantityMask.nextDisplay('50', '5,00', 'un'), '50,0');
    });

    test('backspace em unidade', () {
      expect(QuantityMask.nextDisplay('50', '5,', 'un'), '0,5');
      expect(QuantityMask.nextDisplay('5', '', 'un'), '0');
    });

    test('ignora digitos nao numericos', () {
      expect(QuantityMask.nextDisplay('', 'a0,b5', 'un'), '0,5');
    });

    test('limita a 9 digitos', () {
      expect(
        QuantityMask.nextDisplay('123456789', '1234567890', 'un'),
        '12345678,9',
      );
    });
  });

  group('QuantityMask.formatterFor', () {
    late TextInputFormatter formatter;

    setUp(() {
      formatter = QuantityMask.formatterFor('un');
    });

    TextEditingValue edit(String oldText, String newText) {
      return formatter.formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(text: newText),
      );
    }

    test('digita 5, 0 e 0', () {
      var value = edit('', '5');
      expect(value.text, '0,5');
      expect(value.selection, const TextSelection.collapsed(offset: 3));

      value = edit('0,5', '0,50');
      expect(value.text, '5,0');

      value = edit('5,0', '5,00');
      expect(value.text, '50,0');
    });

    test('backspace remove ultimo digito', () {
      final value = edit('5,0', '5,');
      expect(value.text, '0,5');
    });

    test('colar texto cru funciona', () {
      final value = edit('', '2,5 kg');
      expect(value.text, '2,5');
    });

    test('limite de digitos pelo formatter', () {
      var value = edit('', '123456789');
      expect(value.text, '12345678,9');

      value = edit('12345678,9', '12345678,90');
      expect(value.text, '12345678,9');
    });

    test('limpa e redigita 250 kg com modelo mental de 2 casas', () {
      final kgFormatter = QuantityMask.formatterFor('kg');
      TextEditingValue edit(String oldText, String newText) {
        return kgFormatter.formatEditUpdate(
          TextEditingValue(text: oldText),
          TextEditingValue(text: newText),
        );
      }

      var value = edit('150,00', '');
      expect(value.text, '0');

      value = edit('0', '2');
      expect(value.text, '0,02');
      value = edit('0,02', '0,25');
      expect(value.text, '0,25');
      value = edit('0,25', '2,50');
      expect(value.text, '2,50');
      value = edit('2,50', '25,00');
      expect(value.text, '25,00');
      value = edit('25,00', '250,00');
      expect(value.text, '250,00');
      expect(QuantityMask.toValue(value.text, 'kg'), 250.0);
    });
  });
}

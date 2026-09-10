import 'package:sua_barbearia/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('moeda', () {
    test('formata em BRL', () {
      final result = Formatters.currency(40);
      expect(result, contains('40,00'));
      expect(result, contains(r'R$'));
    });

    test('aceita string vinda da API', () {
      expect(Formatters.currencyFromString('45.50'), contains('45,50'));
    });

    test('trata nulo como zero', () {
      expect(Formatters.currency(null), contains('0,00'));
    });
  });

  group('datas', () {
    test('formata no padrão DD/MM/AAAA', () {
      expect(Formatters.date(DateTime(2026, 9, 10)), '10/09/2026');
    });

    test('formata data e hora', () {
      expect(
        Formatters.dateTime(DateTime(2026, 9, 10, 14, 30)),
        '10/09/2026 14:30',
      );
    });

    test('reconhece hoje e amanhã', () {
      final now = DateTime.now();
      expect(Formatters.friendlyDate(now), 'Hoje');
      expect(
        Formatters.friendlyDate(now.add(const Duration(days: 1))),
        'Amanhã',
      );
    });
  });

  group('relógio', () {
    test('converte HH:MM:SS em HH:MM', () {
      expect(Formatters.clock('09:30:00'), '09:30');
      expect(Formatters.clock('14:05:00'), '14:05');
    });

    test('trata valor vazio', () {
      expect(Formatters.clock(null), '-');
      expect(Formatters.clock(''), '-');
    });
  });

  group('duração', () {
    test('formata minutos e horas', () {
      expect(Formatters.duration(30), '30min');
      expect(Formatters.duration(60), '1h');
      expect(Formatters.duration(90), '1h30');
      expect(Formatters.duration(120), '2h');
    });
  });

  group('documentos', () {
    test('formata telefone com 11 dígitos', () {
      expect(Formatters.phone('41999998888'), '(41) 99999-8888');
    });

    test('formata telefone com 10 dígitos', () {
      expect(Formatters.phone('4133334444'), '(41) 3333-4444');
    });

    test('formata CPF e CNPJ', () {
      expect(Formatters.cpf('52998224725'), '529.982.247-25');
      expect(Formatters.cnpj('11222333000181'), '11.222.333/0001-81');
    });

    test('formata CEP', () {
      expect(Formatters.zipCode('80020310'), '80020-310');
    });
  });

  group('iniciais', () {
    test('usa primeiro e último nome', () {
      expect(Formatters.initials('Carlos Mendes'), 'CM');
      expect(Formatters.initials('João Pedro Silva'), 'JS');
      expect(Formatters.initials('Jota'), 'J');
      expect(Formatters.initials(''), '?');
    });
  });
}

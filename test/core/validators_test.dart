import 'package:sua_barbearia/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('aceita e-mails válidos', () {
      expect(Validators.email('carlos@suabarbearia.com'), isNull);
      expect(Validators.email('nome.sobrenome@empresa.com.br'), isNull);
    });

    test('rejeita e-mails inválidos', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('sem-arroba'), isNotNull);
      expect(Validators.email('faltando@dominio'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('exige ao menos 8 caracteres', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('rejeita senha vazia', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('compara com a senha original', () {
      final validator = Validators.confirmPassword(() => 'SenhaForte@1');
      expect(validator('SenhaForte@1'), isNull);
      expect(validator('outra'), isNotNull);
    });
  });

  group('Validators.phone', () {
    test('aceita telefones com 10 ou 11 dígitos', () {
      expect(Validators.phone('(41) 99999-8888'), isNull);
      expect(Validators.phone('(41) 3333-4444'), isNull);
    });

    test('rejeita telefone incompleto', () {
      expect(Validators.phone('4199'), isNotNull);
    });

    test('permite vazio quando não obrigatório', () {
      expect(Validators.phone('', isRequired: false), isNull);
      expect(Validators.phone('', isRequired: true), isNotNull);
    });
  });

  group('Validators.cpf', () {
    test('valida dígitos verificadores', () {
      expect(Validators.cpf('529.982.247-25'), isNull);
    });

    test('rejeita CPF inválido', () {
      expect(Validators.cpf('111.111.111-11'), isNotNull);
      expect(Validators.cpf('123.456.789-00'), isNotNull);
    });

    test('permite vazio por padrão', () {
      expect(Validators.cpf(''), isNull);
    });
  });

  group('Validators.cnpj', () {
    test('valida dígitos verificadores', () {
      expect(Validators.cnpj('11.222.333/0001-81'), isNull);
    });

    test('rejeita CNPJ inválido', () {
      expect(Validators.cnpj('11.111.111/1111-11'), isNotNull);
      expect(Validators.cnpj('11.222.333/0001-00'), isNotNull);
    });
  });

  group('Validators.money', () {
    test('aceita valores numéricos', () {
      expect(Validators.money('45.00'), isNull);
      expect(Validators.money('45,90'), isNull);
    });

    test('rejeita texto e negativos', () {
      expect(Validators.money('abc'), isNotNull);
      expect(Validators.money('-10'), isNotNull);
    });
  });

  group('Validators.compose', () {
    test('devolve o primeiro erro encontrado', () {
      final validator = Validators.compose([
        (value) => Validators.required(value, field: 'O campo'),
        Validators.email,
      ]);
      expect(validator(''), contains('obrigatório'));
      expect(validator('invalido'), contains('válido'));
      expect(validator('ok@suabarbearia.com'), isNull);
    });
  });
}

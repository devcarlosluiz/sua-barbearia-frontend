import 'package:sua_barbearia/core/errors/api_exception.dart';
import 'package:sua_barbearia/core/errors/error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessages', () {
    test('traduz códigos de negócio do backend', () {
      expect(
        ErrorMessages.forCode('BARBER_NOT_AVAILABLE'),
        'O barbeiro não está disponível neste horário.',
      );
      expect(
        ErrorMessages.forCode('INSUFFICIENT_STOCK'),
        contains('Estoque insuficiente'),
      );
      expect(
        ErrorMessages.forCode('REVIEW_ALREADY_EXISTS'),
        contains('já avaliou'),
      );
    });

    test('usa a mensagem do servidor quando o código é desconhecido', () {
      expect(
        ErrorMessages.forCode('CODIGO_NOVO', fallback: 'Mensagem do servidor'),
        'Mensagem do servidor',
      );
    });

    test('tem mensagem padrão para código desconhecido sem fallback', () {
      expect(ErrorMessages.forCode('QUALQUER'), isNotEmpty);
    });

    test('nunca devolve string vazia', () {
      for (final code in [
        'SLOT_NOT_AVAILABLE',
        'PERMISSION_DENIED',
        'NETWORK_ERROR',
        'INTERNAL_ERROR',
      ]) {
        expect(ErrorMessages.forCode(code), isNotEmpty);
      }
    });
  });

  group('ApiException', () {
    test('classifica os status HTTP', () {
      const unauthorized = ApiException(message: 'x', statusCode: 401);
      const forbidden = ApiException(message: 'x', statusCode: 403);
      const conflict = ApiException(message: 'x', statusCode: 409);

      expect(unauthorized.isUnauthorized, isTrue);
      expect(forbidden.isForbidden, isTrue);
      expect(conflict.isConflict, isTrue);
    });

    test('expõe erros por campo', () {
      const exception = ApiException(
        message: 'Verifique os dados',
        code: 'VALIDATION_ERROR',
        statusCode: 400,
        fieldErrors: {
          'email': ['Já existe uma conta com este e-mail.'],
        },
      );

      expect(exception.hasFieldErrors, isTrue);
      expect(exception.errorFor('email'), contains('Já existe'));
      expect(exception.errorFor('senha'), isNull);
    });

    test('identifica erro de rede', () {
      const exception = ApiException(message: 'x', code: 'NETWORK_ERROR');
      expect(exception.isNetworkError, isTrue);
    });
  });
}

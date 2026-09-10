import 'package:sua_barbearia/core/storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Regressão do incidente em que o `flutter_secure_storage` na Web lançava
/// `OperationError` (Web Crypto) em toda operação: a exceção escapava, o app
/// travava no splash e todas as chamadas HTTP viravam "sem conexão".
///
/// O armazenamento seguro pode falhar (store corrompido, indisponível,
/// permissão negada) — mas isso nunca pode derrubar o aplicativo.
void main() {
  late MockFlutterSecureStorage inner;
  late SecureStorage storage;

  setUp(() {
    inner = MockFlutterSecureStorage();
    storage = SecureStorage(storage: inner);
  });

  group('operação normal', () {
    test('grava e lê os tokens', () async {
      when(
        () => inner.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => inner.read(key: 'sua_barbearia.access_token'),
      ).thenAnswer((_) async => 'access-123');

      await storage.saveTokens(access: 'access-123', refresh: 'refresh-456');

      expect(await storage.readAccessToken(), 'access-123');
      expect(await storage.hasSession, isTrue);
      verify(
        () =>
            inner.write(key: 'sua_barbearia.access_token', value: 'access-123'),
      ).called(1);
      verify(
        () => inner.write(
            key: 'sua_barbearia.refresh_token', value: 'refresh-456'),
      ).called(1);
    });

    test('sem token gravado não há sessão', () async {
      when(() => inner.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      expect(await storage.hasSession, isFalse);
    });
  });

  group('ambiente sem armazenamento seguro', () {
    // Na Web o flutter_secure_storage exige *secure context* (HTTPS ou
    // localhost) e lança `UnsupportedError` fora dele. Engolir isso fazia o
    // login "passar" e a requisição seguinte voltar 401 — que a tela mostrava
    // como senha incorreta.
    test('escrita indisponível propaga SecureStorageUnavailable', () async {
      when(
        () => inner.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenThrow(UnsupportedError('only works in secure contexts'));

      await expectLater(
        storage.saveTokens(access: 'a', refresh: 'b'),
        throwsA(isA<SecureStorageUnavailable>()),
      );
    });

    test('leitura indisponível devolve null sem tentar limpar', () async {
      when(
        () => inner.read(key: any(named: 'key')),
      ).thenThrow(UnsupportedError('only works in secure contexts'));

      expect(await storage.readAccessToken(), isNull);
      // Limpar também falharia: não há store para limpar.
      verifyNever(() => inner.deleteAll());
    });
  });

  group('store corrompido ou indisponível', () {
    test('leitura que lança devolve null em vez de propagar', () async {
      when(
        () => inner.read(key: any(named: 'key')),
      ).thenThrow(Exception('OperationError'));
      when(() => inner.deleteAll()).thenAnswer((_) async {});

      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
    });

    test('leitura que falha limpa o store corrompido', () async {
      when(
        () => inner.read(key: any(named: 'key')),
      ).thenThrow(Exception('OperationError'));
      when(() => inner.deleteAll()).thenAnswer((_) async {});

      await storage.readAccessToken();

      verify(() => inner.deleteAll()).called(1);
    });

    test('hasSession devolve false quando a leitura falha', () async {
      when(
        () => inner.read(key: any(named: 'key')),
      ).thenThrow(Exception('OperationError'));
      when(() => inner.deleteAll()).thenAnswer((_) async {});

      expect(await storage.hasSession, isFalse);
    });

    test('escrita que lança não propaga', () async {
      when(
        () => inner.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenThrow(Exception('OperationError'));

      // Não deve lançar: falhar ao persistir não pode abortar o login.
      await expectLater(
        storage.saveTokens(access: 'a', refresh: 'b'),
        completes,
      );
      await expectLater(storage.saveRole('CLIENT'), completes);
    });

    test('clear que lança não propaga', () async {
      when(() => inner.deleteAll()).thenThrow(Exception('OperationError'));
      await expectLater(storage.clear(), completes);
    });
  });
}

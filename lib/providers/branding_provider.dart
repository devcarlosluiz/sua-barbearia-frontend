import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/branding.dart';
import 'core_providers.dart';

/// Logo do sistema.
///
/// É consumida também pela tela de login, então não pode depender de sessão.
/// Uma falha aqui não deve impedir o uso do app: o widget da marca cai para o
/// desenho padrão quando o provider está em erro ou ainda carregando.
final brandingProvider = FutureProvider<Branding>((ref) async {
  return ref.watch(brandingRepositoryProvider).branding();
});

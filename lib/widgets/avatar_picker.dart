import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors/api_exception.dart';
import '../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';
import 'app_avatar.dart';
import 'app_dialog.dart';
import 'app_states.dart';

/// Foto de perfil com envio e remoção.
///
/// Usado nas três áreas (proprietário, barbeiro e cliente): a foto é do
/// usuário, não do papel. Sem foto, o [AppAvatar] desenha as iniciais — então
/// não existe estado "quebrado" enquanto não há imagem.
class AvatarPicker extends ConsumerStatefulWidget {
  const AvatarPicker({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 72,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  ConsumerState<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<AvatarPicker> {
  bool _isWorking = false;

  bool get _hasPhoto => widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

  Future<void> _escolher() async {
    final XFile? escolhida;
    try {
      escolhida = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
    } catch (error, stackTrace) {
      // Um seletor que não abre precisa dizer isso em vez de ficar mudo.
      debugPrint('[Avatar] falha ao abrir o seletor: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        AppFeedback.error(
          context,
          'Não foi possível abrir o seletor de imagens neste dispositivo.',
        );
      }
      return;
    }

    if (escolhida == null || !mounted) return;

    setState(() => _isWorking = true);
    try {
      final bytes = await escolhida.readAsBytes();
      await ref
          .read(authControllerProvider.notifier)
          .uploadAvatar(bytes: bytes, filename: escolhida.name);
      if (mounted) AppFeedback.success(context, 'Foto atualizada.');
    } on ApiException catch (error) {
      if (mounted) {
        // A mensagem do campo `avatar` diz o motivo exato (tamanho, formato,
        // dimensões) — bem mais útil que o texto genérico.
        AppFeedback.error(context, error.errorFor('avatar') ?? error.message);
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _abrirMenu() async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Trocar foto'),
              onTap: () => Navigator.of(context).pop('trocar'),
            ),
            ListTile(
              leading: const Icon(Icons.person_off_outlined),
              title: const Text('Remover foto'),
              onTap: () => Navigator.of(context).pop('remover'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (acao == 'trocar') await _escolher();
    if (acao == 'remover') await _remover();
  }

  Future<void> _remover() async {
    final confirmado = await AppDialog.confirm(
      context,
      title: 'Remover a foto?',
      message: 'Seu perfil voltará a exibir as iniciais do seu nome.',
      confirmLabel: 'Remover',
      isDestructive: true,
      icon: Icons.person_off_outlined,
    );
    if (!confirmado || !mounted) return;

    setState(() => _isWorking = true);
    try {
      await ref.read(authControllerProvider.notifier).removeAvatar();
      if (mounted) AppFeedback.success(context, 'Foto removida.');
    } on ApiException catch (error) {
      if (mounted) AppFeedback.error(context, error.message);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final acao =
        _hasPhoto ? 'Trocar a foto de perfil' : 'Adicionar foto de perfil';

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        AppAvatar(
          name: widget.name,
          imageUrl: widget.imageUrl,
          size: widget.size,
        ),
        // O selo indica que o avatar é clicável — sem ele, ninguém descobre
        // que dá para trocar a foto tocando na própria imagem.
        // O rótulo fica no elemento que de fato recebe o toque: um
        // `Semantics` externo é substituído pelo nó do próprio `InkWell`.
        Tooltip(
          message: acao,
          child: Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // Sem foto, tocar já abre o seletor — é a única ação possível.
              // Com foto, abre o menu: esconder "remover" atrás de um toque
              // longo faria a opção não existir para quem não adivinha.
              onTap: _isWorking ? null : (_hasPhoto ? _abrirMenu : _escolher),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: _isWorking
                    ? SizedBox(
                        height: widget.size * 0.22,
                        width: widget.size * 0.22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.photo_camera_rounded,
                        size: widget.size * 0.22,
                        color: theme.colorScheme.onPrimary,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Linha com a foto, o nome e as ações — para as telas de perfil.
class AvatarPickerTile extends StatelessWidget {
  const AvatarPickerTile({
    super.key,
    required this.name,
    required this.subtitle,
    this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        AvatarPicker(name: name, imageUrl: imageUrl),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleMedium),
              Text(subtitle, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Toque na câmera para enviar ou trocar a sua foto.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

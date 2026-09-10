import 'dart:async';

import 'package:flutter/material.dart';

/// Campo de busca com debounce, usado nas listagens.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.onSearch,
    this.hint = 'Buscar...',
    this.initialValue,
    this.debounce = const Duration(milliseconds: 400),
    this.autofocus = false,
  });

  final ValueChanged<String> onSearch;
  final String hint;
  final String? initialValue;
  final Duration debounce;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onSearch(value.trim()));
    setState(() {});
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onSearch('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      onSubmitted: (value) {
        _timer?.cancel();
        widget.onSearch(value.trim());
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Limpar busca',
              ),
        isDense: true,
      ),
    );
  }
}

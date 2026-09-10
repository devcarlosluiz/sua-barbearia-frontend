import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import 'app_text_field.dart';

/// Seleção padronizada, com o mesmo visual do [AppTextField].
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.hint,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.itemIcon,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final IconData? Function(T item)? itemIcon;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? hint;
  final bool isRequired;
  final bool enabled;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(label: label, isRequired: isRequired),
        DropdownButtonFormField<T>(
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          validator: validator,
          hint: hint == null ? null : Text(hint!),
          onChanged: enabled ? onChanged : null,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      if (itemIcon?.call(item) != null) ...[
                        Icon(itemIcon!(item), size: 18),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          itemLabel(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

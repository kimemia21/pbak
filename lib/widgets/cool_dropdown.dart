import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

/// A "cool, chilled" dropdown for the bikers app.
///
/// UX:
/// - Tap opens a bottom-sheet (not the default menu)
/// - Optional search
/// - Keeps Material form validation support
class CoolDropdown<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;

  final T? value;
  final List<T> items;
  final String Function(T)? itemAsString;

  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;

  final bool enabled;
  final bool searchable;

  const CoolDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.hint,
    this.icon,
    this.itemAsString,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.searchable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DropdownSearch<T>(
      // v6 API: items is an async callback (supports search/filtering).
      items: (filter, loadProps) async {
        // If caller didn't enable search, ignore filter.
        if (!searchable || filter.trim().isEmpty) return items;

        final query = filter.trim().toLowerCase();
        final asString = itemAsString ?? (v) => v.toString();
        return items
            .where((e) => asString(e).toLowerCase().contains(query))
            .toList(growable: false);
      },
      selectedItem: value,
      enabled: enabled,
      itemAsString: itemAsString,
      validator: validator,
      onChanged: onChanged,
      // v6 API: decoratorProps
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null
              ? null
              : Icon(icon, size: 20, color: cs.onSurfaceVariant),
        ),
      ),
      popupProps: PopupProps.bottomSheet(
        showSearchBox: searchable,
        searchFieldProps: TextFieldProps(
          decoration: const InputDecoration(
            hintText: 'Search…',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        bottomSheetProps: BottomSheetProps(
          backgroundColor: cs.surface,
          elevation: 12,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
        containerBuilder: (ctx, popupWidget) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(child: popupWidget),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

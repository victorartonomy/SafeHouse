import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

/// Dropdown selector for an optional [Category].
///
/// `null` value = "None (use manual key)".
class CategoryPicker extends StatelessWidget {
  final Category? value;
  final ValueChanged<Category?> onChanged;
  final String noneLabel;
  final bool enabled;

  const CategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.noneLabel = 'None (use manual key)',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        // Auto-load if empty.
        if (state.categories.isEmpty &&
            !state.loading &&
            state.error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CategoryBloc>().add(const CategoriesLoadRequested());
          });
        }

        return DropdownButtonFormField<String?>(
          initialValue: value?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(noneLabel),
            ),
            for (final c in state.categories)
              DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
          ],
          onChanged: enabled
              ? (id) {
                  if (id == null) {
                    onChanged(null);
                  } else {
                    final found = state.categories.firstWhere(
                      (c) => c.id == id,
                    );
                    onChanged(found);
                  }
                }
              : null,
        );
      },
    );
  }
}

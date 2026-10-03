import 'package:flutter/material.dart';

enum FieldType { text, number, dropdown, multiSelect }

class FormFieldSpec {
  final String name; 
  final String label;
  final FieldType type;
  final dynamic initialValue;
  final List<dynamic>? options; 
  final String Function(dynamic)? optionLabelBuilder;
  final String? Function(dynamic)? validator;
  final void Function(dynamic) onSaved;

  FormFieldSpec({
    required this.name, required this.label, required this.type,
    this.initialValue, this.options, this.optionLabelBuilder,
    this.validator, required this.onSaved,
  });
}

class DynamicForm extends StatefulWidget {
  final List<FormFieldSpec> fields;
  final Future<void> Function() onSave;
  final Map<String, String>? serverErrors;

  const DynamicForm({super.key, required this.fields, required this.onSave, this.serverErrors});

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _isSaving = false;

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isSaving = true);
    try {
      await widget.onSave();
      setState(() => _isDirty = false);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Есть несохраненные изменения'),
        content: const Text('Вы уверены, что хотите уйти? Все данные будут потеряны.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Остаться')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Уйти', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context, result);
      },
      child: Form(
        key: _formKey,
        onChanged: _markDirty,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...widget.fields.map((spec) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildField(spec),
            )),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Сохранить'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(FormFieldSpec spec) {
    final serverError = widget.serverErrors?[spec.name];

    String? combinedValidator(dynamic value) {
      final clientError = spec.validator?.call(value);
      if (clientError != null) return clientError;
      return serverError;
    }

    switch (spec.type) {
      case FieldType.text:
      case FieldType.number:
        return TextFormField(
          initialValue: spec.initialValue?.toString(),
          decoration: InputDecoration(
            labelText: spec.label, 
            border: const OutlineInputBorder(),
            errorText: serverError, // 2. ВАЖНО: Рисуем красный текст ошибки!
          ),
          keyboardType: spec.type == FieldType.number ? TextInputType.number : TextInputType.text,
          validator: combinedValidator,
          onSaved: spec.onSaved,
          onChanged: (_) => _markDirty(),
        );

      case FieldType.dropdown:
        return DropdownButtonFormField<dynamic>(
          initialValue: spec.initialValue == 0 ? null : spec.initialValue,
          decoration: InputDecoration(
            labelText: spec.label, 
            border: const OutlineInputBorder(),
            errorText: serverError,
          ),
          items: spec.options!.map((o) => DropdownMenuItem(value: o.id, child: Text(spec.optionLabelBuilder!(o)))).toList(),
          validator: combinedValidator,
          onSaved: spec.onSaved,
          onChanged: (_) => _markDirty(), 
        );

      case FieldType.multiSelect:
        return FormField<List<int>>(
          initialValue: (spec.initialValue as List<int>?) ?? [],
          validator: combinedValidator,
          onSaved: (v) => spec.onSaved(v),
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label, 
                border: const OutlineInputBorder(), 
                errorText: field.errorText ?? serverError,
              ),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: spec.options!.map((o) {
                  final selected = field.value!.contains(o.id);
                  return FilterChip(
                    label: Text(spec.optionLabelBuilder!(o)),
                    selected: selected,
                    onSelected: (val) {
                      final next = [...field.value!];
                      val ? next.add(o.id) : next.remove(o.id);
                      field.didChange(next); 
                      _markDirty();
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
    }
  }
}
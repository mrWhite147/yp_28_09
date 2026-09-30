import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../repositories/persistent_store_repository.dart';
import '../utils/validators.dart';
import '../widgets/dynamic_form.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? id;
  final PersistentStore store;
  const CustomerFormScreen({super.key, this.id, required this.store});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late Customer _customer;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _customer = widget.id != null 
        ? widget.store.customers.firstWhere((c) => c.id == widget.id)
        : Customer(id: 0, fullName: '', email: '', card: DiscountCard(number: '', issuedAt: DateTime.now().toIso8601String().split('T')[0]));
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    try {
      widget.store.validateCustomerUnique(_customer);
      
      if (widget.id == null) {
        final newId = (widget.store.customers.lastOrNull?.id ?? 0) + 1;
        widget.store.customers.add(_customer.copyWith(id: newId));
      } else {
        final idx = widget.store.customers.indexWhere((c) => c.id == widget.id);
        widget.store.customers[idx] = _customer;
      }
      await widget.store.saveCustomers();
      if (mounted) context.pop();
    } on ValidationException catch (e) {
      setState(() => _serverErrors = {e.field: e.message});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль покупателя')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DynamicForm(
              serverErrors: _serverErrors,
              onSave: _save,
              fields: [
                FormFieldSpec(
                  name: 'fullName', label: 'ФИО', type: FieldType.text, initialValue: _customer.fullName,
                  validator: Validators.required, onSaved: (v) => _customer = _customer.copyWith(fullName: v),
                ),
                FormFieldSpec(
                  name: 'email', label: 'Email (Уникальный)', type: FieldType.text, initialValue: _customer.email,
                  validator: Validators.combine([Validators.required, Validators.email]), 
                  onSaved: (v) => _customer = _customer.copyWith(email: v),
                ),
                FormFieldSpec(
                  name: 'cardNumber', label: 'Номер карты лояльности', type: FieldType.text, initialValue: _customer.card.number,
                  validator: Validators.required, 
                  onSaved: (v) => _customer = _customer.copyWith(card: DiscountCard(number: v, issuedAt: _customer.card.issuedAt)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
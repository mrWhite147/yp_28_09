import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../models/queries.dart';
import '../repositories/api_repository.dart';
import '../core/api_exceptions.dart';
import '../utils/validators.dart';
import '../widgets/dynamic_form.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? id;
  const CustomerFormScreen({super.key, this.id}); // УДАЛЕНО: required this.store

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  Customer? _customer;
  Map<String, String> _serverErrors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.id == null) {
      setState(() {
        _customer = Customer(id: 0, fullName: '', email: '', card: DiscountCard(number: '', issuedAt: DateTime.now().toIso8601String().split('T')[0]));
        _isLoading = false;
      });
      return;
    }

    try {
      final repo = context.read<ApiRepository<Customer, CustomerQuery>>();
      final c = await repo.findById(widget.id!);
      setState(() {
        _customer = c;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        context.pop();
      }
    }
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    try {
      final repo = context.read<ApiRepository<Customer, CustomerQuery>>();
      if (widget.id == null) {
        await repo.create(_customer!);
      } else {
        await repo.update(widget.id!, _customer!);
      }
      if (mounted) context.pop();
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      rethrow;
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _customer == null) {
      return Scaffold(appBar: AppBar(title: const Text('Загрузка...')), body: const Center(child: CircularProgressIndicator()));
    }

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
                  name: 'fullName', label: 'ФИО', type: FieldType.text, initialValue: _customer!.fullName,
                  validator: Validators.required, onSaved: (v) => _customer = _customer!.copyWith(fullName: v),
                ),
                FormFieldSpec(
                  name: 'email', label: 'Email (Уникальный)', type: FieldType.text, initialValue: _customer!.email,
                  validator: Validators.combine([Validators.required, Validators.email]), 
                  onSaved: (v) => _customer = _customer!.copyWith(email: v),
                ),
                FormFieldSpec(
                  name: 'cardNumber', label: 'Номер карты лояльности', type: FieldType.text, initialValue: _customer!.card.number,
                  validator: Validators.required, 
                  onSaved: (v) => _customer = _customer!.copyWith(card: DiscountCard(number: v, issuedAt: _customer!.card.issuedAt)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/models.dart';
import '../models/queries.dart';
import '../repositories/api_repository.dart';
import '../core/api_exceptions.dart';
import '../utils/validators.dart';
import '../widgets/dynamic_form.dart';

class ProductFormScreen extends StatefulWidget {
  final int? id;
  const ProductFormScreen({super.key, this.id});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  Product? _product;
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
        _product = const Product(id: 0, name: '', sku: '', price: 0, stockCount: 0, manufacturerId: 0, categoryIds: [], supplierIds: []);
        _isLoading = false;
      });
      return;
    }

    try {
      // ИСПРАВЛЕНИЕ: Добавлен второй тип ProductQuery
      final repo = context.read<ApiRepository<Product, ProductQuery>>();
      final p = await repo.findById(widget.id!);
      setState(() {
        _product = p;
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
      final repo = context.read<ApiRepository<Product, ProductQuery>>();
      if (widget.id == null) {
        await repo.create(_product!);
      } else {
        await repo.update(widget.id!, _product!);
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
    if (_isLoading || _product == null) {
      return Scaffold(appBar: AppBar(title: const Text('Загрузка...')), body: const Center(child: CircularProgressIndicator()));
    }

    final cache = context.watch<DictionaryCache>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Новый товар' : 'Редактирование товара')),
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
                  name: 'name', label: 'Название товара', type: FieldType.text, initialValue: _product!.name,
                  validator: Validators.required, onSaved: (v) => _product = _product!.copyWith(name: v),
                ),
                FormFieldSpec(
                  name: 'sku', label: 'Артикул (Уникальный)', type: FieldType.text, initialValue: _product!.sku,
                  validator: Validators.required, onSaved: (v) => _product = _product!.copyWith(sku: v),
                ),
                FormFieldSpec(
                  name: 'price', label: 'Цена (₽)', type: FieldType.number, initialValue: _product!.price,
                  validator: Validators.combine([Validators.required, Validators.positiveNumber]), 
                  onSaved: (v) => _product = _product!.copyWith(price: double.parse(v.replaceAll(',', '.'))),
                ),
                FormFieldSpec(
                  name: 'stockCount', label: 'Остаток на складе (шт.)', type: FieldType.number, initialValue: _product!.stockCount,
                  validator: Validators.combine([Validators.required, Validators.positiveNumber]), 
                  onSaved: (v) => _product = _product!.copyWith(stockCount: double.parse(v.replaceAll(',', '.')).toInt()),
                ),
                FormFieldSpec(
                  name: 'manufacturerId', label: 'Производитель', type: FieldType.dropdown, 
                  initialValue: _product!.manufacturerId,
                  options: cache.manufacturers,
                  optionLabelBuilder: (m) => m.name,
                  validator: (v) => v == null ? 'Выберите производителя' : null,
                  onSaved: (v) => _product = _product!.copyWith(manufacturerId: v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
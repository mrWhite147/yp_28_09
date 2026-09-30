import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../repositories/persistent_store_repository.dart';
import '../utils/validators.dart';
import '../widgets/dynamic_form.dart';

class ProductFormScreen extends StatefulWidget {
  final int? id;
  final PersistentStore store;
  const ProductFormScreen({super.key, this.id, required this.store});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late Product _product;
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _product = widget.id != null 
        ? widget.store.products.firstWhere((p) => p.id == widget.id)
        : const Product(id: 0, name: '', sku: '', price: 0, stockCount: 0, manufacturerId: 0, categoryIds: [], supplierIds: []);
  }

  Future<void> _save() async {
    setState(() => _serverErrors = {});
    try {
      widget.store.validateProductUnique(_product);
      
      if (widget.id == null) {
        final newId = (widget.store.products.lastOrNull?.id ?? 0) + 1;
        widget.store.products.add(_product.copyWith(id: newId));
      } else {
        final idx = widget.store.products.indexWhere((p) => p.id == widget.id);
        widget.store.products[idx] = _product;
      }
      await widget.store.saveProducts();
      if (mounted) context.pop();
    } on ValidationException catch (e) {
      setState(() => _serverErrors = {e.field: e.message});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  name: 'name', label: 'Название товара', type: FieldType.text, initialValue: _product.name,
                  validator: Validators.required, onSaved: (v) => _product = _product.copyWith(name: v),
                ),
                FormFieldSpec(
                  name: 'sku', label: 'Артикул (Уникальный)', type: FieldType.text, initialValue: _product.sku,
                  validator: Validators.required, onSaved: (v) => _product = _product.copyWith(sku: v),
                ),
                FormFieldSpec(
                  name: 'price', label: 'Цена (₽)', type: FieldType.number, initialValue: _product.price,
                  validator: Validators.combine([Validators.required, Validators.positiveNumber]), 
                  onSaved: (v) => _product = _product.copyWith(price: double.parse(v.replaceAll(',', '.'))),
                ),
                
                FormFieldSpec(
                  name: 'stockCount', label: 'Остаток на складе (шт.)', type: FieldType.number, initialValue: _product.stockCount,
                  validator: Validators.combine([Validators.required, Validators.positiveNumber]), 
                  onSaved: (v) => _product = _product.copyWith(stockCount: double.parse(v.replaceAll(',', '.')).toInt()),
                ),

                FormFieldSpec(
                  name: 'manufacturerId', label: 'Производитель', type: FieldType.dropdown, 
                  initialValue: _product.manufacturerId,
                  options: widget.store.manufacturers.where((m) => !m.isDeleted).toList(),
                  optionLabelBuilder: (m) => m.name,
                  validator: (v) => v == null ? 'Выберите производителя' : null,
                  onSaved: (v) => _product = _product.copyWith(manufacturerId: v),
                ),
                FormFieldSpec(
                  name: 'categoryIds', label: 'Категории', type: FieldType.multiSelect, 
                  initialValue: _product.categoryIds,
                  options: widget.store.categories.where((c) => !c.isDeleted).toList(),
                  optionLabelBuilder: (c) => c.name,
                  validator: Validators.required,
                  onSaved: (v) => _product = _product.copyWith(categoryIds: v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
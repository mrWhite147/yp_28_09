import 'package:flutter/material.dart';
import '../models/page_result.dart';
import '../repositories/repository_interfaces.dart';

enum LoadStatus { idle, loading, success, empty, error }

class ListNotifier<T, Q> extends ChangeNotifier {
  final Repository<T, Q> _repository;
  ListNotifier(this._repository);

  PageResult<T> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load(Q query) async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _result = await _repository.find(query);
      _status = _result.items.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (e) {
      _error = e.toString();
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected(Q currentQuery, {bool hard = false}) async {
    try {
      await _repository.deleteMany(_selected.toList(), hard: hard);
      _selected.clear();
      await load(currentQuery);
    } catch (e) {
      String msg = e.toString();      
      if (msg.contains('Instance of')) {
        try { msg = 'ValidationException: ${(e as dynamic).message}'; } catch (_) {}
      }
      
      _error = msg;
      _status = LoadStatus.error;
      notifyListeners();
    }
  }

  Future<void> restore(int id, Q currentQuery) async {
    await _repository.restore(id);
    await load(currentQuery);
  }
}
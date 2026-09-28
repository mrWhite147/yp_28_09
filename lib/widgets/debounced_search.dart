import 'dart:async';
import 'package:flutter/material.dart';

class DebouncedSearch extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  const DebouncedSearch({super.key, required this.initialValue, required this.onChanged});

  @override
  State<DebouncedSearch> createState() => _DebouncedSearchState();
}

class _DebouncedSearchState extends State<DebouncedSearch> {
  late TextEditingController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  void _onSearch(String value) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () => widget.onChanged(value));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(labelText: 'Поиск', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
      onChanged: _onSearch,
    );
  }
}
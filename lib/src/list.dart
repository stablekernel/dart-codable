import 'dart:collection';

import 'package:codable/src/codable.dart';
import 'package:codable/src/keyed_archive.dart';
import 'package:codable/src/resolver.dart';

class ListArchive extends Object with ListMixin<dynamic> implements Referencable {
  final List<dynamic> _inner;

  ListArchive() : _inner = [];

  ListArchive.fromRaw(List<dynamic> raw)
    : _inner = raw.map((e) {
    if (e is Map) {
      return new KeyedArchive(e);
    } else if (e is List) {
      return ListArchive.fromRaw(e);
    }
    return e;
  }).toList();

  @override
  operator [](int index) => _inner[index];

  @override
  int get length => _inner.length;

  @override
  set length(int length) {
    _inner.length = length;
  }

  @override
  void operator []=(int index, dynamic val) {
    _inner[index] = val;
  }

  @override
  void add(dynamic element) {
    _inner.add(element);
  }

  @override
  void addAll(Iterable<dynamic> iterable) {
    _inner.addAll(iterable);
  }

  @override
  void resolveOrThrow(ReferenceResolver coder) {
    _inner.forEach((i) {
      if (i is KeyedArchive) {
        i.resolveOrThrow(coder);
      } else if (i is ListArchive) {
        i.resolveOrThrow(coder);
      }
    });
  }
}

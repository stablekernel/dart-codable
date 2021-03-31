import 'dart:collection';

import 'package:conduit_codable/src/codable.dart';
import 'package:conduit_codable/src/coding.dart';
import 'package:conduit_codable/src/keyed_archive.dart';
import 'package:conduit_codable/src/resolver.dart';

/// A list of values in a [KeyedArchive].
///
/// This object is a [List] that has additional behavior for encoding and decoding [Coding] objects.
class ListArchive extends Object
    with ListMixin<dynamic>
    implements Referencable {
  final List<dynamic> _inner;

  ListArchive() : _inner = [];

  /// Replaces all instances of [Map] and [List] in this object with [KeyedArchive] and [ListArchive]s.
  ListArchive.from(List<dynamic> raw)
      : _inner = raw.map((e) {
          if (e is Map<String, dynamic>) {
            return KeyedArchive(e);
          } else if (e is List) {
            return ListArchive.from(e);
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

  List<dynamic> toPrimitive() {
    final out = [];
    _inner.forEach((val) {
      if (val is KeyedArchive) {
        out.add(val.toPrimitive());
      } else if (val is ListArchive) {
        out.add(val.toPrimitive());
      } else {
        out.add(val);
      }
    });
    return out;
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

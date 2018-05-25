/*
Copyright 2018, the Dart project authors. All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import 'dart:async' as async;
import 'dart:core' as core;
import 'dart:core' hide Map, String, int;

class FailedCast implements core.Exception {
  dynamic context;
  dynamic key;
  core.String message;
  FailedCast(this.context, this.key, this.message);
  toString() {
    if (key == null) {
      return "Failed cast at $context: $message";
    }
    return "Failed cast at $context $key: $message";
  }
}

abstract class Cast<T> {
  const Cast();
  T _cast(dynamic from, core.String context, dynamic key);
  T cast(dynamic from) => _cast(from, "toplevel", null);
}

class AnyCast extends Cast<dynamic> {
  const AnyCast();
  dynamic _cast(dynamic from, core.String context, dynamic key) => from;
}

class IntCast extends Cast<core.int> {
  const IntCast();
  core.int _cast(dynamic from, core.String context, dynamic key) =>
    from is core.int
      ? from
      : throw new FailedCast(context, key, "$from is not an int");
}

class DoubleCast extends Cast<core.double> {
  const DoubleCast();
  core.double _cast(dynamic from, core.String context, dynamic key) =>
    from is core.double
      ? from
      : throw new FailedCast(context, key, "$from is not an double");
}

class StringCast extends Cast<core.String> {
  const StringCast();
  core.String _cast(dynamic from, core.String context, dynamic key) =>
    from is core.String
      ? from
      : throw new FailedCast(context, key, "$from is not a String");
}

class BoolCast extends Cast<core.bool> {
  const BoolCast();
  core.bool _cast(dynamic from, core.String context, dynamic key) =>
    from is core.bool
      ? from
      : throw new FailedCast(context, key, "$from is not a bool");
}

class Map<K, V> extends Cast<core.Map<K, V>> {
  final Cast<K> _key;
  final Cast<V> _value;
  const Map(Cast<K> key, Cast<V> value)
    : _key = key,
      _value = value;
  core.Map<K, V> _cast(dynamic from, core.String context, dynamic key) {
    if (from is core.Map) {
      var result = <K, V>{};
      for (var key in from.keys) {
        var newKey = _key._cast(key, "map entry", key);
        result[newKey] = _value._cast(from[key], "map entry", key);
      }
      return result;
    }
    return throw new FailedCast(context, key, "not a map");
  }
}

class StringMap<V> extends Cast<core.Map<core.String, V>> {
  final Cast<V> _value;
  const StringMap(Cast<V> value) : _value = value;
  core.Map<core.String, V> _cast(
    dynamic from, core.String context, dynamic key) {
    if (from is core.Map) {
      var result = <core.String, V>{};
      for (core.String key in from.keys) {
        result[key] = _value._cast(from[key], "map entry", key);
      }
      return result;
    }
    return throw new FailedCast(context, key, "not a map");
  }
}

class List<E> extends Cast<core.List<E>> {
  final Cast<E> _entry;
  const List(Cast<E> entry) : _entry = entry;
  core.List<E> _cast(dynamic from, core.String context, dynamic key) {
    if (from is core.List) {
      var length = from.length;
      var result = core.List<E>(length);
      for (core.int i = 0; i < length; ++i) {
        if (from[i] != null) {
          result[i] = _entry._cast(from[i], "list entry", i);
        } else {
          result[i] = null;
        }
      }
      return result;
    }
    return throw new FailedCast(context, key, "not a list");
  }
}

class Keyed<K, V> extends Cast<core.Map<K, V>> {
  Iterable<K> get keys => _map.keys;
  final core.Map<K, Cast<V>> _map;
  const Keyed(core.Map<K, Cast<V>> map)
    : _map = map;
  core.Map<K, V> _cast(dynamic from, core.String context, dynamic key) {
    core.Map<K, V> result = {};
    if (from is core.Map) {
      for (K key in from.keys) {
        if (_map.containsKey(key)) {
          result[key] = _map[key]._cast(from[key], "map entry", key);
        } else {
          result[key] = from[key];
        }
      }
      return result;
    }
    return throw new FailedCast(context, key, "not a map");
  }
}

class OneOf<S, T> extends Cast<dynamic> {
  final Cast<S> _left;
  final Cast<T> _right;
  const OneOf(Cast<S> left, Cast<T> right)
    : _left = left,
      _right = right;
  dynamic _cast(dynamic from, core.String context, dynamic key) {
    try {
      return _left._cast(from, context, key);
    } on FailedCast {
      return _right._cast(from, context, key);
    }
  }
}

class Apply<S, T> extends Cast<T> {
  final Cast<S> _first;
  final T Function(S) _transform;
  const Apply(T Function(S) transform, Cast<S> first)
    : _transform = transform,
      _first = first;
  T _cast(dynamic from, core.String context, dynamic key) =>
    _transform(_first._cast(from, context, key));
}

class Future<E> extends Cast<async.Future<E>> {
  final Cast<E> _value;
  const Future(Cast<E> value) : _value = value;
  async.Future<E> _cast(dynamic from, core.String context, dynamic key) {
    if (from is async.Future) {
      return from.then(_value.cast);
    }
    return throw new FailedCast(context, key, "not a Future");
  }
}

const any = AnyCast();
const bool = BoolCast();
const int = IntCast();
const double = DoubleCast();
const String = StringCast();

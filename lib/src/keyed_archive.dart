import 'dart:collection';
import 'package:codable/src/coding.dart';
import 'package:codable/cast.dart' as cast;
import 'package:codable/src/list.dart';
import 'package:codable/src/resolver.dart';

class KeyedArchive extends Object with MapMixin<String, dynamic> {
  static KeyedArchive unarchive(Map<String, dynamic> data) {
    final archive = new KeyedArchive(data);
    archive.resolve(new KeyResolver(archive));
    return archive;
  }

  KeyedArchive._empty();

  KeyedArchive(this._map) {
    _recode();
  }

  Uri referenceURI;

  Map<String, dynamic> _map;
  Coding _inflated;
  KeyedArchive _objectReference;

  void castValues(Map<String, cast.Cast> schema) {
    if (schema == null) {
      return;
    }

    final caster = new cast.Keyed(schema);
    _map = caster.cast(_map);

    if (_objectReference != null) {
      // todo: can optimize this by only running it once
      _objectReference._map = caster.cast(_objectReference._map);
    }
  }

  operator []=(String key, dynamic value) {
    _map[key] = value;
  }

  dynamic operator [](Object key) => _getValue(key);

  Iterable<String> get keys => _map.keys;

  void clear() => _map.clear();

  dynamic remove(Object key) => _map.remove(key);

  dynamic _getValue(String key) {
    if (_map.containsKey(key)) {
      return _map[key];
    }

    return _objectReference?._getValue(key);
  }

  void _recode() {
    const caster = cast.Map(cast.String, cast.any);
    final keys = _map.keys.toList();
    keys.forEach((key) {
      final val = _map[key];
      if (val is Map) {
        _map[key] = new KeyedArchive(caster.cast(val));
      } else if (val is List) {
        _map[key] = new ListArchive.fromRaw(val);
      } else if (key == r"$ref") {
        if (val is Map) {
          _objectReference = val;
        } else {
          referenceURI = Uri.parse(Uri.parse(val).fragment);
        }
      }
    });
  }

  void resolve(KeyResolver coder) {
    if (referenceURI != null) {
      _objectReference = coder.resolve(referenceURI);
      if (_objectReference == null) {
        throw new ArgumentError("Invalid document. Reference '$referenceURI' does not exist in document.");
      }
    }

    _map.forEach((key, val) {
      if (val is KeyedArchive) {
        val.resolve(coder);
      } else if (val is ListArchive) {
        val.resolve(coder);
      }
    });
  }

  /* decode */

  T _decodedObject<T extends Coding>(KeyedArchive raw, T inflate()) {
    if (raw == null) {
      return null;
    }

    if (raw._inflated == null) {
      raw._inflated = inflate();
      raw._inflated.decode(raw);
    }

    return raw._inflated;
  }

  T decode<T>(String key) {
    var v = _getValue(key);
    if (v == null) {
      return null;
    }

    if (T == Uri) {
      return Uri.parse(v) as T;
    } else if (T == DateTime) {
      return DateTime.parse(v) as T;
    }

    return v;
  }


  T decodeObject<T extends Coding>(String key, T inflate()) {
    final val = _getValue(key);
    if (val == null) {
      return null;
    }

    if (val is! KeyedArchive) {
      throw new ArgumentError(
        "Cannot decode key '$key' into '$T', because the value is not a Map. Actual value: '$val'.");
    }

    return _decodedObject(val, inflate);
  }

  List<T> decodeObjects<T extends Coding>(String key, T inflate()) {
    var val = _getValue(key);
    if (val == null) {
      return null;
    }
    if (val is! List) {
      throw new ArgumentError(
        "Cannot decode key '$key' as 'List<$T>', because value is not a List. Actual value: '$val'.");
    }

    return (val as List<dynamic>).map((v) => _decodedObject(v, inflate)).toList().cast<T>();
  }

  Map<String, T> decodeObjectMap<T extends Coding>(String key, T inflate()) {
    var v = _getValue(key);
    if (v == null) {
      return null;
    }

    if (v is! Map<String, dynamic>) {
      throw new ArgumentError("Cannot decode key '$key' as 'Map<String, $T>', because value is not a Map. Actual value: '$v'.");
    }

    return new Map<String, T>.fromIterable(v.keys, key: (k) => k, value: (k) => _decodedObject(v[k], inflate));
  }

  /* encode */

  Map<String, dynamic> _encodedObject(Coding object) {
    // todo: an object can override the values it inherits from its
    // reference object. These values are siblings to the $ref key.
    // they are currently not being emitted. the solution is probably tricky.
    // letting encode run as normal would stack overflow when there is a cyclic
    // reference between this object and another.
    var json = new KeyedArchive._empty().._map = {}..referenceURI = object.referenceURI;
    if (json.referenceURI != null) {
      json._map[r"$ref"] = "#${json.referenceURI.toString()}";
    } else {
      object.encode(json);
    }
    return json;
  }

  void encode<T>(String key, T value) {
    if (value == null) {
      return;
    }

    _map[key] = value;
  }

  void encodeUri(String key, Uri value) {
    final stringRepresentation = value?.toString();
    if (stringRepresentation == null) {
      return;
    }

    _map[key] = stringRepresentation;
  }

  void encodeObject(String key, Coding value) {
    if (value == null) {
      return;
    }

    _map[key] = _encodedObject(value);
  }

  void encodeObjects(String key, List<Coding> value) {
    if (value == null) {
      return;
    }

    _map[key] = value.map((v) => _encodedObject(v)).toList();
  }

  void encodeObjectMap<T extends Coding>(String key, Map<String, T> value) {
    if (value == null) {
      return;
    }

    var object = <String, dynamic>{};
    value.forEach((k, v) {
      object[k] = _encodedObject(v);
    });

    _map[key] = object;
  }
}


# codable
 
[![Build Status](https://travis-ci.org/stablekernel/dart-codable.svg?branch=master)](https://travis-ci.org/stablekernel/dart-codable)

A library for encoding and decoding dynamic data into Dart objects.

## Basic Usage 

Data objects extend `Coding`:

```dart
class Person extends Coding {
  String name;

  @override
  void decode(KeyedArchive object) {
    // must call super
    super.decode(object);

    name = object.decode("name");   
  }

  @override
  void encode(KeyedArchive object) {
    object.encode("name", name);
  }
}
```

An object that extends `Coding` can be read from JSON: 

```dart
final json = json.decode(...);
final archive = KeyedArchive.unarchive(json);
final person = Person()..decode(archive);
```

Objects that extend `Coding` may also be written to JSON:

```dart
final person = Person()..name = "Bob";
final archive = KeyedArchive.archive(person);
final json = json.encode(archive);
```

`Coding` objects can encode or decode other `Coding` objects, including lists of `Coding` objects and maps where `Coding` objects are values. You must provide a closure that instantiates the `Coding` object being decoded.

```dart
class Team extends Coding {

  List<Person> members;
  Person manager;

  @override
  void decode(KeyedArchive object) {
    super.decode(object); // must call super

    members = object.decodeObjects("members", () => Person());
    manager = object.decodeObject("manager", () => Person());
  }

  @override
  void encode(KeyedArchive object) {
    object.encodeObject("manager", manager);
    object.encodeObjects("members", members);
  }
}
```

## Dynamic Type Casting 

Types with primitive type arguments (e.g., `List<String>` or `Map<String, int>`) are a particular pain point when decoding. Override `castMap` in `Coding` to perform type coercion.
You must import `package:codable/cast.dart as cast` and prefix type names with `cast`.

```dart
import 'package:codable/cast.dart' as cast;
class Container extends Coding {  
  List<String> things;

  @override
  Map<String, cast.Cast<dynamic>> get castMap => {
    "things": cast.List(cast.String)
  };
  

  @override
  void decode(KeyedArchive object) {
    super.decode(object);

    things = object.decode("things");
  }

  @override
  void encode(KeyedArchive object) {
    object.encode("things", things);
  }
}

``` 


## Document References

`Coding` objects may be referred to multiple times in a document without duplicating their structure. An object is referenced with the `$key` key. 
For example, consider the following JSON: 

```json
{
  "components": {
    "thing": {
      "name": "The Thing"
    }    
  },
  "data": {
    "$ref": "#/components/thing"
  }
}
```

In the above, the decoded value of `data` inherits all properties from `/components/thing`:

```json
{
  "$ref": "#/components/thing",
  "name": "The Thing"
}
```

You may create references in your in-memory data structures through the `Coding.referenceURI`. 

```dart
final person = Person()..referenceURI = Uri(path: "/teams/engineering/manager");
```

The above person is encoded as:

```json
{
  "$ref": "#/teams/engineering/manager"
}
```

You may have cyclical references.

See the specification for [JSON Schema](http://json-schema.org) and the `$ref` keyword for more details.


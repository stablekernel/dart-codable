# codable
 
[![Build Status](https://travis-ci.org/stablekernel/dart-codable.svg?branch=master)](https://travis-ci.org/stablekernel/dart-codable)

A library for encoding and decoding dynamic data into Dart objects.

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
final person = new Person()..decode(archive);
```

`Coding` objects can encode or decode other `Coding` objects.

```dart
class Team extends Coding {

  List<Person> members;
  Person manager;

  @override
  void decode(KeyedArchive object) {
    // must call super
    super.decode(object);

    members = object.decodeObjectList("members");
    manager = object.decodeObject("manager");
  }

  @override
  void encode(KeyedArchive object) {
    object.encodeObject("manager", manager);
    object.encodeObjectList("members", members);
  }
}
```

`Coding` objects may be referred to multiple times in a document without duplicating their structure. See the specification for [JSON Schema](http://json-schema.org) and the `$ref` keyword for more details.

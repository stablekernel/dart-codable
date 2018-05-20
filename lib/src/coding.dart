import 'package:codable/src/keyed_archive.dart';
import 'package:meta/meta.dart';

abstract class Coding {
  Uri referenceURI;

  @mustCallSuper
  void decode(KeyedArchive object) {
    referenceURI = object.referenceURI;
  }

  // would prefer to write referenceURI to object here, but see note in KeyedArchive._encodedObject
  @mustCallSuper
  void encode(KeyedArchive object);

}
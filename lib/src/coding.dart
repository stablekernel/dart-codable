import 'package:codable/src/keyed_archive.dart';
import 'package:meta/meta.dart';

abstract class Coding {
  Uri referenceURI;
  Map<String, dynamic> get castMap => null;

  @mustCallSuper
  void decode(KeyedArchive object) {
    referenceURI = object.referenceURI;
    object.castValues(castMap);
  }

  // would prefer to write referenceURI to object here, but see note in KeyedArchive._encodedObject
  void encode(KeyedArchive object);

}
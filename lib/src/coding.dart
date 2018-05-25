import 'package:codable/src/keyed_archive.dart';
import 'package:meta/meta.dart';
import 'package:codable/cast.dart' as cast;

/// A base class for encodable and decodable objects.
///
/// Types that can read or write their values to a document should extend this abstract class.
/// By overriding [decode] and [encode], an instance of this type will read or write its values
/// into a data container that can be transferred into formats like JSON or YAML.
abstract class Coding {
  Uri referenceURI;
  Map<String, cast.Cast<dynamic>> get castMap => null;

  @mustCallSuper
  void decode(KeyedArchive object) {
    referenceURI = object.referenceURI;
    object.castValues(castMap);
  }

  // would prefer to write referenceURI to object here, but see note in KeyedArchive._encodedObject
  void encode(KeyedArchive object);

}
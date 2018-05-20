import 'package:codable/src/keyed_archive.dart';

class KeyResolver {
  KeyResolver(this.document);

  final KeyedArchive document;

  KeyedArchive resolve(Uri ref) {
    return ref.pathSegments.fold(document, (objectPtr, pathSegment) {
      return objectPtr[pathSegment];
    });
  }
}
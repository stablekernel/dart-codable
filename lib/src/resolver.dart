import 'package:codable/src/keyed_archive.dart';

class ReferenceResolver {
  ReferenceResolver(this.document);

  final KeyedArchive document;

  KeyedArchive resolve(Uri ref) {
    return ref.pathSegments.fold(document, (objectPtr, pathSegment) {
      return objectPtr[pathSegment] as Map<String, dynamic>;
    }) as KeyedArchive;
  }
}
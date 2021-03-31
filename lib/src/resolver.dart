import 'package:conduit_codable/src/keyed_archive.dart';

class ReferenceResolver {
  ReferenceResolver(this.document);

  final KeyedArchive document;

  KeyedArchive? resolve(Uri ref) {
    var folded = ref.pathSegments.fold<KeyedArchive?>(document,
        (KeyedArchive? objectPtr, pathSegment) {
      if (objectPtr != null)
        return objectPtr[pathSegment]; //  as Map<String, dynamic>;
      else
        return null;
    });

    return folded;
  }
}

import 'package:codable/src/resolver.dart';

abstract class Referencable {
  void resolveOrThrow(ReferenceResolver resolver);
}
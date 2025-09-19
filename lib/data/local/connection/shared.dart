// lib/data/local/connection/shared.dart
export 'unsupported.dart'
    if (dart.library.html) 'web.dart'
    if (dart.library.io) 'native.dart';
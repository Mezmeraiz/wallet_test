import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

extension Uint8ListBlobConversion on Uint8List {
  Pointer<Uint8> toPointerUint8() {
    final blob = calloc<Uint8>(length);
    final blobBytes = blob.asTypedList(length);
    blobBytes.setAll(0, this);
    return blob;
  }
}

extension CharPointer on Pointer<Char> {
  int get length {
    _ensureNotNullptr('length');
    final codeUnits = cast<Uint8>();
    return _length(codeUnits);
  }

  String toDartString({int? length}) {
    _ensureNotNullptr('toDartString');
    final codeUnits = cast<Uint8>();
    if (length != null) {
      RangeError.checkNotNegative(length, 'length');
    } else {
      length = _length(codeUnits);
    }
    return utf8.decode(codeUnits.asTypedList(length));
  }

  static int _length(Pointer<Uint8> codeUnits) {
    var length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }
    return length;
  }

  void _ensureNotNullptr(String operation) {
    if (this == nullptr) {
      throw UnsupportedError("Operation '$operation' not allowed on a 'nullptr'.");
    }
  }
}

extension StringCharPointer on String {
  /// Creates a zero-terminated [Utf8] code-unit array from this String.
  ///
  /// If this [String] contains NUL characters, converting it back to a string
  /// using [Utf8Pointer.toDartString] will truncate the result if a length is
  /// not passed.
  ///
  /// Unpaired surrogate code points in this [String] will be encoded as
  /// replacement characters (U+FFFD, encoded as the bytes 0xEF 0xBF 0xBD) in
  /// the UTF-8 encoded result. See [Utf8Encoder] for details on encoding.
  ///
  /// Returns an [allocator]-allocated pointer to the result.
  Pointer<Char> toNativeChar({Allocator allocator = malloc}) {
    final units = utf8.encode(this);
    final Pointer<Uint8> result = allocator<Uint8>(units.length + 1);
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}

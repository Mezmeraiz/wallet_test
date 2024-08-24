import 'package:flutter/material.dart';
import 'package:http_interceptor/http/http.dart';
import 'package:wallet_test/data/library_storage.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';
import 'package:wallet_test/ffi_impl/generated_bindings.dart';

class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required super.child,
    required this.libraryStorage,
    required this.walletRepository,
    required this.core,
    required this.http,
  });

  final LibraryStorage libraryStorage;
  final WalletRepository walletRepository;
  final TrustWalletCore core;
  final InterceptedHttp http;

  static DependencyScope of(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<DependencyScope>()!.widget as DependencyScope;

  @override
  bool updateShouldNotify(DependencyScope oldWidget) => false;
}

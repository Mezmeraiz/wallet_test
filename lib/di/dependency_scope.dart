import 'package:flutter/material.dart';
import 'package:wallet_test/data/library_storage.dart';
import 'package:wallet_test/data/repository/wallet_repository.dart';

class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required super.child,
    required this.libraryStorage,
    required this.walletRepository,
  });

  final LibraryStorage libraryStorage;
  final WalletRepository walletRepository;

  static DependencyScope of(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<DependencyScope>()!.widget as DependencyScope;
  }

  @override
  bool updateShouldNotify(DependencyScope oldWidget) => false;
}

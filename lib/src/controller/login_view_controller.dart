import 'dart:async';

import 'package:cord_hearing/src/core/services/firebase_auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginViewControllerProvider = AutoDisposeAsyncNotifierProvider<LoginViewController, void>(
  LoginViewController.new,
);

class LoginViewController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is just a successful void state.
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(email, password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

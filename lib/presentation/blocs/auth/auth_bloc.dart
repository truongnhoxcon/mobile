import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);

    // Listen to auth state changes
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(AuthState.authenticated(user));
      } else {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(const AuthState.unauthenticated());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await _authRepository.getCurrentUser();
    
    result.fold(
      (failure) => emit(const AuthState.unauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthState.authenticated(user));
        } else {
          emit(const AuthState.unauthenticated());
        }
      },
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await _authRepository.signInWithEmail(
      email: event.email,
      password: event.password,
    );
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await _authRepository.signUpWithEmail(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    
    final result = await _authRepository.signInWithGoogle();
    
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    await _authRepository.signOut();
    emit(const AuthState.unauthenticated());
  }
}

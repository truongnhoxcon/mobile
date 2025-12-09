import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);
  
  const AuthState.loading() : this(status: AuthStatus.loading);
  
  const AuthState.authenticated(User user) 
      : this(status: AuthStatus.authenticated, user: user);
  
  const AuthState.unauthenticated() 
      : this(status: AuthStatus.unauthenticated);
  
  const AuthState.error(String message) 
      : this(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => user?.role == UserRole.admin;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}

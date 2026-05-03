import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInWithEmailUseCase _signInWithEmail;
  final SignUpWithEmailUseCase _signUpWithEmail;
  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignOutUseCase _signOut;
  final DeleteAccountUseCase _deleteAccount;
  final GetCurrentUserUseCase _getCurrentUser;

  AuthCubit({
    required SignInWithEmailUseCase signInWithEmail,
    required SignUpWithEmailUseCase signUpWithEmail,
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignOutUseCase signOut,
    required DeleteAccountUseCase deleteAccount,
    required GetCurrentUserUseCase getCurrentUser,
  }) : _signInWithEmail = signInWithEmail,
       _signUpWithEmail = signUpWithEmail,
       _signInWithGoogle = signInWithGoogle,
       _signOut = signOut,
       _deleteAccount = deleteAccount,
       _getCurrentUser = getCurrentUser,
       super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    final result = await _getCurrentUser(const NoParams());
    result.fold((failure) => emit(Unauthenticated()), (user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    final result = await _signInWithEmail(
      SignInWithEmailParams(email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> signUpWithEmail(String email, String password) async {
    emit(AuthLoading());
    final result = await _signUpWithEmail(
      SignUpWithEmailParams(email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    final result = await _signInWithGoogle(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    final result = await _signOut(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }

  Future<void> deleteAccount() async {
    emit(AuthLoading());
    final result = await _deleteAccount(const NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(Unauthenticated()),
    );
  }
}

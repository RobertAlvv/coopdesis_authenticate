part of 'coopdesis_authenticate.dart';

@immutable
abstract class AuthState {
  final AuthModel? user;
  final StatusConnetion statusConnetion;

  const AuthState({this.user, required this.statusConnetion});
}

class AuthInitState extends AuthState {
  const AuthInitState()
      : super(user: null, statusConnetion: StatusConnetion.disconnected);
}

class AuthAnonymousLoginState extends AuthState {
  @override
  final AuthModel user;

  const AuthAnonymousLoginState(this.user)
      : super(user: user, statusConnetion: StatusConnetion.anonymousLogin);
}

class AuthAnonymousQRState extends AuthState {
  @override
  final AuthModel user;

  const AuthAnonymousQRState(this.user)
      : super(user: user, statusConnetion: StatusConnetion.anonymousQR);
}

class AuthWaitingState extends AuthState {
  @override
  final AuthModel? user;

  const AuthWaitingState({this.user})
      : super(user: user, statusConnetion: StatusConnetion.waiting);
}

class AuthAnonymousEstablishedState extends AuthState {
  @override
  final AuthModel user;

  const AuthAnonymousEstablishedState(this.user)
      : super(
            statusConnetion: StatusConnetion.anonymousEstablished, user: user);
}

class AuthEstablishedState extends AuthState {
  @override
  final AuthModel user;

  const AuthEstablishedState(this.user)
      : super(statusConnetion: StatusConnetion.established, user: user);
}

part of 'coopdesis_authenticate.dart';

@immutable
abstract class AuthEvent {}

class AuthEstablishedEvent extends AuthEvent {
  final AuthModel user;

  AuthEstablishedEvent({required this.user});
}

class AuthAnonymousEstablishedEvent extends AuthEvent {
  final AuthModel user;

  AuthAnonymousEstablishedEvent({required this.user});
}

class AuthAnonymousLoginEvent extends AuthEvent {
  final AuthModel anonymousUser;

  AuthAnonymousLoginEvent({required this.anonymousUser});
}

class AuthAnonymousQREvent extends AuthEvent {
  final AuthModel anonymousUser;

  AuthAnonymousQREvent({required this.anonymousUser});
}

class LogoutAuthEvent extends AuthEvent {}

class AuthWaitingEvent extends AuthEvent {
  final AuthModel? user;

  AuthWaitingEvent({this.user});
}

import 'package:equatable/equatable.dart';

class AuthModel extends Equatable {
  AuthModel({required this.uid, required this.userBackendAutenticate});

  final String uid;
  final bool userBackendAutenticate;

  @override
  List<Object> get props => [uid];

  AuthModel copyWith({
    String? uid,
    bool? userBackendAutenticate,
  }) =>
      AuthModel(
        uid: uid ?? this.uid,
        userBackendAutenticate:
            userBackendAutenticate ?? this.userBackendAutenticate,
      );
}

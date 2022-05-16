import 'package:bloc/bloc.dart';
import 'package:coopdesis_authenticate/auth_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

part 'auth_event.dart';
part 'auth_state.dart';

enum StatusConnetion {
  disconnected,
  waiting,
  anonymousLogin,
  anonymousQR,
  anonymousEstablished,
  established,
}

class Nav {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static navigatorPush(String route) {
    Nav.navigatorKey.currentState!.pushNamed(route);
  }

  static navigatorPop() {
    Nav.navigatorKey.currentState!.pop();
  }

  static navigatorReplacementName(String route) {
    Nav.navigatorKey.currentState!.pushReplacementNamed(route);
  }

  static navigatorPopAndPush(String route) {
    Nav.navigatorKey.currentState!.popAndPushNamed(route);
  }
}

class CoopdesisAuthenticate extends Bloc<AuthEvent, AuthState> {
  CoopdesisAuthenticate() : super(const AuthWaitingState());

  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final Connectivity _connectivity = Connectivity();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _databaseInstance = FirebaseDatabase.instance;

  Future<void> _writeTokenToLocalStorage({
    required String key,
    required String value,
  }) async =>
      await _storage.write(key: 'custom-token', value: value);

  Future<String?> _readTokenFromLocalStorage({
    required String key,
  }) async =>
      await _storage.read(key: key);

  //Valida si el usuario tiene conexion a internet, verifica si tiene UID almacenado en el storage
  Future<void> initConfig() async {
    //Verifica si el usuario tiene conexion a internet
    if (await _connectivity.checkConnectivity() == ConnectivityResult.none) {
      _storage.delete(key: 'custom-token');
      add(LogoutAuthEvent());
      return;
    }

    //Lee el UID en el storage
    final String? uid = await _readTokenFromLocalStorage(key: 'custom-token');

    //Si el storage existe establecera una conexion
    if (uid != null) {
      add(
        AuthWaitingEvent(
          user: AuthModel(
              uid: uid,
              userBackendAutenticate:
                  state.user?.userBackendAutenticate ?? false),
        ),
      );

      //FIXME: BUSCAR OTRA ALTERNATIVA AL FUTURE.DELAYED EL CUAL SE ENCUENTRA PUESTO PORQUE
      // EL METODO ADD() NO SE ESTA EJECUTANDO COMPLETAMENTE ANTES DE ENTRAR AL METODO
      // ESTABLISHEDCONNECTION()
      await Future.delayed(const Duration(microseconds: 1));
      listenerAnonymousConnection();

      //Si el storage no existe crea una nueva conexion anonima
    } else {
      refreshConnectionAnonymous();
    }
  }

  //Crea un usuario basado en la conexion anonima
  Future<void> refreshConnectionAnonymous() async {
    //Se logea a firebase de ser necesario y genera un UID cada vez que se llama
    final UserCredential? userAno = await _auth.signInAnonymously();

    AuthModel user = AuthModel(
        uid: userAno!.credential!.token.toString(),
        userBackendAutenticate: false);

    if (user == null) {
      add(LogoutAuthEvent());
      return;
    }

    if (state.statusConnetion == StatusConnetion.anonymousQR) {
      add(AuthAnonymousQREvent(anonymousUser: user));
    } else {
      add(AuthAnonymousLoginEvent(anonymousUser: user));
    }
    await Future.delayed(const Duration(microseconds: 1));
  }

  // Se mantendra escuchando la conexion en firebase.
  Future<void> listenerAnonymousConnection({String? routeName}) async {
    //Listener que escucha si se inserto una nueva sesion con el token
    //o si aun hay una sesion activa con ese token
    _databaseInstance
        .ref("/terminales")
        .orderByChild('session')
        .equalTo(state.user!.uid)
        .onValue
        .listen((event) async {
      if (!event.snapshot.exists) {
        //Si la aplicacion inicia con un uid almacenado y ese uid no existe en firebase,
        //eliminara el uid del storage y lo deslogueara
        if (state.statusConnetion == StatusConnetion.waiting) {
          await _storage.delete(key: 'custom-token');
          add(LogoutAuthEvent());
        }
        //Si la aplicacion inicia anonima de una terminal y el usuario decide volver atras,
        //O si se borra el uid en firebase, eliminara el uid del storage y lo deslogueara
        else if (state.statusConnetion ==
            StatusConnetion.anonymousEstablished) {
          await _storage.delete(key: 'custom-token');
          add(LogoutAuthEvent());
        }
        //Si se borra el uid en firebase, eliminara el uid del storage y deslogueara al usuario
        else if (state.statusConnetion == StatusConnetion.established) {
          await _storage.delete(key: 'custom-token');
          add(LogoutAuthEvent());
          Nav.navigatorReplacementName(routeName!);
        }
      } else {
        final currentSession =
            event.snapshot.children.first.child("session").value.toString();

        //Se inserta el uid a firebase, lo almacena en el storage y cambia el estado para entrar al homeScreen
        if (event.snapshot.exists && currentSession != state.user!.uid) {
          add(AuthAnonymousEstablishedEvent(user: state.user!));
          await _writeTokenToLocalStorage(
              key: 'custom-token', value: state.user!.uid);

          //Si el usuario tiene una conexion valida en firebase le permitira
          //entrar a la aplicacion
        } else if (event.snapshot.exists && currentSession == state.user!.uid) {
          add(AuthEstablishedEvent(user: state.user!));
          await _writeTokenToLocalStorage(
              key: 'custom-token', value: state.user!.uid);
        }
      }
    });
  }

  void lock() {
    add(AuthAnonymousEstablishedEvent(user: state.user!));
  }

  Future<bool> loginUser() async {
    //TODO: Llamar el servicio que hara la peticion al backend para
    //conectar al usuario con el usuario y el pin

    add(AuthEstablishedEvent(
        user: state.user!.copyWith(userBackendAutenticate: true)));
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  //Deslogueara al usuario si este lo desea
  Future<void> logoutUser() async {
    //Busca en firebase el usuario logueado.
    final data = await _databaseInstance
        .ref('/terminales')
        .orderByChild('session')
        .equalTo(state.user!.uid)
        .onValue
        .first;

    //Limpia el token en firebase
    _databaseInstance
        .ref("/terminales/${data.snapshot.children.first.key}")
        .child("session")
        .set("");

    //Elimina el token del storage
    await _storage.delete(key: 'custom-token');

    //Se desloguea la sesion anonima
    await _auth.signOut();
  }

  void switchLoginQr() {
    if (state.statusConnetion == StatusConnetion.anonymousLogin) {
      add(AuthAnonymousQREvent(anonymousUser: state.user!));
    } else if (state.statusConnetion == StatusConnetion.anonymousQR) {
      add(AuthAnonymousLoginEvent(anonymousUser: state.user!));
    }
  }
}

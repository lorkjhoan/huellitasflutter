import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registrar usuario con correo, contraseña y datos adicionales (teléfono)
  Future<String?> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    try {
      // 1. Crea el usuario de forma segura en Firebase Auth (cifra la contraseña automáticamente)
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // 2. Guarda los datos extendidos en Firestore (aquí se crean las colecciones automáticamente)
      await _firestore.collection('usuarios').doc(uid).set({
        'uid': uid,
        'email': email,
        'nombre': nombre,
        'telefono': telefono,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      return null; // Éxito (sin errores)
    } catch (e) {
      return e.toString(); // Retorna el mensaje de error si algo falla
    }
  }

  // Iniciar sesión
  Future<String?> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Éxito
    } catch (e) {
      return e.toString();
    }
  }
}

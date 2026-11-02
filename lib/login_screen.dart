import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool esRegistro = false;

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _celularController =
      TextEditingController(); // Nuevo controlador para el celular
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _mensajeError = '';

  Future<void> _enviarFormulario() async {
    setState(() {
      _isLoading = true;
      _mensajeError = '';
    });

    try {
      if (esRegistro) {
        // 1. Registro en Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // 2. Guardar datos adicionales en Firestore (Incluyendo celular)
        String uid = userCredential.user!.uid;
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
          'uid': uid,
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'celular': _celularController.text.trim(),
          'email': _emailController.text.trim(),
          'creadoEn': FieldValue.serverTimestamp(),
        });
      } else {
        // 1. Inicio de sesión en Firebase Auth
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      // Traducción personalizada de errores de Firebase a Español
      String mensajeTraducido = 'Ocurrió un error en la autenticación.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        mensajeTraducido = 'Correo o contraseña incorrectos.';
      } else if (e.code == 'email-already-in-use') {
        mensajeTraducido = 'Este correo electrónico ya está registrado.';
      } else if (e.code == 'weak-password') {
        mensajeTraducido =
            'La contraseña es demasiado débil (mínimo 6 caracteres).';
      }

      setState(() {
        _mensajeError = mensajeTraducido;
      });
    } catch (e) {
      setState(() {
        _mensajeError = 'Error inesperado: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          esRegistro
              ? '📝 Crear Cuenta - Huellitas'
              : '🔑 Iniciar Sesión - Huellitas',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, size: 70, color: Colors.teal),
                const SizedBox(height: 15),
                Text(
                  esRegistro
                      ? 'Regístrate en Huellitas'
                      : 'Bienvenido de nuevo',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),

                // Campos adicionales solo si es Registro
                if (esRegistro) ...[
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _apellidoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _celularController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Número de Celular',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                if (_mensajeError.isNotEmpty)
                  Text(
                    _mensajeError,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _enviarFormulario,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            esRegistro ? 'Registrarse e Ingresar' : 'Ingresar',
                            style: const TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    setState(() {
                      esRegistro = !esRegistro;
                      _mensajeError = '';
                    });
                  },
                  child: Text(
                    esRegistro
                        ? '¿Ya tienes una cuenta? Inicia sesión aquí'
                        : '¿No tienes cuenta? Regístrate aquí',
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

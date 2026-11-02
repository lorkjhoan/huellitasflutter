import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io'; // Necesario para manejar archivos locales en Flutter

import 'package:flutter/foundation.dart'; // Para detectar si corre en Web o Móvil

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'tarjeta_mascota.dart';
import 'login_screen.dart'; // Importamos la pantalla de login
import 'mensajes_screen.dart';
import 'perfil_screen.dart';

void main() async {
  // 1. Inicialización obligatoria de los servicios nativos de Flutter y Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HuellitasApp());
}

class HuellitasApp extends StatelessWidget {
  const HuellitasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Huellitas PWA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DocumentSnapshot> mascotas =
      []; // Cambiado para almacenar los documentos completos
  bool isLoading = true;
  String filtroSeleccionado = 'Todos';
  bool usuarioAutenticado = false;

  @override
  void initState() {
    super.initState();
    verificarSesion();
    obtenerMascotas();
  }

  // Verifica si hay un usuario activo en Firebase Auth
  void verificarSesion() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      usuarioAutenticado = user != null;
    });
  }

  // Obtiene los reportes directamente desde Cloud Firestore
  Future<void> obtenerMascotas() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('mascotas')
          .orderBy('creadoEn', descending: true)
          .get();

      setState(() {
        mascotas = querySnapshot.docs; // Guardamos los documentos directamente
        isLoading = false;
      });
    } catch (e) {
      print('Error conectando a Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Manejar Login / Logout desde el AppBar con Firebase
  void gestionarSesion() async {
    if (usuarioAutenticado) {
      // Cerrar sesión en Firebase
      await FirebaseAuth.instance.signOut();
      setState(() {
        usuarioAutenticado = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión cerrada correctamente')),
        );
      }
    } else {
      // Ir a la pantalla de Login y esperar resultado
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      // Si el login fue exitoso, actualizamos el estado
      if (resultado == true) {
        verificarSesion();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Bienvenido! Has iniciado sesión')),
          );
        }
      }
    }
  }

  // Modal para crear reporte y guardarlo en Cloud Firestore
  void mostrarModalReporte() {
    final nombreController = TextEditingController();
    String estadoSeleccionado = 'Perdido';
    final descController = TextEditingController();
    XFile? imagenSeleccionada; // Variable temporal para la imagen

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Crear Reporte de Mascota',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la mascota / Referencia',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: estadoSeleccionado,
                      items: ['Perdido', 'Adopción', 'Encontrado']
                          .map(
                            (estado) => DropdownMenuItem(
                              value: estado,
                              child: Text(estado),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) estadoSeleccionado = val;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Clasificación / Estado',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción o ubicación',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Botón y Vista previa de la imagen
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (image != null) {
                              setStateModal(() {
                                imagenSeleccionada = image;
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Añadir Foto'),
                        ),
                        const SizedBox(width: 12),
                        if (imagenSeleccionada != null)
                          const Text(
                            '¡Foto seleccionada! ✅',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          if (nombreController.text.isEmpty ||
                              descController.text.isEmpty) {
                            return;
                          }

                          try {
                            User? user = FirebaseAuth.instance.currentUser;
                            String nombreAutor = 'Anónimo';

                            // 1. Buscamos el nombre del usuario actual en la colección 'usuarios'
                            if (user != null) {
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(user.uid)
                                  .get();

                              if (userDoc.exists) {
                                final dataUser = userDoc.data();
                                final nombre = dataUser?['nombre'] ?? '';
                                final apellido = dataUser?['apellido'] ?? '';
                                nombreAutor = '$nombre $apellido'.trim();
                                if (nombreAutor.isEmpty) {
                                  nombreAutor = user.email ?? 'Usuario';
                                }
                              }
                            }

                            String imagenBase64 = '';

                            // 2. Convertir la imagen seleccionada a Texto Base64 (si el usuario eligió una foto)
                            if (imagenSeleccionada != null) {
                              Uint8List bytes = await imagenSeleccionada!
                                  .readAsBytes();
                              imagenBase64 = base64Encode(bytes);
                            }

                            // 3. Guardar el reporte en Firestore con todos los datos
                            await FirebaseFirestore.instance
                                .collection('mascotas')
                                .add({
                                  'nombre': nombreController.text,
                                  'estado': estadoSeleccionado,
                                  'descripcion': descController.text,
                                  'usuarioId': user?.uid ?? 'desconocido',
                                  'autorNombre': nombreAutor,
                                  'imagenBase64': imagenBase64, // Guardamos la foto en texto plano
                                  'creadoEn': FieldValue.serverTimestamp(),
                                });

                            // =========================================================================
                            // 🐾 4. ¡AQUÍ CREAMOS LA NOTIFICACIÓN AUTOMÁTICA DEL NUEVO REPORTE!
                            // =========================================================================
                            await FirebaseFirestore.instance
                                .collection('notificaciones')
                                .add({
                                  'usuarioId': user?.uid ?? 'todos', // Si deseas que sea general o dirigida
                                  'titulo': '🐾 ¡Nuevo Reporte Publicado!',
                                  'mensaje':
                                      '$nombreAutor ha reportado a: ${nombreController.text} ($estadoSeleccionado)',
                                  'leida': false,
                                  'creadoEn': FieldValue.serverTimestamp(),
                                });

                            if (mounted) Navigator.pop(context);
                            obtenerMascotas(); // Recarga la lista en pantalla

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '¡Reporte publicado con éxito!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            print('Error al guardar en Firestore: $e');
                          }
                        },
                        child: const Text('Guardar Reporte'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot> mascotasFiltradas = mascotas.where((doc) {
      if (filtroSeleccionado == 'Todos') return true;
      final data = doc.data() as Map<String, dynamic>?;
      return data?['estado'] == filtroSeleccionado;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 Huellitas - Alertas y Adopción'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (usuarioAutenticado) ...[
            // ==========================================
            // 1. BOTÓN MI PERFIL
            // ==========================================
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerfilScreen()),
                );
              },
              icon: const Icon(Icons.person, color: Colors.black87),
              label: const Text(
                'Mi Perfil',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // ==========================================
            // 2. BOTÓN MIS MENSAJES CON BADGE DE NÚMEROS
            // ==========================================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mensajes')
                  .where(
                    'destinatarioId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                  )
                  .where('leido', isEqualTo: false)
                  .snapshots(),
              builder: (context, mensajeSnapshot) {
                int mensajesNoLeidos = 0;
                if (mensajeSnapshot.hasData) {
                  mensajesNoLeidos = mensajeSnapshot.data!.docs.length;
                }

                return TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MensajesScreen(),
                      ),
                    );
                  },
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.message, color: Colors.black87),
                      if (mensajesNoLeidos > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$mensajesNoLeidos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: const Text(
                    'Mis Mensajes',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),

            // ==========================================
            // 3. CAMPANITA DE NOTIFICACIONES CON MENÚ DESPLEGABLE
            // ==========================================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notificaciones')
                  .where('leida', isEqualTo: false)
                  .snapshots(),
              builder: (context, notifSnapshot) {
                int noLeidasCount = 0;
                if (notifSnapshot.hasData) {
                  noLeidasCount = notifSnapshot.data!.docs.length;
                }

                return PopupMenuButton<String>(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications,
                        color: Colors.black87,
                        size: 26,
                      ),
                      if (noLeidasCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$noLeidasCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  offset: const Offset(0, 45),
                  itemBuilder: (BuildContext context) {
                    if (!notifSnapshot.hasData ||
                        notifSnapshot.data!.docs.isEmpty) {
                      return [
                        const PopupMenuItem<String>(
                          enabled: false,
                          child: Text(
                            'No tienes notificaciones nuevas',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ];
                    }

                    return notifSnapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final titulo = data['titulo'] ?? 'Notificación';
                      final mensaje = data['mensaje'] ?? '';

                      return PopupMenuItem<String>(
                        value: doc.id,
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('notificaciones')
                              .doc(doc.id)
                              .update({'leida': true});
                        },
                        child: SizedBox(
                          width: 260,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.teal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mensaje,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(height: 10),
                            ],
                          ),
                        ),
                      );
                    }).toList();
                  },
                );
              },
            ),
          ],

          // ==========================================
          // 4. BOTÓN DE INICIAR / CERRAR SESIÓN
          // ==========================================
          TextButton.icon(
            onPressed: gestionarSesion,
            icon: Icon(
              usuarioAutenticado ? Icons.logout : Icons.login,
              color: Colors.black87,
            ),
            label: Text(
              usuarioAutenticado ? 'Cerrar Sesión' : 'Iniciar Sesión',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Todos', 'Perdido', 'Adopción', 'Encontrado'].map((
                  filtro,
                ) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(filtro),
                      selected: filtroSeleccionado == filtro,
                      onSelected: (selected) {
                        setState(() {
                          filtroSeleccionado = filtro;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : mascotasFiltradas.isEmpty
                ? const Center(child: Text('No hay reportes en esta categoría'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: mascotasFiltradas.length,
                    itemBuilder: (context, index) {
                      final documento = mascotasFiltradas[index];
                      final data = documento.data() as Map<String, dynamic>;

                      return TarjetaMascota(
                        mascota: data,
                        mascotaId: documento.id, // ID del documento requerido
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: usuarioAutenticado
          ? FloatingActionButton.extended(
              onPressed: mostrarModalReporte,
              label: const Text('Nuevo Reporte'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

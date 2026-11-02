import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? datosUsuario;
  bool isLoadingUsuario = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Cargar datos adicionales del usuario desde la colección 'usuarios'
  Future<void> _cargarDatosUsuario() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          datosUsuario = doc.data();
          isLoadingUsuario = false;
        });
      } else {
        setState(() {
          isLoadingUsuario = false;
        });
      }
    } catch (e) {
      print('Error al cargar perfil: $e');
      setState(() {
        isLoadingUsuario = false;
      });
    }
  }

  // Función para cambiar el estado de un reporte
  void _cambiarEstadoReporte(String mascotaId, String estadoActual) async {
    List<String> estados = ['Perdido', 'Adopción', 'Encontrado'];
    String? nuevoEstado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cambiar Estado del Reporte'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: estados.map((estado) {
              return ListTile(
                title: Text(estado),
                leading: Radio<String>(
                  value: estado,
                  groupValue: estadoActual,
                  onChanged: (val) => Navigator.pop(context, val),
                ),
                onTap: () => Navigator.pop(context, estado),
              );
            }).toList(),
          ),
        );
      },
    );

    if (nuevoEstado != null && nuevoEstado != estadoActual) {
      try {
        await FirebaseFirestore.instance
            .collection('mascotas')
            .doc(mascotaId)
            .update({'estado': nuevoEstado});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Estado actualizado con éxito!')),
          );
        }
      } catch (e) {
        print('Error al actualizar estado: $e');
      }
    }
  }

  // Función para eliminar un reporte
  void _eliminarReporte(String mascotaId) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reporte'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este reporte? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection('mascotas')
            .doc(mascotaId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte eliminado correctamente')),
          );
        }
      } catch (e) {
        print('Error al eliminar reporte: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(
          child: Text('Debes iniciar sesión para ver tu perfil.'),
        ),
      );
    }

    final nombre = datosUsuario?['nombre'] ?? '';
    final apellido = datosUsuario?['apellido'] ?? '';
    final celular =
        datosUsuario?['celular'] ??
        datosUsuario?['telefono'] ??
        'No registrado';
    final correo = user?.email ?? 'No disponible';
    final nombreCompleto = '$nombre $apellido'.trim().isEmpty
        ? 'Usuario Huellitas'
        : '$nombre $apellido';

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Mi Perfil y Mis Reportes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Tarjeta de Información Personal
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: isLoadingUsuario
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.teal,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreCompleto,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📧 $correo',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '📱 Celular: $celular',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '📋 Mis Reportes Publicados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Lista de reportes creados por el usuario actual
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mascotas')
                  .where('usuarioId', isEqualTo: user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No has publicado ningún reporte aún.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  );
                }

                final misReportes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: misReportes.length,
                  itemBuilder: (context, index) {
                    final doc = misReportes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final mascotaId = doc.id;
                    final nombreMascota = data['nombre'] ?? 'Sin nombre';
                    final estado = data['estado'] ?? 'Perdido';
                    final descripcion = data['descripcion'] ?? '';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.pets, color: Colors.white),
                        ),
                        title: Text(
                          nombreMascota,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Estado: $estado',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              descripcion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón para cambiar estado
                            IconButton(
                              icon: const Icon(
                                Icons.edit_note,
                                color: Colors.blue,
                              ),
                              tooltip: 'Cambiar Estado',
                              onPressed: () =>
                                  _cambiarEstadoReporte(mascotaId, estado),
                            ),
                            // Botón para eliminar
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar Reporte',
                              onPressed: () => _eliminarReporte(mascotaId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

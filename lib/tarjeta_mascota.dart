import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TarjetaMascota extends StatelessWidget {
  final Map<String, dynamic> mascota;
  final String mascotaId;

  const TarjetaMascota({
    super.key,
    required this.mascota,
    required this.mascotaId,
  });

  @override
  Widget build(BuildContext context) {
    Color colorEstado = Colors.teal;
    if (mascota['estado'] == 'Perdido') colorEstado = Colors.red;
    if (mascota['estado'] == 'Adopción') colorEstado = Colors.orange;
    if (mascota['estado'] == 'Encontrado') colorEstado = Colors.green;

    String? imagenBase64 = mascota['imagenBase64'];

    return InkWell(
      onTap: () {
        _mostrarDetalleReporte(context, colorEstado, imagenBase64);
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mascota['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      mascota['estado'] ?? 'Desconocido',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: colorEstado,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (imagenBase64 != null && imagenBase64.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(imagenBase64),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                mascota['descripcion'] ?? 'Sin descripción',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(
                          'Por: ${mascota['autorNombre'] ?? 'Desconocido'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Ver detalle 🔍',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleReporte(
    BuildContext context,
    Color colorEstado,
    String? imagenBase64,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mascota['nombre'] ?? 'Detalle del Reporte',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  mascota['estado'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                backgroundColor: colorEstado,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imagenBase64 != null && imagenBase64.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.black12,
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: Image.memory(
                        base64Decode(imagenBase64),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Descripción:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(mascota['descripcion'] ?? 'Sin descripción'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reportado por: ${mascota['autorNombre'] ?? 'Desconocido'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _mostrarDialogoMensaje(context);
              },
              icon: const Icon(Icons.chat),
              label: const Text('Responder / Contactar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoMensaje(BuildContext context) {
    final mensajeController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para enviar mensajes'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Contactar sobre ${mascota['nombre'] ?? 'la mascota'}'),
          content: TextField(
            controller: mensajeController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe tu mensaje (ej. ¡Hola! Me interesa adoptar o creo haber visto a tu mascota...)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (mensajeController.text.trim().isEmpty) return;

                try {
                  // Guardar el mensaje en la colección 'mensajes'
                  await FirebaseFirestore.instance.collection('mensajes').add({
                    'mascotaId': mascotaId,
                    'mascotaNombre': mascota['nombre'] ?? 'Mascota',
                    'remitenteId': user.uid,
                    'remitenteEmail': user.email ?? 'Usuario',
                    'remitenteNombre':
                        user.displayName ??
                        user.email?.split('@').first ??
                        'Usuario', // <--- Añadido
                    'destinatarioId': mascota['usuarioId'] ?? '',
                    'texto': mensajeController.text.trim(),
                    'creadoEn': FieldValue.serverTimestamp(),
                  });

                  // Crear la notificación para el autor del reporte
                  if (mascota['usuarioId'] != null &&
                      mascota['usuarioId'] != 'desconocido') {
                    await FirebaseFirestore.instance
                        .collection('notificaciones')
                        .add({
                          'usuarioId': mascota['usuarioId'],
                          'titulo':
                              'Nuevo mensaje sobre ${mascota['nombre'] ?? 'tu reporte'}',
                          'mensaje': 'Alguien te ha enviado un mensaje.',
                          'leida': false,
                          'creadoEn': FieldValue.serverTimestamp(),
                        });
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Mensaje enviado con éxito!'),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error al enviar mensaje: $e');
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
}

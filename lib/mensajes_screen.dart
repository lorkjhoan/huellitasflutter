import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_detalle_screen.dart';

class MensajesScreen extends StatelessWidget {
  const MensajesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Mensajes')),
        body: const Center(
          child: Text('Debes iniciar sesión para ver tus mensajes.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Mis Mensajes y Consultas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('mensajes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar mensajes: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No tienes mensajes o consultas aún.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final allDocs = snapshot.data!.docs;
          final misMensajes = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final rem = data['remitenteId'];
            final dest = data['destinatarioId'];
            return rem == user.uid || dest == user.uid;
          }).toList();

          if (misMensajes.isEmpty) {
            return const Center(
              child: Text(
                'No tienes mensajes o consultas aún.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          Map<String, Map<String, dynamic>> ultimosChats = {};

          misMensajes.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final Timestamp? tA = dataA['creadoEn'] as Timestamp?;
            final Timestamp? tB = dataB['creadoEn'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tA.compareTo(tB);
          });

          for (var doc in misMensajes) {
            final data = doc.data() as Map<String, dynamic>;
            final mascotaId = data['mascotaId'] ?? '';
            final mascotaNombre = data['mascotaNombre'] ?? 'Mascota';
            final remitenteId = data['remitenteId'] ?? '';
            final remitenteNombre =
                data['remitenteNombre'] ?? data['remitenteEmail'] ?? 'Usuario';
            final destinatarioId = data['destinatarioId'] ?? '';
            final bool leido = data['leido'] ?? true;

            final esMio = remitenteId == user.uid;
            final otroId = esMio ? destinatarioId : remitenteId;
            final claveConversacion = '$mascotaId-$otroId';

            final Timestamp? timestamp = data['creadoEn'] as Timestamp?;
            final DateTime fecha = timestamp?.toDate() ?? DateTime.now();

            // Verificamos si este mensaje específico es un mensaje no leído dirigido a mí
            final bool esNoLeidoParaMi =
                (!esMio && !leido && destinatarioId == user.uid);

            if (!esMio) {
              ultimosChats[claveConversacion] = {
                'mascotaId': mascotaId,
                'mascotaNombre': mascotaNombre,
                'otroUsuarioId': otroId,
                'otroUsuarioEmail': remitenteNombre,
                'texto': data['texto'] ?? '',
                'fecha': fecha,
                'tieneNoLeidos': esNoLeidoParaMi,
              };
            } else {
              if (!ultimosChats.containsKey(claveConversacion)) {
                ultimosChats[claveConversacion] = {
                  'mascotaId': mascotaId,
                  'mascotaNombre': mascotaNombre,
                  'otroUsuarioId': otroId,
                  'otroUsuarioEmail': 'Usuario',
                  'texto': data['texto'] ?? '',
                  'fecha': fecha,
                  'tieneNoLeidos': false,
                };
              } else {
                ultimosChats[claveConversacion]!['texto'] = data['texto'] ?? '';
                ultimosChats[claveConversacion]!['fecha'] = fecha;
                // Mantenemos el estado de no leído si ya lo tenía
                if (esNoLeidoParaMi) {
                  ultimosChats[claveConversacion]!['tieneNoLeidos'] = true;
                }
              }
            }
          }

          final listaChats = ultimosChats.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: listaChats.length,
            itemBuilder: (context, index) {
              final chat = listaChats[index];
              final mascotaNombre = chat['mascotaNombre'];
              final otroUsuarioEmail = chat['otroUsuarioEmail'];
              final texto = chat['texto'];
              final bool tieneNoLeidos = chat['tieneNoLeidos'] ?? false;

              return Card(
                elevation: tieneNoLeidos ? 4 : 1,
                // Fondo ligeramente verduzco/teal si tiene mensajes sin leer, blanco si ya se leyeron
                color: tieneNoLeidos ? Colors.teal.shade50 : Colors.white,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: tieneNoLeidos
                      ? BorderSide(color: Colors.teal.shade300, width: 1.5)
                      : BorderSide.none,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tieneNoLeidos
                        ? Colors.teal
                        : Colors.grey.shade400,
                    child: const Icon(Icons.pets, color: Colors.white),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sobre: $mascotaNombre',
                          style: TextStyle(
                            fontWeight: tieneNoLeidos
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: tieneNoLeidos
                                ? Colors.teal.shade900
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (tieneNoLeidos)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NUEVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Con: $otroUsuarioEmail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: tieneNoLeidos
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tieneNoLeidos ? Colors.black : Colors.black87,
                          fontWeight: tieneNoLeidos
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetalleScreen(
                          mascotaId: chat['mascotaId'],
                          mascotaNombre: mascotaNombre,
                          otroUsuarioId: chat['otroUsuarioId'],
                          otroUsuarioEmail: otroUsuarioEmail,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

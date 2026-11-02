import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatDetalleScreen extends StatefulWidget {
  final String mascotaId;
  final String mascotaNombre;
  final String otroUsuarioId;
  final String otroUsuarioEmail;

  const ChatDetalleScreen({
    super.key,
    required this.mascotaId,
    required this.mascotaNombre,
    required this.otroUsuarioId,
    required this.otroUsuarioEmail,
  });

  @override
  State<ChatDetalleScreen> createState() => _ChatDetalleScreenState();
}

class _ChatDetalleScreenState extends State<ChatDetalleScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _marcarMensajesComoLeidos();
  }

  // Marca como leídos los mensajes que nos envió el otro usuario en este chat
  void _marcarMensajesComoLeidos() async {
    if (currentUser == null) return;
    try {
      final noLeidosQuery = await FirebaseFirestore.instance
          .collection('mensajes')
          .where('mascotaId', isEqualTo: widget.mascotaId)
          .where('destinatarioId', isEqualTo: currentUser!.uid)
          .where('leido', isEqualTo: false)
          .get();

      for (var doc in noLeidosQuery.docs) {
        doc.reference.update({'leido': true});
      }
    } catch (e) {
      print('Error al marcar mensajes como leídos: $e');
    }
  }

  void _enviarMensaje() async {
    if (_mensajeController.text.trim().isEmpty || currentUser == null) return;

    final texto = _mensajeController.text.trim();
    _mensajeController.clear();

    try {
      await FirebaseFirestore.instance.collection('mensajes').add({
        'mascotaId': widget.mascotaId,
        'mascotaNombre': widget.mascotaNombre,
        'remitenteId': currentUser!.uid,
        'remitenteEmail': currentUser!.email ?? 'Usuario',
        'remitenteNombre':
            currentUser!.displayName ??
            currentUser!.email?.split('@').first ??
            'Usuario',
        'destinatarioId': widget.otroUsuarioId,
        'texto': texto,
        'leido':
            false, // <--- Importante: nace como no leído para el destinatario
        'creadoEn': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error al enviar respuesta: $e');
    }
  }

  String _formatearHora(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final fecha = timestamp.toDate();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Debes iniciar sesión.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.mascotaNombre, style: const TextStyle(fontSize: 16)),
            Text(
              'Chat con: ${widget.otroUsuarioEmail}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('mensajes')
                  .where('mascotaId', isEqualTo: widget.mascotaId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar chat: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay mensajes en este chat aún.'),
                  );
                }

                final docs = snapshot.data!.docs;

                final mensajesFiltrados = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rem = data['remitenteId'];
                  final dest = data['destinatarioId'];
                  return (rem == currentUser!.uid &&
                          dest == widget.otroUsuarioId) ||
                      (rem == widget.otroUsuarioId && dest == currentUser!.uid);
                }).toList();

                if (mensajesFiltrados.isEmpty) {
                  return const Center(
                    child: Text('Inicia la conversación respondiendo abajo.'),
                  );
                }

                mensajesFiltrados.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final Timestamp? tA = dataA['creadoEn'] as Timestamp?;
                  final Timestamp? tB = dataB['creadoEn'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: mensajesFiltrados.length,
                  itemBuilder: (context, index) {
                    final data =
                        mensajesFiltrados[index].data() as Map<String, dynamic>;
                    final esMio = data['remitenteId'] == currentUser!.uid;
                    final texto = data['texto'] ?? '';
                    final Timestamp? timestamp = data['creadoEn'] as Timestamp?;
                    final horaStr = _formatearHora(timestamp);

                    return Align(
                      alignment: esMio
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: esMio
                              ? Colors.teal.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              texto,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (horaStr.isNotEmpty)
                              Text(
                                horaStr,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
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
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu respuesta...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _enviarMensaje,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

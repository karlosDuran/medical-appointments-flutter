import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);

  Widget _buildAppointmentCard(
    BuildContext context,
    Map<String, dynamic> appointment,
    String docId,
  ) {
    final startTime = (appointment['start_time'] as Timestamp).toDate();
    final endTime = (appointment['end_time'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: appointment['status'] == 'cancelada'
                        ? Colors.red.shade100
                        : accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment['status'] == 'cancelada'
                        ? 'CANCELADA'
                        : 'AGENDADA',
                    style: TextStyle(
                      color: appointment['status'] == 'cancelada'
                          ? Colors.red.shade700
                          : primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(startTime),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              appointment['reason'] ?? 'Consulta Médica General',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: primaryColor),
                const SizedBox(width: 5),
                Text(
                  '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (appointment['status'] != 'cancelada')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.close, color: Colors.red.shade700),
                  label: Text(
                    'Cancelar Cita',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  onPressed: () => _showCancelDialog(context, docId),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Cancelación"),
        content: const Text("¿Estás seguro de que deseas cancelar esta cita?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              FirestoreService().cancelAppointment(docId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Sí, Cancelar",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text("Error: Usuario no autenticado."));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getAppointmentsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No tienes citas agendadas.",
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          // SOLUCIÓN: Ordenar la lista localmente para evitar el error del índice de Firestore
          final List<DocumentSnapshot> documents = snapshot.data!.docs;
          documents.sort((a, b) {
            final aTime = (a.get('start_time') as Timestamp).toDate();
            final bTime = (b.get('start_time') as Timestamp).toDate();
            // Orden descendente (más reciente primero)
            return bTime.compareTo(aTime);
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return _buildAppointmentCard(
                  context,
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

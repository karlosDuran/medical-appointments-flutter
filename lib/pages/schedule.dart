import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/firestore_service.dart';
import '../routes.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);

  // Variable para forzar reconstrucción del StreamBuilder
  int _refreshKey = 0;

  // Función onRefresh: se ejecuta al deslizar de arriba hacia abajo
  Future<void> _handleRefresh() async {
    // Espera más tiempo para que el indicador sea MÁS visible
    await Future.delayed(const Duration(milliseconds: 1500));

    // Incrementa la key para forzar reconstrucción del StreamBuilder
    setState(() {
      _refreshKey++;
    });

    // Muestra confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Citas actualizadas'),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Map<String, dynamic> appointment,
    String docId,
  ) {
    final startTime = (appointment['start_time'] as Timestamp).toDate();
    final endTime = (appointment['end_time'] as Timestamp).toDate();

    // Slidable permite deslizar con límite y no vuelve automáticamente
    return Slidable(
      key: Key(docId),
      // endActionPane: botones que aparecen al deslizar a la izquierda
      endActionPane: ActionPane(
        // motion: controla cómo se mueven los botones
        motion:
            const ScrollMotion(), // los botones se mueven junto con la tarjeta
        // extentRatio: controla cuánto se puede deslizar (0.0 a 1.0)
        extentRatio:
            0.35, // limita el deslizamiento al 35% del ancho (más espacio para los íconos)
        children: [
          // Botón de Editar
          CustomSlidableAction(
            onPressed: (context) {
              Navigator.pushNamed(
                context,
                Routes.editAppointment,
                arguments: docId,
              );
            },
            backgroundColor: Colors.transparent, // fondo transparente
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          // Botón de Eliminar
          CustomSlidableAction(
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirmar Cancelación"),
                  content: const Text(
                    "¿Estás seguro de que deseas cancelar esta cita?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("No"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        "Sí, Cancelar",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirestoreService().cancelAppointment(docId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cita cancelada')),
                  );
                }
              }
            },
            backgroundColor: Colors.transparent, // fondo transparente
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      child: Card(
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
            ],
          ),
        ),
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
      body: RefreshIndicator(
        // onRefresh: función que se ejecuta al deslizar de arriba hacia abajo
        onRefresh: _handleRefresh,
        color: primaryColor, // Color del círculo que gira
        backgroundColor: Colors.white,
        strokeWidth: 3.0, // Grosor del círculo
        displacement: 40.0, // Distancia desde el borde superior
        child: StreamBuilder<QuerySnapshot>(
          // key cambia cuando _refreshKey cambia, forzando reconstrucción
          key: ValueKey(_refreshKey),
          stream: FirestoreService().getAppointmentsStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              // Envuelve en ListView para que RefreshIndicator funcione
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Text(
                        'Error al cargar: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              // Envuelve en ListView para que RefreshIndicator funcione
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
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
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Desliza hacia abajo para actualizar",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final List<DocumentSnapshot> documents = snapshot.data!.docs;
            documents.sort((a, b) {
              final aTime = (a.get('start_time') as Timestamp).toDate();
              final bTime = (b.get('start_time') as Timestamp).toDate();
              return bTime.compareTo(aTime);
            });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                // Permite scroll incluso con pocos elementos (necesario para RefreshIndicator)
                physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}

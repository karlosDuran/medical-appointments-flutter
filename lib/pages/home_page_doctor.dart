import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePageDoctor extends StatelessWidget {
  const HomePageDoctor({super.key});

  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);
  final Color successColor = const Color(0xFF28A745);
  final Color warningColor = const Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(child: Text("Error: Usuario no autenticado."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del dashboard
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              String doctorName = "Doctor";
              if (snapshot.hasData && snapshot.data!.exists) {
                doctorName = snapshot.data!.get('name') ?? "Doctor";
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, Dr. $doctorName',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Panel de Control',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 25),

          // Tarjetas de estadísticas
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctor_id', isEqualTo: userId)
                .snapshots(),
            builder: (context, appointmentsSnapshot) {
              if (appointmentsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final appointments = appointmentsSnapshot.data?.docs ?? [];
              final totalAppointments = appointments.length;

              // Filtrar citas próximas (status: agendada y fecha futura)
              final now = DateTime.now();
              final upcomingAppointments = appointments.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? '';
                final startTime = (data['start_time'] as Timestamp).toDate();
                return status == 'agendada' && startTime.isAfter(now);
              }).toList();

              // Obtener pacientes únicos
              final uniquePatients = appointments
                  .map(
                    (doc) => (doc.data() as Map<String, dynamic>)['patient_id'],
                  )
                  .toSet()
                  .length;

              return Column(
                children: [
                  // Fila 1: Total de citas y Citas próximas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total de Citas',
                          value: totalAppointments.toString(),
                          icon: Icons.calendar_today,
                          color: primaryColor,
                          subtitle: 'Historial completo',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Citas Próximas',
                          value: upcomingAppointments.length.toString(),
                          icon: Icons.event_available,
                          color: successColor,
                          subtitle: 'Pendientes',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 2: Total de pacientes
                  _buildStatCard(
                    title: 'Total de Pacientes',
                    value: uniquePatients.toString(),
                    icon: Icons.people,
                    color: warningColor,
                    subtitle: 'Pacientes únicos',
                    isFullWidth: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),

          // Sección de próximas citas
          Text(
            'Próximas Citas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 15),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                .where('doctor_id', isEqualTo: userId)
                .where('status', isEqualTo: 'agendada')
                .orderBy('start_time', descending: false)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No hay citas próximas',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final upcomingAppointments = snapshot.data!.docs.where((doc) {
                final startTime =
                    ((doc.data() as Map<String, dynamic>)['start_time']
                            as Timestamp)
                        .toDate();
                return startTime.isAfter(DateTime.now());
              }).toList();

              if (upcomingAppointments.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No hay citas próximas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: upcomingAppointments.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startTime = (data['start_time'] as Timestamp).toDate();
                  final patientId = data['patient_id'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(patientId)
                        .get(),
                    builder: (context, patientSnapshot) {
                      String patientName = 'Cargando...';
                      if (patientSnapshot.hasData &&
                          patientSnapshot.data!.exists) {
                        patientName =
                            patientSnapshot.data!.get('name') ?? 'Paciente';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: accentColor.withOpacity(0.2),
                            child: Icon(Icons.person, color: accentColor),
                          ),
                          title: Text(
                            patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['reason'] ?? 'Sin motivo especificado'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(startTime),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool isFullWidth = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 35),
                if (!isFullWidth)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                if (isFullWidth)
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

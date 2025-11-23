import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ScheduleDoctorPage extends StatefulWidget {
  const ScheduleDoctorPage({super.key});

  @override
  State<ScheduleDoctorPage> createState() => _ScheduleDoctorPageState();
}

class _ScheduleDoctorPageState extends State<ScheduleDoctorPage> {
  final Color primaryColor = const Color(0xFF007BFF);
  final Color accentColor = const Color(0xFF4A90E2);

  int _refreshKey = 0;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _refreshKey++;
    });

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

  void _showPatientInfo(BuildContext context, String patientId) async {
    print('🔍 Mostrando info del paciente: $patientId');

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      print('📄 Documento existe: ${patientDoc.exists}');

      if (!context.mounted) return;

      // Cerrar loading
      Navigator.pop(context);

      if (!patientDoc.exists) {
        print('❌ Paciente no encontrado en Firestore');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró información del paciente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final patientData = patientDoc.data()!;
      print('📊 Datos del paciente: $patientData');

      final birthDate = patientData['birth_date'] != null
          ? (patientData['birth_date'] as Timestamp).toDate()
          : null;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                // Indicador de arrastre
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Título
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: accentColor.withOpacity(0.2),
                      child: Icon(Icons.person, size: 35, color: accentColor),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientData['name'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Información del Paciente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Información del paciente
                _buildInfoTile(
                  icon: Icons.cake,
                  title: 'Edad',
                  value: patientData['age'] != null
                      ? '${patientData['age']} años'
                      : 'No disponible',
                  color: primaryColor,
                ),
                _buildInfoTile(
                  icon: Icons.calendar_today,
                  title: 'Fecha de Nacimiento',
                  value: birthDate != null
                      ? DateFormat('dd/MM/yyyy').format(birthDate)
                      : 'No disponible',
                  color: accentColor,
                ),
                _buildInfoTile(
                  icon: Icons.phone,
                  title: 'Teléfono',
                  value: patientData['phone_number'] ?? 'No disponible',
                  color: Colors.green,
                ),
                _buildInfoTile(
                  icon: Icons.email,
                  title: 'Email',
                  value: patientData['email'] ?? 'No disponible',
                  color: Colors.orange,
                ),
                _buildInfoTile(
                  icon: Icons.straighten,
                  title: 'Altura',
                  value: patientData['height'] != null
                      ? '${patientData['height']} cm'
                      : 'No disponible',
                  color: Colors.purple,
                ),
                _buildInfoTile(
                  icon: Icons.healing,
                  title: 'Padecimiento Crónico',
                  value:
                      patientData['chronic_condition']?.toString().isEmpty ??
                          true
                      ? 'Ninguno'
                      : patientData['chronic_condition'].toString(),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error obteniendo info del paciente: $e');
      print('📚 StackTrace: $stackTrace');

      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAppointmentActions(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> appointment,
  ) {
    final status = appointment['status'] ?? 'agendada';
    final startTime = (appointment['start_time'] as Timestamp).toDate();
    final now = DateTime.now();
    final isPastAppointment = startTime.isBefore(now);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título
              Text(
                'Acciones de la Cita',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // Botón: Ver información del paciente
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: accentColor),
                ),
                title: const Text('Ver información del paciente'),
                onTap: () {
                  Navigator.pop(context);
                  _showPatientInfo(context, appointment['patient_id']);
                },
              ),

              // Botón: Marcar como completada (solo si está agendada y no es futura)
              if (status == 'agendada' &&
                  !startTime.isAfter(now.add(const Duration(hours: 1))))
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  title: const Text('Marcar como completada'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmCompleteAppointment(context, appointmentId);
                  },
                ),

              // Botón: Cancelar cita (solo si está agendada)
              if (status == 'agendada')
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    child: const Icon(Icons.cancel, color: Colors.red),
                  ),
                  title: const Text('Cancelar cita'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmCancelAppointment(
                      context,
                      appointmentId,
                      appointment,
                    );
                  },
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _confirmCompleteAppointment(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Marcar como completada?'),
        content: const Text('¿Confirmas que esta cita ha sido completada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _completeAppointment(appointmentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Sí, completada',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeAppointment(String appointmentId) async {
    try {
      print('✅ Marcando cita como completada: $appointmentId');

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'completada', 'completed_at': Timestamp.now()});

      print('✅ Cita marcada como completada');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Cita marcada como completada'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _refreshKey++;
        });
      }
    } catch (e) {
      print('❌ Error completando cita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmCancelAppointment(
    BuildContext context,
    String appointmentId,
    Map<String, dynamic> appointment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar cita?'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta cita? El horario quedará disponible nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelAppointment(appointmentId, appointment);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(
    String appointmentId,
    Map<String, dynamic> appointment,
  ) async {
    try {
      print('🔄 Cancelando cita: $appointmentId');

      final doctorId = appointment['doctor_id'] as String;
      final startTime = (appointment['start_time'] as Timestamp).toDate();

      // Cancelar la cita
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': 'cancelada'});

      // Liberar el horario en schedules
      final dateString =
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
      final scheduleId = '${doctorId}_$dateString';
      final timeString =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

      final scheduleDoc = await FirebaseFirestore.instance
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (scheduleDoc.exists) {
        List<String> availableTimes = List<String>.from(
          scheduleDoc.data()!['available_times'] ?? [],
        );

        if (!availableTimes.contains(timeString)) {
          availableTimes.add(timeString);
          availableTimes.sort();

          await FirebaseFirestore.instance
              .collection('schedules')
              .doc(scheduleId)
              .update({'available_times': availableTimes});
        }
      }

      print('✅ Cita cancelada y horario liberado');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Cita cancelada exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _refreshKey++;
        });
      }
    } catch (e) {
      print('❌ Error cancelando cita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    Map<String, dynamic> appointment,
    String docId,
  ) {
    final startTime = (appointment['start_time'] as Timestamp).toDate();
    final endTime = (appointment['end_time'] as Timestamp).toDate();
    final patientId = appointment['patient_id'] as String;
    final status = appointment['status'] ?? 'agendada';

    print('🔍 Cargando info para paciente: $patientId');

    // Determinar color y texto del estado
    Color statusColor;
    String statusText;

    switch (status) {
      case 'cancelada':
        statusColor = Colors.red.shade100;
        statusText = 'CANCELADA';
        break;
      case 'completada':
        statusColor = Colors.green.shade100;
        statusText = 'COMPLETADA';
        break;
      default:
        statusColor = accentColor.withOpacity(0.1);
        statusText = 'AGENDADA';
    }

    Color statusTextColor;
    switch (status) {
      case 'cancelada':
        statusTextColor = Colors.red.shade700;
        break;
      case 'completada':
        statusTextColor = Colors.green.shade700;
        break;
      default:
        statusTextColor = primaryColor;
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get(),
      builder: (context, patientSnapshot) {
        String patientName = 'Cargando...';
        String patientEmail = '';

        if (patientSnapshot.connectionState == ConnectionState.done) {
          if (patientSnapshot.hasError) {
            print('❌ Error obteniendo paciente: ${patientSnapshot.error}');
            patientName = 'Error al cargar';
          } else if (patientSnapshot.hasData && patientSnapshot.data!.exists) {
            final data = patientSnapshot.data!.data() as Map<String, dynamic>;
            patientName = data['name'] ?? 'Sin nombre';
            patientEmail = data['email'] ?? '';
            print('✅ Paciente cargado: $patientName');
          } else {
            print('⚠️ Documento del paciente no existe: $patientId');
            patientName = 'Usuario no encontrado';
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          child: InkWell(
            onTap: () {
              _showAppointmentActions(context, docId, appointment);
            },
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: accentColor.withOpacity(0.2),
                              child: Icon(Icons.person, color: accentColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (patientEmail.isNotEmpty)
                                    Text(
                                      patientEmail,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(startTime),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                appointment['reason'] ??
                                    'Consulta Médica General',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Toca para ver opciones',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.more_horiz, size: 14, color: accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    print('👤 Doctor ID: $userId');

    if (userId == null) {
      return const Center(child: Text("Error: Usuario no autenticado."));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        displacement: 40.0,
        child: StreamBuilder<QuerySnapshot>(
          key: ValueKey(_refreshKey),
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('doctor_id', isEqualTo: userId)
              .orderBy('start_time', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            print('📊 ConnectionState: ${snapshot.connectionState}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('❌ Error: ${snapshot.error}');
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('📭 No hay citas');
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
                            Icons.event_busy,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "No tienes citas registradas.",
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

            final documents = snapshot.data!.docs;
            print('✅ ${documents.length} citas encontradas');

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
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

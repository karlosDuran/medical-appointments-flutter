import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/appointment_manager.dart'; // Para acceder a las citas

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final Color primaryColor = const Color(0xFF007BFF);
  final Color lightBlue = const Color(0xFFE3F2FD); // Azul muy claro para fondo
  final DateFormat dateFormatter = DateFormat('EEE, MMM d, yyyy');

  // La lista de citas puede cambiar, por lo que la obtenemos en cada build (o con un listener)
  List<Appointment> get appointments => AppointmentManager.appointments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: appointments.isEmpty ? _buildEmptyState() : _buildAppointmentList(),
    );
  }

  // Estado cuando no hay citas agendadas
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            "Aún no tienes citas agendadas.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Text(
            "Agenda tu primera consulta desde el inicio.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Lista de citas agendadas
  Widget _buildAppointmentList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            "Próximas Citas (${appointments.length})",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const Divider(color: Colors.grey, height: 25),
          ...appointments
              .map((appointment) => _buildAppointmentCard(appointment))
              .toList(),
        ],
      ),
    );
  }

  // Tarjeta individual de cita
  Widget _buildAppointmentCard(Appointment appointment) {
    // Formatear la hora
    final String formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(appointment.time, alwaysUse24HourFormat: false);

    // Calcular el estado (simulación)
    final bool isPast = appointment.date.isBefore(DateTime.now());
    final Color cardColor = isPast ? Colors.grey.shade300 : Colors.white;
    final Color statusColor = isPast ? Colors.red : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Fecha y Hora (Minimalista)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  appointment.date.day.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(appointment.date),
                  style: TextStyle(fontSize: 14, color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),

          // Detalles de la Cita
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. en ${appointment.specialist}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dateFormatter.format(appointment.date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Icono de Estado
          isPast
              ? Icon(Icons.check_circle_outline, color: Colors.red, size: 30)
              : Icon(Icons.pending_actions, color: primaryColor, size: 30),
        ],
      ),
    );
  }
}

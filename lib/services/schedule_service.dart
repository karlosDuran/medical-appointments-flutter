import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generar horarios disponibles para los próximos 60 días
  Future<void> generateSchedulesForDoctor(String doctorId) async {
    try {
      // Obtener configuración del doctor
      final doctorDoc = await _firestore
          .collection('users')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) return;

      final doctorData = doctorDoc.data()!;
      final workSchedule = doctorData['work_schedule'] as Map<String, dynamic>?;

      if (workSchedule == null) return;

      final today = DateTime.now();

      // Generar horarios para los próximos 60 días
      for (int i = 0; i < 60; i++) {
        final currentDate = today.add(Duration(days: i));
        final dayName = _getDayName(currentDate.weekday);

        // Verificar si el doctor trabaja este día
        if (!workSchedule.containsKey(dayName)) continue;

        final daySchedule = workSchedule[dayName] as List;

        // Generar lista de horarios disponibles
        List<String> availableTimes = [];

        for (var interval in daySchedule) {
          final startParts = (interval['start'] as String).split(':');
          final endParts = (interval['end'] as String).split(':');

          final startHour = int.parse(startParts[0]);
          final startMinute = int.parse(startParts[1]);
          final endHour = int.parse(endParts[0]);
          final endMinute = int.parse(endParts[1]);

          // Si es 24 horas (misma hora inicio y fin)
          if (startHour == endHour && startMinute == endMinute) {
            for (int hour = 0; hour < 24; hour++) {
              availableTimes.add('${hour.toString().padLeft(2, '0')}:00');
              availableTimes.add('${hour.toString().padLeft(2, '0')}:30');
            }
          } else {
            // Generar intervalos de 30 minutos
            int currentMinutes = startHour * 60 + startMinute;
            final endMinutes = endHour * 60 + endMinute;

            while (currentMinutes < endMinutes) {
              final hour = currentMinutes ~/ 60;
              final minute = currentMinutes % 60;
              availableTimes.add(
                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
              );
              currentMinutes += 30;
            }
          }
        }

        if (availableTimes.isEmpty) continue;

        // Crear documento con ID único: doctorId_fecha
        final dateString =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
        final scheduleId = '${doctorId}_$dateString';

        final scheduleData = {
          'doctor_id': doctorId,
          'date': Timestamp.fromDate(
            DateTime(currentDate.year, currentDate.month, currentDate.day),
          ),
          'available_times': availableTimes,
          'created_at': FieldValue.serverTimestamp(),
        };

        // Usar set con merge para no sobrescribir si ya existe
        await _firestore
            .collection('schedules')
            .doc(scheduleId)
            .set(scheduleData, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error generando horarios: $e');
      rethrow;
    }
  }

  // Obtener horarios disponibles de un doctor en una fecha específica
  Future<List<String>> getAvailableTimesForDate(
    String doctorId,
    DateTime date,
  ) async {
    try {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final scheduleId = '${doctorId}_$dateString';

      print('🔍 Buscando horarios...');
      print('   Doctor ID: $doctorId');
      print('   Fecha: $dateString');
      print('   Schedule ID: $scheduleId');

      final scheduleDoc = await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .get();

      print('   Documento existe: ${scheduleDoc.exists}');

      if (!scheduleDoc.exists) {
        print('❌ No se encontró el documento de horarios');
        print('   Buscando todos los schedules para debug...');

        // Debug: Ver todos los schedules de este doctor
        final allSchedules = await _firestore
            .collection('schedules')
            .where('doctor_id', isEqualTo: doctorId)
            .get();

        print('   Schedules encontrados: ${allSchedules.docs.length}');
        for (var doc in allSchedules.docs) {
          print('   - ID: ${doc.id}');
          print('     Date: ${doc.data()['date']}');
          print(
            '     Available times: ${(doc.data()['available_times'] as List).length} horarios',
          );
        }

        return [];
      }

      final data = scheduleDoc.data()!;
      print('📄 Documento encontrado:');
      print('   Doctor ID: ${data['doctor_id']}');
      print('   Fecha: ${data['date']}');

      final availableTimes = List<String>.from(data['available_times'] ?? []);
      print('   Horarios totales: ${availableTimes.length}');

      // Filtrar horarios ocupados
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);

      print('🔍 Buscando citas agendadas...');
      final existingAppointments = await _firestore
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .where('status', isEqualTo: 'agendada')
          .where(
            'start_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'start_time',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
          )
          .get();

      print('   Citas encontradas: ${existingAppointments.docs.length}');

      // Crear set de horarios ocupados
      final Set<String> occupiedTimes = {};
      for (var doc in existingAppointments.docs) {
        final data = doc.data();
        final startTime = (data['start_time'] as Timestamp).toDate();
        final timeKey =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        occupiedTimes.add(timeKey);
        print('   - Ocupado: $timeKey');
      }

      // Filtrar horarios que ya pasaron si es hoy
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        print('⏰ Es hoy, filtrando horarios pasados...');
        availableTimes.removeWhere((time) {
          final parts = time.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final timeInMinutes = hour * 60 + minute;
          final nowInMinutes = now.hour * 60 + now.minute;
          return timeInMinutes <= nowInMinutes;
        });
        print('   Después de filtrar pasados: ${availableTimes.length}');
      }

      // Remover horarios ocupados
      availableTimes.removeWhere((time) => occupiedTimes.contains(time));
      print('   Después de filtrar ocupados: ${availableTimes.length}');

      print('✅ Horarios disponibles finales: ${availableTimes.length}');
      if (availableTimes.isNotEmpty) {
        print('   Primeros 5: ${availableTimes.take(5).join(", ")}');
      }

      return availableTimes;
    } catch (e, stackTrace) {
      print('❌ Error obteniendo horarios: $e');
      print('📚 StackTrace: $stackTrace');
      return [];
    }
  }

  // Marcar un horario como reservado (se ejecuta al crear una cita)
  Future<void> markTimeAsBooked(String doctorId, DateTime dateTime) async {
    try {
      final dateString =
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      final scheduleId = '${doctorId}_$dateString';
      final timeString =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      final scheduleDoc = await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .get();

      if (scheduleDoc.exists) {
        List<String> availableTimes = List<String>.from(
          scheduleDoc.data()!['available_times'] ?? [],
        );
        availableTimes.remove(timeString);

        await _firestore.collection('schedules').doc(scheduleId).update({
          'available_times': availableTimes,
        });
      }
    } catch (e) {
      print('Error marcando horario como reservado: $e');
    }
  }

  // Liberar un horario (se ejecuta al cancelar una cita)
  Future<void> freeUpTime(String doctorId, DateTime dateTime) async {
    try {
      final dateString =
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      final scheduleId = '${doctorId}_$dateString';
      final timeString =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      final scheduleDoc = await _firestore
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

          await _firestore.collection('schedules').doc(scheduleId).update({
            'available_times': availableTimes,
          });
        }
      }
    } catch (e) {
      print('Error liberando horario: $e');
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[weekday - 1];
  }
}

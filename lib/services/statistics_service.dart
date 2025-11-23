import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener cantidad de citas por mes (últimos 6 meses)
  Future<Map<String, int>> getAppointmentsByMonth(String doctorId) async {
    print('📊 getAppointmentsByMonth - doctorId: $doctorId');

    try {
      // SIMPLIFICADO: Obtener TODAS las citas del doctor y filtrar localmente
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      print('📊 Total documentos encontrados: ${snapshot.docs.length}');

      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

      Map<String, int> monthlyData = {};

      // Inicializar los últimos 6 meses con 0
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${_getMonthName(date.month)} ${date.year}';
        monthlyData[monthKey] = 0;
        print('📅 Inicializando: $monthKey = 0');
      }

      // Filtrar y contar citas por mes
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final startTime = (data['start_time'] as Timestamp).toDate();

        print(
          '📄 Cita ${doc.id}: ${startTime.toString()} - status: ${data['status']}',
        );

        // Filtrar solo citas de los últimos 6 meses
        if (startTime.isBefore(sixMonthsAgo)) {
          print('   ⏩ Muy antigua, omitiendo');
          continue;
        }

        final monthKey = '${_getMonthName(startTime.month)} ${startTime.year}';

        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
          print('   ✅ Contando en $monthKey: ${monthlyData[monthKey]}');
        } else {
          print('   ⚠️ Mes fuera de rango: $monthKey');
        }
      }

      print('📊 Resultado mensual final: $monthlyData');
      return monthlyData;
    } catch (e, stackTrace) {
      print('❌ Error en getAppointmentsByMonth: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Obtener citas completadas vs canceladas vs agendadas
  Future<Map<String, int>> getAppointmentsByStatus(String doctorId) async {
    print('📊 getAppointmentsByStatus - doctorId: $doctorId');

    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      print('📊 Total documentos: ${snapshot.docs.length}');

      Map<String, int> statusData = {
        'Agendadas': 0,
        'Completadas': 0,
        'Canceladas': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'agendada';
        print('📄 Cita ${doc.id}: status = $status');

        if (status == 'agendada') {
          statusData['Agendadas'] = (statusData['Agendadas'] ?? 0) + 1;
        } else if (status == 'completada') {
          statusData['Completadas'] = (statusData['Completadas'] ?? 0) + 1;
        } else if (status == 'cancelada') {
          statusData['Canceladas'] = (statusData['Canceladas'] ?? 0) + 1;
        }
      }

      print('📊 Resultado por estado: $statusData');
      return statusData;
    } catch (e, stackTrace) {
      print('❌ Error en getAppointmentsByStatus: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Obtener cantidad de pacientes únicos atendidos
  Future<int> getUniquePatientsCount(String doctorId) async {
    print('📊 getUniquePatientsCount - doctorId: $doctorId');

    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      Set<String> uniquePatients = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';

        // Solo contar pacientes con citas completadas
        if (status == 'completada') {
          uniquePatients.add(data['patient_id'] as String);
        }
      }

      print('📊 Pacientes únicos: ${uniquePatients.length}');
      return uniquePatients.length;
    } catch (e, stackTrace) {
      print('❌ Error en getUniquePatientsCount: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  // Obtener citas por día de la semana
  Future<Map<String, int>> getAppointmentsByWeekday(String doctorId) async {
    print('📊 getAppointmentsByWeekday - doctorId: $doctorId');

    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctor_id', isEqualTo: doctorId)
          .get();

      print('📊 Total documentos: ${snapshot.docs.length}');

      Map<String, int> weekdayData = {
        'Lun': 0,
        'Mar': 0,
        'Mié': 0,
        'Jue': 0,
        'Vie': 0,
        'Sáb': 0,
        'Dom': 0,
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';

        print('📄 Cita ${doc.id}: status = $status');

        // Filtrar solo agendadas y completadas
        if (status != 'agendada' && status != 'completada') {
          print('   ⏩ Status ignorado: $status');
          continue;
        }

        final startTime = (data['start_time'] as Timestamp).toDate();
        final dayName = _getWeekdayName(startTime.weekday);
        weekdayData[dayName] = (weekdayData[dayName] ?? 0) + 1;
        print('   ✅ Contando en $dayName: ${weekdayData[dayName]}');
      }

      print('📊 Citas por día de la semana: $weekdayData');
      return weekdayData;
    } catch (e, stackTrace) {
      print('❌ Error en getAppointmentsByWeekday: $e');
      print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }
}

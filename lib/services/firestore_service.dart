import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule_service.dart';

class FirestoreService {
  // Patrón Singleton para una única instancia de la clase
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Instancia de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ScheduleService _scheduleService = ScheduleService();

  // --- Paths de Colección ---
  final String _usersCollection = 'users';
  final String _appointmentsCollection = 'appointments';

  // --- MÉTODOS DE USUARIO ---

  // NUEVA FUNCIÓN: Crea el documento inicial del usuario en Firestore.
  Future<void> createUserProfile(String userId, String email) async {
    final userRef = _db.collection(_usersCollection).doc(userId);

    await userRef.set(
      {
        'email': email,
        'name': '',
        'phone_number': '',
        'is_doctor': false,
        'specialty': '',
      },
      SetOptions(merge: true),
    ); // Usamos merge para evitar sobrescribir si ya existe
  }

  // LEER: Obtener datos del usuario en tiempo real (para SettingsPage)
  Stream<Map<String, dynamic>?> getUserDataStream(String userId) {
    return _db.collection(_usersCollection).doc(userId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  // UPDATE: Actualizar campos específicos del usuario (EL MÉTODO REQUERIDO)
  Future<void> updateUserField(
    String userId,
    String field,
    dynamic value,
  ) async {
    await _db.collection(_usersCollection).doc(userId).update({field: value});
  }

  // --- MÉTODOS DE CITAS ---

  // CREATE: Agendar una nueva cita
  Future<void> createAppointment(Map<String, dynamic> appointmentData) async {
    await _db.collection('appointments').add(appointmentData);
  }

  // READ: Obtener citas del usuario
  Stream<QuerySnapshot> getAppointmentsStream(String userId) {
    return _db
        .collection(_appointmentsCollection)
        .where('patient_id', isEqualTo: userId)
        .snapshots();
  }

  // UPDATE/DELETE: Cancelar una cita
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      // Obtener datos de la cita antes de cancelar
      final appointmentDoc = await _db
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (appointmentDoc.exists) {
        final data = appointmentDoc.data()!;
        final doctorId = data['doctor_id'] as String;
        final startTime = (data['start_time'] as Timestamp).toDate();

        print('🔄 Cancelando cita y liberando horario...');

        // Cancelar la cita
        await _db.collection('appointments').doc(appointmentId).update({
          'status': 'cancelada',
        });

        // Liberar el horario en schedules
        await _scheduleService.freeUpTime(doctorId, startTime);

        print('✅ Cita cancelada y horario liberado');
      }
    } catch (e) {
      print('❌ Error cancelando cita: $e');
      rethrow;
    }
  }

  // UPDATE: Actualizar una cita existente
  Future<void> updateAppointment(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db
          .collection(_appointmentsCollection)
          .doc(appointmentId)
          .update(data);
    } catch (e) {
      throw Exception('Error al actualizar la cita: $e');
    }
  }
}

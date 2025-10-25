import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryColor = const Color(0xFF007BFF);
  final Color secondaryColor = const Color(
    0xFF6B58F5,
  ); // Tono morado para contraste

  User? _currentUser;
  File? _localProfileImageFile;

  final List<String> _dailyTips = [
    "Recuerda beber al menos 8 vasos de agua al día para mantenerte hidratado.",
    "Prioriza 7-9 horas de sueño cada noche para mejorar tu concentración.",
    "Toma un descanso de 5 minutos cada hora si trabajas frente a una pantalla.",
    "Incluye verduras de hoja verde en tu dieta diaria para un aporte extra de vitaminas.",
    "Da un paseo de 30 minutos; la actividad física ligera es clave para la salud mental.",
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _showDailyTipPopup();
    _loadLocalImage();
  }

  // Muestra un pop-up con un consejo aleatorio al inicio
  void _showDailyTipPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final random = Random();
      final tip = _dailyTips[random.nextInt(_dailyTips.length)];

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: secondaryColor),
              const SizedBox(width: 8),
              const Text("Consejo del Día"),
            ],
          ),
          content: Text(tip, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cerrar", style: TextStyle(color: primaryColor)),
            ),
          ],
        ),
      );
    });
  }

  // Lógica para cargar la imagen local guardada (requiere path_provider)
  Future<void> _loadLocalImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = File('${directory.path}/images/profile_picture.jpg');

    if (await path.exists()) {
      setState(() {
        _localProfileImageFile = path;
      });
    } else {
      setState(() {
        _localProfileImageFile = null;
      });
    }
  }

  Widget _buildAppointmentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String routeArg,
  }) {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          // Navegación al formulario de citas con el tipo de cita como argumento
          Navigator.pushNamed(
            context,
            Routes.scheduleAppointment,
            arguments: routeArg,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser?.displayName ?? "karlos";

    // La HomePage ahora solo devuelve el contenido central sin Scaffold ni AppBar
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Saludo
          Text(
            'Hola $userName',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            '¿Cómo te sientes hoy?',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 25),

          // Tarjetas de Agendamiento
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAppointmentCard(
                title: "Visita a Clínica",
                subtitle: "Agenda una cita con tu doctor ahora",
                icon: Icons.add,
                color: secondaryColor, // Morado
                routeArg: 'Visita a Clínica',
              ),
              _buildAppointmentCard(
                title: "Consulta Remota",
                subtitle: "Llamada o video chat",
                icon: Icons.home,
                color: primaryColor, // Azul
                routeArg: 'Consulta Remota',
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Sección de Síntomas
          const Text(
            '¿Cuáles son tus síntomas?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            children: [
              _buildSymptomChip('Temperatura', primaryColor),
              _buildSymptomChip('Tos', primaryColor),
              _buildSymptomChip('Fiebre', primaryColor),
              _buildSymptomChip('Dolor de cabeza', primaryColor),
            ],
          ),
          const SizedBox(height: 25),

          // Sección de Doctores Populares
          const Text(
            'Doctores Populares',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          // Lista horizontal de doctores (simulada)
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildDoctorCard('Dr. Pérez', 'Cardiología', secondaryColor),
                _buildDoctorCard('Dra. Gámez', 'Pediatría', secondaryColor),
                _buildDoctorCard('Dr. Lopez', 'General', secondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomChip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color)),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildDoctorCard(String name, String specialty, Color color) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.person, size: 40, color: color),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            specialty,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 14, color: Colors.amber),
              Text(' 4.9', style: TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

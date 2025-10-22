import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el nombre
import 'routes.dart'; // Para la navegación

// Lista de consejos para el pop-up aleatorio
const List<String> dailyTips = [
  "Recuerda beber al menos 8 vasos de agua hoy.",
  "Dedica 15 minutos a estiramientos ligeros para tu postura.",
  "Intenta desconectarte de las pantallas una hora antes de dormir.",
  "Asegúrate de consumir una porción de verduras de hoja verde.",
  "Programa una breve caminata de 10 minutos al aire libre.",
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Definición de colores
  final Color primaryColor = const Color(0xFF007BFF); // Azul principal
  final Color secondaryColor = const Color(
    0xFF6F3CFF,
  ); // Morado/Violeta para contraste
  final Color accentColor = const Color(0xFF4A90E2);

  bool _hasShownTip = false;

  @override
  void initState() {
    super.initState();
    // Muestra el consejo después de que el widget se ha construido
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDailyTip(context));
  }

  // Función para mostrar el diálogo de consejos
  void _showDailyTip(BuildContext context) {
    if (_hasShownTip) return;

    final randomTip = dailyTips[Random().nextInt(dailyTips.length)];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: primaryColor),
              const SizedBox(width: 10),
              const Text("Consejo del Día"),
            ],
          ),
          content: Text(randomTip),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("¡Entendido!", style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );

    // Marca como mostrado para que no aparezca de nuevo en esta sesión
    _hasShownTip = true;
  }

  // Widget para las tarjetas de cita (similares a Clinic Visit)
  Widget _buildAppointmentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        // CORRECCIÓN CLAVE: Eliminamos height: 150 y width: 150
        // Ahora el tamaño es determinado por el padding interno y el Flexible/Expanded
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Añadimos MainAxisAlignment.end para empujar el contenido hacia abajo
          mainAxisAlignment: MainAxisAlignment.end,
          // Ajustamos el tamaño del contenido para evitar el desbordamiento
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(
              height: 15,
            ), // Añadimos espacio en lugar de usar MainAxisAlignment.spaceBetween
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Intenta obtener el nombre del usuario, si no está disponible usa un valor por defecto
    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? "Usuario";

    // Obtenemos solo el primer nombre
    final firstName = userName.split(' ')[0];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Saludo
          Text(
            "Hola $firstName",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "¿Cómo te sientes hoy?",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          // Cards de Citas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // CORRECCIÓN CLAVE: Usamos Flexible y SizedBox para controlar el espaciado
              Flexible(
                child: _buildAppointmentCard(
                  title: "Visita a Clínica",
                  subtitle: "Agenda una cita ahora",
                  icon: Icons.add,
                  color: secondaryColor,
                  onTap: () {
                    // Navegar a la página de agendar citas
                    Navigator.pushNamed(context, Routes.schedule);
                  },
                ),
              ),
              const SizedBox(width: 15), // Espacio entre las tarjetas
              Flexible(
                child: _buildAppointmentCard(
                  title: "Consulta Remota",
                  subtitle: "Llamada o video chat",
                  icon: Icons.home_outlined,
                  color: accentColor,
                  onTap: () {
                    // Lógica para consulta remota
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Consulta Remota - En desarrollo"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Título de Doctores Populares (Simulación de la imagen)
          const Text(
            "Doctores Populares",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),

          // Lista de Doctores Populares (Simulación)
          ...List.generate(4, (index) => _buildDoctorTile(context, index)),
        ],
      ),
    );
  }

  // Widget de simulación para la lista de doctores
  Widget _buildDoctorTile(BuildContext context, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono de Doctor
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(Icons.medical_services_outlined, color: primaryColor),
          ),
          const SizedBox(width: 15),

          // Información del Doctor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Dr. Juan Pérez ${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Cardiólogo - 4.9 ⭐",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          // Botón de cita rápida
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Cita",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

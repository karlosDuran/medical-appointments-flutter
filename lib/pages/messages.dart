import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  // Definición de colores
  final Color primaryColor = const Color(0xFF007BFF); // Azul principal
  final Color accentColor = const Color(0xFF4A90E2); // Azul más claro
  final Color inactiveColor = const Color(0xFFE0E0E0); // Gris claro minimalista

  // Datos de ejemplo para los doctores en línea
  final List<String> _onlineDoctors = const [
    "Dra. Laura",
    "Dr. Miguel",
    "Dr. Ana",
    "Dr. José",
    "Dra. Rosa",
    "Dr. Juan",
  ];

  // Datos de ejemplo para los chats recientes (solo 4)
  final List<Map<String, String>> _recentChats = const [
    {
      'name': 'Dra. Laura Gómez',
      'message': 'Recuerda tomar tu medicamento a tiempo.',
      'time': '10:45 AM',
    },
    {
      'name': 'Dr. Miguel Torres',
      'message': 'Revisa los resultados que te envié.',
      'time': 'Ayer',
    },
    {
      'name': 'Dr. Juan Pérez',
      'message': 'Confirmamos su cita para mañana.',
      'time': 'Hace 5 min',
    },
    {
      'name': 'Dra. Ana Díaz',
      'message': 'Estoy esperando su respuesta, gracias.',
      'time': '1 día',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // No mostrar botón de retroceso
        title: const Text(
          "Mensajes",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80, // Aumentar altura del AppBar
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar doctor o chat...",
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: inactiveColor.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Lista de Avatars (Doctores online)
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _onlineDoctors.length,
              itemBuilder: (context, index) {
                return _buildOnlineDoctorAvatar(
                  _onlineDoctors[index],
                  index.isEven,
                );
              },
            ),
          ),
          const SizedBox(height: 15),

          // Título de Chats Recientes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Chats Recientes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Lista de Chats (4 chats de ejemplo)
          Expanded(
            child: ListView.builder(
              itemCount: _recentChats.length,
              itemBuilder: (context, index) {
                final chat = _recentChats[index];
                return _buildChatListItem(
                  chat['name']!,
                  chat['message']!,
                  chat['time']!,
                  index, // Usar el índice para variar el ícono
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir el avatar de doctor online (con íconos)
  Widget _buildOnlineDoctorAvatar(String name, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.local_hospital, // Ícono de ejemplo
                  color: primaryColor,
                  size: 30,
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.green, // Indicador online
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            name.split(' ')[0], // Mostrar solo el nombre
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Widget para construir un elemento de la lista de chats
  Widget _buildChatListItem(
    String doctorName,
    String lastMessage,
    String time,
    int index,
  ) {
    // Para simular variedad de iniciales
    final String initial = doctorName.substring(0, 1);
    final bool hasUnread = index == 2; // Simular un mensaje no leído

    return InkWell(
      onTap: () {
        // Lógica para abrir el chat con este doctor
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: hasUnread
            ? primaryColor.withOpacity(0.05)
            : Colors.transparent, // Fondo sutil para no leído
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: accentColor.withOpacity(0.8),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasUnread ? primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnread ? primaryColor : Colors.grey.shade600,
                      fontWeight: hasUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread ? primaryColor : Colors.grey.shade500,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(color: Colors.white, fontSize: 10),
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

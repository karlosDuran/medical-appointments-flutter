import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  final Color primaryColor = const Color(0xFF007BFF);
  final Color detailColor = const Color(0xFF6C757D);

  // Datos de chats de ejemplo
  final List<Map<String, dynamic>> _chatData = const [
    {
      'name': 'Dr. Elena Ríos',
      'icon': Icons.local_hospital,
      'status': true,
      'initials': 'ER',
    },
    {
      'name': 'Dra. Ana López',
      'icon': Icons.medical_services,
      'status': true,
      'initials': 'AL',
    },
    {
      'name': 'Dr. Juan Pérez',
      'icon': Icons.person,
      'status': false,
      'initials': 'JP',
    },
    {
      'name': 'Clínica Central',
      'icon': Icons.apartment,
      'status': true,
      'initials': 'CC',
    },
  ];

  // Widget para el avatar de ejemplo
  Widget _buildAvatar(Map<String, dynamic> chat) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Text(
            chat['initials'],
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        if (chat['status'])
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // Widget para la fila de un chat
  Widget _buildChatItem(Map<String, dynamic> chat) {
    return ListTile(
      leading: _buildAvatar(chat),
      title: Text(
        chat['name'],
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        "Hola, ¿están ahí? Necesito agendar una cita...",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Text(
        "12:30",
        style: TextStyle(color: detailColor, fontSize: 12),
      ),
      onTap: () {
        // Lógica no funcional, solo visual
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: "Buscar Chats o Doctores",
                prefixIcon: Icon(Icons.search, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
              ),
            ),
          ),

          // Fila de Historias/Avatares Recientes
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _chatData.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: _buildAvatar(_chatData[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Lista de Chats
          Expanded(
            child: ListView.builder(
              itemCount: _chatData.length,
              itemBuilder: (context, index) {
                return _buildChatItem(_chatData[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

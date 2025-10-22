import 'package:appointment/pages/messages.dart';
import 'package:appointment/pages/schedule.dart';
import 'package:appointment/pages/settings.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Widget genérico de Placeholder para las pantallas no implementadas
  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            'Página de $title en construcción',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Lista de los títulos del AppBar
  static const List<String> _pageTitles = <String>[
    'Inicio',
    'Mensajes',
    'Citas',
    'Configuración', // Título para la página de Ajustes/Perfil
  ];

  // Inicialización de la lista de Widgets
  List<Widget> get _widgetOptions => <Widget>[
    const HomePage(),
    const MessagesPage(),
    const SchedulePage(), // CAMBIO CLAVE: Ahora muestra la página de Citas
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final Color primaryColor = const Color(0xFF007BFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar General para toda la MainScreen ---
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex], // Título dinámico
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Quitar el botón de retroceso
      ),
      // El body ahora solo contiene el widget seleccionado de la lista
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: _pageTitles[0],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.message_outlined),
            activeIcon: const Icon(Icons.message),
            label: _pageTitles[1],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: _pageTitles[2],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline), // Icono de Perfil
            activeIcon: const Icon(Icons.person),
            label: _pageTitles[3], // Etiqueta 'Configuración'
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

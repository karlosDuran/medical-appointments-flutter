import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'pages/home_page_doctor.dart';
import 'pages/schedule.dart';
import 'pages/schedule_doctor.dart';
import 'pages/messages.dart';
import 'pages/settings.dart';
import 'pages/graphics_page.dart'; // ← AGREGAR al inicio

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool? _isDoctor;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('✅ MainScreen: initState llamado');
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    print('🔍 MainScreen: Verificando tipo de usuario...');

    final user = FirebaseAuth.instance.currentUser;
    print('👤 Usuario actual: ${user?.uid}');

    if (user == null) {
      print('❌ No hay usuario autenticado');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay usuario autenticado';
        });
      }
      return;
    }

    try {
      print('📥 Obteniendo documento del usuario...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      print('📄 Documento existe: ${userDoc.exists}');

      if (userDoc.exists) {
        final data = userDoc.data();
        print('📊 Datos del usuario: $data');

        if (mounted) {
          setState(() {
            _isDoctor = data?['is_doctor'] ?? false;
            _isLoading = false;
            print('✅ Es doctor: $_isDoctor');
          });
        }
      } else {
        print('⚠️ El documento del usuario no existe');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Perfil de usuario no encontrado';
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error al verificar tipo de usuario: $e');
      print('📚 StackTrace: $stackTrace');

      if (mounted) {
        setState(() {
          _isDoctor = false;
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  void _onItemTapped(int index) {
    print('🔘 Tab seleccionado: $index');
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🎨 build() - isLoading: $_isLoading, isDoctor: $_isDoctor, error: $_errorMessage',
    );

    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  'Cargando perfil...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mostrar error si hay
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _checkUserType();
                  },
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Definir páginas según el tipo de usuario
    List<Widget> pages;

    try {
      print('📄 Creando páginas...');
      pages = _isDoctor == true
          ? [
              const HomePageDoctor(),
              const ScheduleDoctorPage(),
              const GraphicsPage(),
              const MessagesPage(),
              const SettingsPage(),
            ]
          : [
              const HomePage(),
              const SchedulePage(),
              const MessagesPage(),
              const SettingsPage(),
            ];
      print('✅ Páginas creadas exitosamente');
    } catch (e, stackTrace) {
      print('❌ Error creando páginas: $e');
      print('📚 StackTrace: $stackTrace');

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error al cargar páginas: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                child: const Text('Volver al login'),
              ),
            ],
          ),
        ),
      );
    }

    print('✅ Renderizando Scaffold con ${pages.length} páginas');

    // Determinar título del AppBar según el índice y tipo de usuario
    String appBarTitle;
    if (_isDoctor == true) {
      // Para doctores (5 pestañas)
      switch (_selectedIndex) {
        case 0:
          appBarTitle = 'Dashboard';
          break;
        case 1:
          appBarTitle = 'Mis Citas';
          break;
        case 2:
          appBarTitle = 'Gráficas';
          break;
        case 3:
          appBarTitle = 'Mensajes';
          break;
        case 4:
          appBarTitle = 'Configuración';
          break;
        default:
          appBarTitle = 'Dashboard';
      }
    } else {
      // Para pacientes (4 pestañas)
      switch (_selectedIndex) {
        case 0:
          appBarTitle = 'Inicio';
          break;
        case 1:
          appBarTitle = 'Mis Citas';
          break;
        case 2:
          appBarTitle = 'Mensajes';
          break;
        case 3:
          appBarTitle = 'Configuración';
          break;
        default:
          appBarTitle = 'Inicio';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF007BFF),
        elevation: 0,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(_isDoctor == true ? Icons.dashboard : Icons.home),
            label: _isDoctor == true ? 'Dashboard' : 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
          if (_isDoctor == true)
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Gráficas',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mensajes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}

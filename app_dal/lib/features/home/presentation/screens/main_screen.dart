import 'package:flutter/material.dart';
import 'package:app_dal/features/home/presentation/screens/inicio_tab.dart';
import 'package:app_dal/features/equipos/presentation/screens/equipos_tab.dart';
import 'package:app_dal/features/renta/presentation/screens/renta_tab.dart';
import 'package:app_dal/features/configuracion/presentation/screens/configuracion_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    InicioTab(),
    EquiposTab(),
    RentaTab(),
    ConfiguracionTab(),
  ];

  static const List<BottomNavigationBarItem> _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.construction_outlined),
      activeIcon: Icon(Icons.construction),
      label: 'Equipos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assignment_outlined),
      activeIcon: Icon(Icons.assignment),
      label: 'Renta',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Configuración',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _screens,
          ),
          Positioned(
            top: 8,
            right: 12,
            child: SafeArea(
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/Logo_Icon_White.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        },
        items: _items,
      ),
    );
  }
}

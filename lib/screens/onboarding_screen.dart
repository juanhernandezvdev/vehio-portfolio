import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Bienvenido a Vehio',
      'description': 'La herramienta definitiva para tener el control total de tus vehículos en la palma de tu mano.',
      'icon': Icons.garage,
    },
    {
      'title': 'Control Financiero',
      'description': 'Registra tus recargas de gasolina y mantenimientos. Nosotros generamos los gráficos y el cálculo de vida útil.',
      'icon': Icons.pie_chart,
    },
    {
      'title': 'Alertas Inteligentes',
      'description': 'Recibe notificaciones locales antes de que tus piezas se desgasten. ¡Evita daños mayores y ahorra dinero!',
      'icon': Icons.notifications_active,
    }
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false); // Marcamos que ya vio el tutorial
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_pages[index]['icon'], size: 120, color: const Color(0xFFE50914)),
                        const SizedBox(height: 40),
                        Text(_pages[index]['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        Text(_pages[index]['description'], style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 10,
                  width: _currentPage == index ? 30 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFFE50914) : Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: () {
                    // CORREGIDO: Se ajustó la condición para evaluar el último índice correctamente
                    if (_currentPage == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE50914), foregroundColor: Colors.black),
                  child: Text(
                    // CORREGIDO: Se ajustó el operador de longitud para mostrar el texto adecuado
                    _currentPage == _pages.length - 1 ? 'Empezar a usar Vehio' : 'Siguiente',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
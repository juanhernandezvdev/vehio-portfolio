import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/vehicle_provider.dart';
import '../models/maintenance_model.dart';
import '../providers/maintenance_provider.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';

// --- IMPORTACIONES DE NUEVAS SECCIONES Y AUTH ---
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'emergency_screen.dart';
import 'premium_screen.dart';
import '../auth/login_screen.dart';
import '../providers/subscription_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables para controlar el menú lateral y el Garaje Dual
  bool _isMenuOpen = false;
  int _selectedIndex = 0; // 0: Garaje
  int _selectedGarage = 0; // 0: Autos, 1: Motos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<VehicleProvider>(context, listen: false);
      await provider.loadVehicles();
      
      final mProvider = Provider.of<MaintenanceProvider>(context, listen: false);
      
      // Construimos una lista combinada de todos los mantenimientos
      List<Maintenance> allMaintenances = [];
      for (var v in provider.vehicles) {
        // En lugar de usar la lista "maintenances" privada (que dio error), 
        // usamos el método público que diseñamos para extraer de Hive
        allMaintenances.addAll(mProvider.getVehicleMaintenances('${v.brand}_${v.model}_${v.year}'));
      }
      
      // Llamar al nuevo servicio robusto de notificaciones
      await NotificationService.processAlerts(provider.vehicles, allMaintenances);
    });
  }

  // --- FUNCIÓN DE CIERRE DE SESIÓN SEGURO ---
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: '36297751205-kodn1bblam3k1qtuhm0o5mhrrbso2nb3.apps.googleusercontent.com',
        );
        await googleSignIn.signOut();
      } catch (_) {
        // Ignorado si no usó Google Sign-In
      }
    } catch (_) {
      // Manejo de errores de cierre de sesión
    }

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
            (route) => false,
      );
    }
  }

  // --- FUNCIÓN ACTUALIZADA PARA CARGAR EL LOGO POR MARCA CON COLOR DINÁMICO ---
  Widget _getModelAvatar(String vehicleType, String brand) {
    String normalizedBrand = brand.toLowerCase();
    String fileName = '${normalizedBrand.replaceAll(' ', '_')}.png';

    // Mapeo especial para marcas que no coinciden exactamente con el nombre o usan .jpg
    if (normalizedBrand == 'gac motor' || normalizedBrand == 'gac') {
      fileName = 'gac-group.png';
    } else if (normalizedBrand.contains('chery')) {
      fileName = 'chery.png';
    } else if (normalizedBrand == 'land rover') {
      fileName = 'land-rover.png';
    } else if (normalizedBrand == 'alfa romeo') {
      fileName = 'alfa-romeo.png';
    } else if (normalizedBrand == 'great wall') {
      fileName = 'great-wall.png';
    } else if (normalizedBrand == 'lada') {
      fileName = 'lada.jpg';
    } else if (normalizedBrand == 'aston martin') {
      fileName = 'aston-martin.png';
    }

    String assetPath = 'assets/logos/$fileName';
    
    // Detectamos si el modo oscuro está activo
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Lista de marcas que conservan sus colores originales en modo oscuro (NO se pintan de blanco)
    final List<String> excludedBrands = [
      'ford', 'fiat', 'jac', 'geely', 'mg', 'jetour', 'bmw', 'porsche', 'ram', 
      'subaru', 'volvo', 'mini', 'haval', 'ferrari', 'lamborghini', 'bentley', 
      'rolls-royce', 'bugatti', 'land rover', 'lada'
    ];

    bool shouldFilterToWhite = isDarkMode && !excludedBrands.contains(normalizedBrand);

    return Semantics(
      label: 'Logotipo de la marca $brand', // Accesibilidad para lectores de pantalla
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: shouldFilterToWhite
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcATop),
                child: _buildImage(assetPath, vehicleType),
              )
            : _buildImage(assetPath, vehicleType),
      ),
    );
  }

  Widget _buildImage(String assetPath, String vehicleType) {
    return Image.asset(
      assetPath,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          vehicleType == 'Moto' ? Icons.two_wheeler : Icons.directions_car,
          color: const Color(0xFFE50914),
          size: 32,
        );
      },
    );
  }

  // Icono para el menú lateral (ahora es una imagen según el tema)
  Widget _buildMenuIcon(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final imagePath = isDarkMode ? 'assets/logos/menu_dark.png' : 'assets/logos/menu_light.png';

    return Image.asset(
      imagePath,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback al icono clásico si no encuentra las imágenes nuevas
        return Icon(Icons.menu, color: Theme.of(context).primaryColor, size: 28);
      },
    );
  }

  // --- CONSTRUYE EL MENÚ LATERAL CON DATOS DINÁMICOS DE FIREBASE ---
  Widget _buildSidebar(bool isDesktop) {
    // 1. Obtenemos el usuario actual conectado desde Firebase
    final User? user = FirebaseAuth.instance.currentUser;

    // 2. Extraemos el nombre (o ponemos 'Usuario' si no tiene uno configurado)
    final String displayName = user?.displayName != null && user!.displayName!.isNotEmpty
        ? user.displayName!
        : 'Usuario';

    // 3. Extraemos el correo (o dejamos uno genérico si por alguna razón falla)
    final String displayEmail = user?.email ?? 'correo@noencontrado.com';

    // 4. Extraemos la foto de perfil (si inició sesión con Google la tendrá)
    final String? photoUrl = user?.photoURL;

    // Generamos llaves únicas para los elementos estáticos en lugar de reusar una GlobalKey
    return Container(
      width: 280,
      color: Theme.of(context).cardColor,
      child: Material(
        color: Colors.transparent,
        elevation: isDesktop ? 0 : 16,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
              accountEmail: Text(displayEmail, style: const TextStyle(color: Colors.black87)),
              currentAccountPicture: photoUrl != null
                  ? CircleAvatar(
                backgroundImage: NetworkImage(photoUrl),
              )
                  : const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: const Color(0xFFE50914)),
              ),
              decoration: const BoxDecoration(color: const Color(0xFFE50914)),
              margin: EdgeInsets.zero,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: [
                  ListTile(
                    leading: Icon(Icons.garage, color: _selectedIndex == 0 ? const Color(0xFFE50914) : Colors.grey),
                    title: Text('Mi Garaje', style: TextStyle(color: _selectedIndex == 0 ? const Color(0xFFE50914) : null, fontWeight: _selectedIndex == 0 ? FontWeight.bold : null)),
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() { _selectedIndex = 0; _isMenuOpen = false; }),
                  ),

                  // --- NAVEGACIÓN A PERFIL ---
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.grey),
                    title: const Text('Perfil'),
                    onTap: () {
                      setState(() { _selectedIndex = 1; _isMenuOpen = false; });
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ).then((_) => setState(() => _selectedIndex = 0));
                    },
                  ),

                  // --- NAVEGACIÓN A CONFIGURACIÓN ---
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text('Configuración y Seguridad'),
                    onTap: () {
                      setState(() { _selectedIndex = 2; _isMenuOpen = false; });
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ).then((_) => setState(() => _selectedIndex = 0));
                    },
                  ),
                  const Divider(),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      final bool isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;
                      return SwitchListTile(
                        activeColor: const Color(0xFFE50914),
                        secondary: Icon(isCurrentlyDark ? Icons.dark_mode : Icons.light_mode, color: Colors.grey),
                        title: Text(isCurrentlyDark ? 'Modo Oscuro' : 'Modo Claro'),
                        value: isCurrentlyDark,
                        onChanged: (value) => themeProvider.toggleTheme(value),
                      );
                    },
                  ),
                  const Divider(),

                  // --- NAVEGACIÓN A MANUAL Y SOPORTE ---
                  ListTile(
                    leading: const Icon(Icons.support_agent, color: Colors.grey),
                    title: const Text('Manual y Soporte'),
                    onTap: () {
                      setState(() { _selectedIndex = 3; _isMenuOpen = false; });
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupportScreen()),
                      ).then((_) => setState(() => _selectedIndex = 0));
                    },
                  ),

                  // --- NAVEGACIÓN A EMERGENCIA VIAL ---
                  ListTile(
                    leading: const Icon(Icons.minor_crash, color: Colors.redAccent),
                    title: const Text('Emergencia Vial', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () {
                      setState(() => _isMenuOpen = false);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()));
                    },
                  ),
                  const Divider(),

                  // --- BOTÓN DE CERRAR SESIÓN ---
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () => _signOut(context),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Vehio v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }

  // --- FUNCIÓN PARA NAVEGAR A AGREGAR VEHÍCULO ---
  void _navigateToAddVehicle() {
    final isPremium = Provider.of<SubscriptionProvider>(context, listen: false).isPremium;
    final vehicleCount = Provider.of<VehicleProvider>(context, listen: false).vehicles.length;

    if (!isPremium && vehicleCount >= 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen())).then((_) => setState((){}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final provider = Provider.of<VehicleProvider>(context);

    final filteredVehicles = provider.vehicles.where((v) {
      if (_selectedGarage == 0) return v.vehicleType == 'Auto';
      return v.vehicleType == 'Moto';
    }).toList();

    Widget mainContent = Scaffold(
      appBar: AppBar(
        title: const Text('Vehio', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 0,
        leading: isDesktop ? const SizedBox() : null,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // --- SELECTOR DEL GARAJE DUAL ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGarage = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedGarage == 0 ? const Color(0xFFE50914) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car, color: _selectedGarage == 0 ? Colors.black : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Autos', style: TextStyle(color: _selectedGarage == 0 ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGarage = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedGarage == 1 ? const Color(0xFFE50914) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.two_wheeler, color: _selectedGarage == 1 ? Colors.black : Colors.grey),
                            const SizedBox(width: 8),
                            Text('Motos', style: TextStyle(color: _selectedGarage == 1 ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- LISTA DE VEHÍCULOS DEL GARAJE ACTIVO ---
          Expanded(
            child: filteredVehicles.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_selectedGarage == 0 ? Icons.directions_car : Icons.two_wheeler, size: 100, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  Text('No tienes ${_selectedGarage == 0 ? "autos" : "motos"} aquí', style: const TextStyle(fontSize: 20, color: Colors.grey)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _navigateToAddVehicle,
                    icon: const Icon(Icons.add),
                    label: Text(_selectedGarage == 0 ? 'Agregar Auto' : 'Agregar Moto'),
                  )
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                final vehicle = filteredVehicles[index];

                int milesLeft = vehicle.nextServiceMileage - vehicle.mileage;
                bool needsService = milesLeft <= 500;

                // Calcular la barra de progreso. 
                // Usamos un intervalo de 5000 a 15000 para la visualización de la barra 
                // si no tenemos el dato exacto de la recarga, pero para que sea exacta al límite, 
                // calculamos el progreso invertido.
                double progress = 1.0;
                if (milesLeft > 0) {
                   // Fija un bloque visual estimado de 15000 como "salud total", y se va vaciando a 0
                   progress = (milesLeft / 15000.0).clamp(0.0, 1.0);
                }

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final uniqueKey = '${vehicle.brand}_${vehicle.model}_${vehicle.year}';
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle, vehicleKey: uniqueKey)),
                      ).then((_) => setState(() {}));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).cardColor,
                      ),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Usamos la función modificada pasando el brand
                                  _getModelAvatar(vehicle.vehicleType, vehicle.brand),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${vehicle.brand} ${vehicle.model}',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                                      ),
                                      Text(
                                          'Año ${vehicle.year}',
                                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey[700], fontSize: 14)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              PopupMenuButton<int>(
                                icon: Icon(Icons.more_vert, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54),
                                onSelected: (val) async {
                                  if (val == 1) {
                                    bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Eliminar Vehículo'),
                                        content: Text('¿Estás seguro de eliminar el vehículo "${vehicle.brand} ${vehicle.model}"? Esta acción borrará todos sus registros y no se puede deshacer.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      int realIndex = provider.vehicles.indexOf(vehicle);
                                      if (realIndex != -1) {
                                        provider.deleteVehicle(realIndex);
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 1, child: Text('Eliminar Vehículo', style: TextStyle(color: Colors.redAccent))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Odómetro: ${vehicle.mileage} ${vehicle.distanceUnit}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                              ),
                              if (needsService || milesLeft <= 1500)
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: milesLeft <= 0 ? Colors.redAccent : Colors.orangeAccent, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      milesLeft <= 0 ? 'Servicio Vencido' : 'Servicio Cerca', 
                                      style: TextStyle(color: milesLeft <= 0 ? Colors.redAccent : Colors.orangeAccent, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                )
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: milesLeft <= 0 ? 1.0 : progress,
                              minHeight: 8,
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                              color: milesLeft <= 0 
                                  ? Colors.redAccent 
                                  : (milesLeft <= 1500 ? Colors.orangeAccent : Colors.green), // Verde -> Naranja -> Rojo
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            milesLeft <= 0
                                ? '⚠️ Servicio vencido por ${milesLeft.abs()} ${vehicle.distanceUnit}'
                                : 'Faltan $milesLeft ${vehicle.distanceUnit} para el próximo servicio',
                            style: TextStyle(
                                color: milesLeft <= 0 
                                    ? Colors.redAccent 
                                    : (milesLeft <= 1500 ? Colors.orangeAccent : Colors.green), 
                                fontSize: 13,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddVehicle,
        icon: const Icon(Icons.add),
        label: Text(_selectedGarage == 0 ? 'Añadir Auto' : 'Añadir Moto'),
        backgroundColor: const Color(0xFFE50914),
        foregroundColor: Colors.white,
      ),
    );

    return Scaffold(
      body: isDesktop
          ? Row(
        children: [
          _buildSidebar(true),
          Expanded(child: mainContent),
        ],
      )
          : Stack(
        children: [
          mainContent,
          if (_isMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isMenuOpen = false),
              onHorizontalDragUpdate: (details) {
                if (details.primaryDelta! < -10) setState(() => _isMenuOpen = false);
              },
              child: Container(color: Colors.black54),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: _isMenuOpen ? 0 : -280,
            top: 0,
            bottom: 0,
            child: _buildSidebar(false),
          ),
          if (!_isMenuOpen)
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top + 8,
              child: GestureDetector(
                onTap: () => setState(() => _isMenuOpen = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
                  ),
                  child: _buildMenuIcon(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
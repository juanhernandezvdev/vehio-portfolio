import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../providers/subscription_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDefaultPackage();
    });
  }

  void _setDefaultPackage() {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    if (subProvider.packages.isNotEmpty) {
      // Buscamos el anual por defecto
      final yearly = subProvider.packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
      setState(() {
        _selectedPackage = yearly ?? subProvider.packages.first;
      });
    }
  }

  void _handlePurchase() async {
    if (_selectedPackage == null) return;
    
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    try {
      bool success = await subProvider.buyPackage(_selectedPackage!);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias! Bienvenido a Vehio Premium 🚀'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleRestore() async {
    final subProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    try {
      bool success = await subProvider.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Compras restauradas con éxito.' : 'No se encontraron compras previas.'),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
        if (success) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al restaurar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildFeatureRow(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE50914), size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final isYearly = package.packageType == PackageType.annual;
    final isSelected = _selectedPackage?.identifier == package.identifier;

    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = package),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x11E50914) : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? const Color(0xFFE50914) : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFE50914) : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isYearly ? 'Plan Anual' : 'Plan Mensual',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(4)),
                          child: const Text('AHORRA 16%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.storeProduct.priceString,
                    style: TextStyle(color: isSelected ? const Color(0xFFE50914) : Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);

    // Seleccionamos default si acabó de cargar
    if (_selectedPackage == null && subProvider.packages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setDefaultPackage());
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Vehio Premium', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFE50914),
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: Icon(Icons.workspace_premium, size: 80, color: Color(0xFFE50914))),
                        const SizedBox(height: 16),
                        const Text('Desbloquea el Control Total', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        _buildFeatureRow(Icons.directions_car, 'Garaje de vehículos ilimitados'),
                        _buildFeatureRow(Icons.cloud_sync, 'Respaldo seguro en la nube'),
                        _buildFeatureRow(Icons.picture_as_pdf, 'Generación de reportes detallados'),
                        _buildFeatureRow(Icons.block, 'Cero anuncios al usar la app'),
                        const SizedBox(height: 32),
                        const Text('Elige tu plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        if (subProvider.packages.isEmpty && !subProvider.isLoading)
                          const Center(child: Text('No hay planes disponibles en tu región en este momento.', style: TextStyle(color: Colors.red)))
                        else if (subProvider.packages.isNotEmpty)
                          ...subProvider.packages.map((p) => _buildPackageCard(p)),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: (_selectedPackage == null || subProvider.isLoading) ? null : _handlePurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CONTINUAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: subProvider.isLoading ? null : _handleRestore,
                        child: const Text('Restaurar Compras', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bloqueo total anti-doble clic
        if (subProvider.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
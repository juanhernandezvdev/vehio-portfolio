import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hive/hive.dart';
import '../models/maintenance_model.dart';
import '../models/vehicle_model.dart';
import '../providers/maintenance_provider.dart';
import '../providers/fuel_provider.dart';
import 'add_maintenance_screen.dart';
import 'add_fuel_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../models/document_model.dart';
import '../providers/document_provider.dart';
import 'premium_screen.dart';
import '../providers/subscription_provider.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  final String vehicleKey;

  const VehicleDetailScreen({super.key, required this.vehicle, required this.vehicleKey});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Escuchamos los cambios para detonar la animación del AnimatedSwitcher
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf(BuildContext context, double maintCost, double fuelCost) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Reporte de Mantenimiento y Gastos", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Vehículo: ${widget.vehicle.brand} ${widget.vehicle.model} (${widget.vehicle.year})"),
              pw.Text("Kilometraje Actual: ${widget.vehicle.mileage} ${widget.vehicle.distanceUnit}"),
              pw.SizedBox(height: 20),
              pw.Text("Resumen Financiero:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text("Gastos en Mantenimiento: \$${maintCost.toStringAsFixed(2)}"),
              pw.Text("Gastos en Combustible: \$${fuelCost.toStringAsFixed(2)}"),
              pw.Text("Gasto Total Histórico: \$${(maintCost + fuelCost).toStringAsFixed(2)}"),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // Animación Prémium para el cambio de pestañas
  Widget _buildAnimatedTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _getTabWidget(_tabController.index),
    );
  }

  Widget _getTabWidget(int index) {
    switch (index) {
      case 0:
        return _buildServicesTab(key: const ValueKey('tab_services'));
      case 1:
        return _buildGasTab(key: const ValueKey('tab_gas'));
      case 2:
        return _buildStatsTab(key: const ValueKey('tab_stats'));
      case 3:
        return _buildDocsTab(key: const ValueKey('tab_docs'));
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.brand} ${widget.vehicle.model}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar Reporte PDF',
            onPressed: () {
              final isPremium = Provider.of<SubscriptionProvider>(context, listen: false).isPremium;
              if (isPremium) {
                // Obtenemos los costos totales que ya se calculan en la UI
                final maintProvider = Provider.of<MaintenanceProvider>(context, listen: false);
                final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
                
                final mList = maintProvider.getVehicleMaintenances(widget.vehicleKey);
                final fList = fuelProvider.getVehicleFuelLogs(widget.vehicleKey);
                
                final double totalMaint = mList.fold(0, (sum, item) => sum + item.cost);
                final double totalFuel = fList.fold(0, (sum, item) => sum + item.totalCost);

                _generatePdf(context, totalMaint, totalFuel);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
              }
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE50914),
          labelColor: const Color(0xFFE50914),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.build), text: 'Servicios'),
            Tab(icon: Icon(Icons.local_gas_station), text: 'Gasolina'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.folder_shared), text: 'Docs'),
          ],
        ),
      ),
      body: Column(
        children: [
          Consumer2<MaintenanceProvider, FuelProvider>(
            builder: (context, maintProv, fuelProv, child) {
              final totalCost = maintProv.getTotalExpenses(widget.vehicleKey) + fuelProv.getTotalFuelCost(widget.vehicleKey);
              final double healthPct = maintProv.calculateVehicleHealth(widget.vehicle.mileage, widget.vehicle.nextServiceMileage, widget.vehicleKey);
              final Color healthColor = healthPct > 0.7 ? Colors.greenAccent : (healthPct > 0.4 ? const Color(0xFFE50914) : Colors.redAccent);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gasto Histórico Total', style: TextStyle(color: Colors.grey)),
                        Text('\$${totalCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFE50914))),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Salud del Vehículo', style: TextStyle(color: Colors.grey)),
                        Text('${(healthPct * 100).toInt()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: healthColor)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Aquí inyectamos nuestra animación prémium en lugar del TabBarView tradicional
          Expanded(
            child: _buildAnimatedTabContent(),
          ),
        ],
      ),
      floatingActionButton: PopupMenuButton<int>(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: const Color(0xFFE50914), shape: BoxShape.circle),
          child: const Icon(Icons.add, color: Colors.black),
        ),
        onSelected: (val) async {
          if (val == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddMaintenanceScreen(vehicle: widget.vehicle, vehicleKey: widget.vehicleKey)));
          } else if (val == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddFuelScreen(vehicle: widget.vehicle, vehicleKey: widget.vehicleKey)));
          } else if (val == 3) {
            try {
              final result = await FilePicker.platform.pickFiles();

              if (result != null && result.files.isNotEmpty) {
                final name = result.files.single.name;
                final path = result.files.single.path;

                if (path != null) {
                  final newDoc = VehicleDocument(title: name, filePath: path, vehicleKey: widget.vehicleKey);

                  if (!context.mounted) return;
                  Provider.of<DocumentProvider>(context, listen: false).addDocument(newDoc);
                }
              }
            } catch (e) {
              debugPrint("Error al seleccionar archivo: $e");
            }
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 1, child: Row(children: [Icon(Icons.build), SizedBox(width: 8), Text('Añadir Servicio')])),
          const PopupMenuItem(value: 2, child: Row(children: [Icon(Icons.local_gas_station), SizedBox(width: 8), Text('Añadir Gasolina')])),
          const PopupMenuItem(value: 3, child: Row(children: [Icon(Icons.upload_file), SizedBox(width: 8), Text('Subir Documento')])),
        ],
      ),
    );
  }

  // ==========================================
  // BLOQUES DE PESTAÑAS EXTRAÍDOS PARA LA ANIMACIÓN
  // ==========================================

  Widget _buildServicesTab({Key? key}) {
    return Consumer<MaintenanceProvider>(
      key: key,
      builder: (context, provider, child) {
        final history = provider.getVehicleMaintenances(widget.vehicleKey);
        
        // Agrupar los mantenimientos por título (en minúsculas para ignorar mayúsculas/minúsculas)
        // para saber cuál es el más reciente de cada tipo (por Odómetro)
        Map<String, Maintenance> latestMaintenances = {};
        for (var m in history) {
          final titleLower = m.title.trim().toLowerCase();
          if (!latestMaintenances.containsKey(titleLower) || m.mileageAtService > latestMaintenances[titleLower]!.mileageAtService) {
            latestMaintenances[titleLower] = m;
          }
        }

        if (history.isEmpty) return const Center(child: Text('Sin registros de servicio.'));
        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            final box = Hive.box<Maintenance>('maintenances_box');
            final realIndex = box.values.toList().indexOf(item);
            
            // Verificamos si este ítem es el más nuevo de su tipo
            bool isLatestOfItsType = latestMaintenances[item.title.trim().toLowerCase()] == item;

            return Dismissible(
              key: Key(item.key.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmar eliminación'),
                      content: Text('¿Estás seguro de eliminar el servicio "${item.title}" permanentemente?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                provider.deleteMaintenance(realIndex);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registro de servicio eliminado exitosamente')),
                );
              },
              child: ListTile(
                leading: Icon(
                  item.category == 'Electrónica' ? Icons.electrical_services :
                  item.category == 'Llantas' ? Icons.tire_repair : Icons.handyman,
                  color: isLatestOfItsType ? const Color(0xFFE50914) : Colors.grey,
                ),
                title: Text(item.title, style: TextStyle(fontWeight: isLatestOfItsType ? FontWeight.bold : FontWeight.normal)),
                trailing: Text('\$${item.cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${item.category} • ${item.date.day}/${item.date.month}/${item.date.year}\nOdómetro: ${item.mileageAtService} ${widget.vehicle.distanceUnit}', style: const TextStyle(fontSize: 12)),
                    if (item.description != null && item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '💬 "${item.description}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (item.nextReviewMileage != null)
                      Builder(
                          builder: (context) {
                            if (isLatestOfItsType) {
                              // Solo calculamos alertas si es el registro más nuevo de su tipo
                              int remaining = item.nextReviewMileage! - widget.vehicle.mileage;
                              bool isExpired = remaining <= 0;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  isExpired
                                      ? '⚠️ Vencido por ${remaining.abs()} ${widget.vehicle.distanceUnit}'
                                      : '⏳ Vida útil: Faltan $remaining ${widget.vehicle.distanceUnit}',
                                  style: TextStyle(
                                      color: isExpired ? Colors.redAccent : (remaining <= 1500 ? Colors.orangeAccent : Colors.green),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                  ),
                                ),
                              );
                            } else {
                              // Si es un registro viejo y ya hay uno más nuevo, lo marcamos como completado
                              return const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '✅ Completado / Reemplazado',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12
                                  ),
                                ),
                              );
                            }
                          }
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGasTab({Key? key}) {
    return Consumer<FuelProvider>(
      key: key,
      builder: (context, provider, child) {
        final fuelHistory = provider.getVehicleFuelLogs(widget.vehicleKey);
        if (fuelHistory.isEmpty) return const Center(child: Text('Sin registros de gasolina.'));

        double totalLiters = fuelHistory.fold(0, (sum, item) => sum + item.liters);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Consumido:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${totalLiters.toStringAsFixed(1)} Litros', style: const TextStyle(color: const Color(0xFFE50914), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: fuelHistory.length,
                itemBuilder: (context, index) {
                  final item = fuelHistory[index];

                  return Dismissible(
                    key: Key(item.key?.toString() ?? index.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: Text('¿Estás seguro de eliminar esta recarga de ${item.liters} Litros?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      provider.deleteFuelLog(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Carga de gasolina eliminada')),
                      );
                    },
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: const Color(0xFFE50914),
                        child: Icon(Icons.local_gas_station, size: 18, color: Colors.black),
                      ),
                      title: Text('${item.liters} Litros'),
                      subtitle: Text('${item.date.day}/${item.date.month}/${item.date.year}'),
                      trailing: Text(
                        '\$${item.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Nota legal: Vehio no se hace responsable por la veracidad, pérdida o la sensibilidad de las fotografías y documentos cargados en este apartado. El usuario asume toda la responsabilidad legal del contenido que almacene localmente en su dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsTab({Key? key}) {
    return Consumer2<MaintenanceProvider, FuelProvider>(
      key: key,
      builder: (context, maintProv, fuelProv, child) {
        final maintDocs = maintProv.getVehicleMaintenances(widget.vehicleKey);
        final fuelDocs = fuelProv.getVehicleFuelLogs(widget.vehicleKey);

        double totalFuel = fuelDocs.fold(0, (sum, item) => sum + item.totalCost);
        double totalMaint = maintDocs.fold(0, (sum, item) => sum + item.cost);
        double total = totalFuel + totalMaint;

        Map<String, double> maintByCategory = {};
        for (var m in maintDocs) {
          maintByCategory[m.category] = (maintByCategory[m.category] ?? 0) + m.cost;
        }

        final List<Color> proPalette = [
          const Color(0xFFE50914),
          const Color(0xFF00ACC1),
          const Color(0xFFAB47BC),
          const Color(0xFF26A69A),
          const Color(0xFFEF5350),
        ];
        int colorIndex = 0;

        List<PieChartSectionData> pieSections = [];
        if (totalFuel > 0) {
          pieSections.add(PieChartSectionData(
            value: totalFuel,
            title: 'Gasolina\n\$${totalFuel.toStringAsFixed(0)}',
            color: const Color(0xFF66BB6A),
            radius: 65,
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          ));
        }

        maintByCategory.forEach((category, cost) {
          if (cost > 0) {
            pieSections.add(PieChartSectionData(
              value: cost,
              title: '$category\n\$${cost.toStringAsFixed(0)}',
              color: proPalette[colorIndex % proPalette.length],
              radius: 65,
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ));
            colorIndex++;
          }
        });

        if (total == 0) {
          return const Center(child: Text('Agrega gastos para ver las estadísticas.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Distribución Financiera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 230,
                      child: PieChart(
                        PieChartData(
                          sections: pieSections,
                          centerSpaceRadius: 45,
                          sectionsSpace: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Gasto Total Histórico: \$${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE50914))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Historial Detallado de Mantenimientos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            maintDocs.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text('No hay servicios registrados aún.')),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: maintDocs.length,
              itemBuilder: (context, index) {
                final item = maintDocs[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: const Color(0xFFE50914),
                      child: Icon(Icons.build, color: Colors.black, size: 18),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categoría: ${item.category} • Fecha: ${item.date.day}/${item.date.month}/${item.date.year}\nOdómetro: ${item.mileageAtService} ${widget.vehicle.distanceUnit}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        if (item.description != null && item.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '💬 "${item.description}"',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      '\$${item.cost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFE50914)),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocsTab({Key? key}) {
    return Consumer<DocumentProvider>(
      key: key,
      builder: (context, provider, child) {
        final docs = provider.getVehicleDocuments(widget.vehicleKey);
        if (docs.isEmpty) return const Center(child: Text('Sin documentos guardados.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final realIndex = Hive.box<VehicleDocument>('documents_box').values.toList().indexOf(doc);
            return ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              title: Text(doc.title),
              subtitle: const Text('Toca para abrir archivo'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => provider.deleteDocument(realIndex),
              ),
              onTap: () => OpenFilex.open(doc.filePath),
            );
          },
        );
      },
    );
  }
}
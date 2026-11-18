import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_model.dart';
import '../models/vehicle_model.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';

class _PendingTask {
  final String title;
  final String category;
  final double cost;
  final int? nextReview;
  final String? description;

  _PendingTask({
    required this.title,
    required this.category,
    required this.cost,
    this.nextReview,
    this.description,
  });
}

class AddMaintenanceScreen extends StatefulWidget {
  final Vehicle vehicle;
  final String vehicleKey;
  final Maintenance? maintenanceToEdit;
  final int? editIndex;

  const AddMaintenanceScreen({
    super.key,
    required this.vehicle,
    required this.vehicleKey,
    this.maintenanceToEdit,
    this.editIndex,
  });

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  final _nextReviewController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Mecánica';
  
  // Lista de tareas agrupadas a registrar en esta misma visita
  List<_PendingTask> _pendingTasks = [];

  final List<String> _categories = ['Mecánica', 'Electrónica', 'Llantas', 'Estética', 'Varios', 'Otros'];

  // Lista dinámica de chips rápidos (permite agregar servicios personalizados)
  final List<String> _quickChips = [
    'Cambio de aceite',
    'Cambio de pastillas de freno',
    'Reemplazo de batería',
    'Alineación y balanceo',
    'Cambio de filtros',
    'Cambio de bujías',
    'Revisión general',
  ];

  void _addCustomChip() {
    final text = _titleController.text.trim();
    if (text.isNotEmpty) {
      if (!_quickChips.contains(text)) {
        setState(() {
          _quickChips.add(text);
          _titleController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡"$text" añadido como chip rápido!'), duration: const Duration(seconds: 2)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este servicio ya está en los chips rápidos'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.maintenanceToEdit != null) {
      _titleController.text = widget.maintenanceToEdit!.title;
      _costController.text = widget.maintenanceToEdit!.cost.toString();
      _mileageController.text = widget.maintenanceToEdit!.mileageAtService.toString();
      _selectedDate = widget.maintenanceToEdit!.date;
      _selectedCategory = widget.maintenanceToEdit!.category;
      _descriptionController.text = widget.maintenanceToEdit!.description ?? '';

      if (widget.maintenanceToEdit!.nextReviewMileage != null) {
        int relativeLife = widget.maintenanceToEdit!.nextReviewMileage! - widget.maintenanceToEdit!.mileageAtService;
        _nextReviewController.text = relativeLife > 0 ? relativeLife.toString() : '';
      }
    } else {
      _mileageController.text = widget.vehicle.mileage.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    _nextReviewController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.maintenanceToEdit != null;
    final unit = widget.vehicle.distanceUnit;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Servicio' : 'Registrar Servicio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Servicio realizado',
                  prefixIcon: Icon(Icons.build),
                  errorStyle: TextStyle(color: Colors.redAccent, fontSize: 12),
                  counterText: '',
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(80),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '⚠️ El nombre del servicio es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // --- SUGERENCIAS RÁPIDAS PREDETERMINADAS Y DINÁMICAS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Sugerencias rápidas:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addCustomChip,
                    icon: const Icon(Icons.add_circle_outline, size: 14),
                    label: const Text('Añadir chip', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 30)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _quickChips.map((String text) {
                  return ActionChip(
                    label: Text(text, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[200],
                    onPressed: () {
                      _titleController.text = text;
                      // Autoseleccionamos la categoría más lógica según el texto
                      final tLower = text.toLowerCase();
                      if (tLower.contains('batería') || tLower.contains('bateria')) {
                        setState(() => _selectedCategory = 'Electrónica');
                      } else if (tLower.contains('aceite') || tLower.contains('freno') || tLower.contains('filtros') || tLower.contains('bujías') || tLower.contains('bujia')) {
                        setState(() => _selectedCategory = 'Mecánica');
                      } else if (tLower.contains('alineación') || tLower.contains('llantas')) {
                        setState(() => _selectedCategory = 'Llantas');
                      } else if (tLower.contains('pintura') || tLower.contains('estética') || tLower.contains('estetica')) {
                        setState(() => _selectedCategory = 'Estética');
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category)),
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fecha', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        labelText: 'Costo (\$)',
                        prefixIcon: Icon(Icons.attach_money),
                        errorStyle: TextStyle(color: Colors.redAccent, fontSize: 12),
                        counterText: '',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '⚠️ Requerido';
                        }
                        if (double.tryParse(value) == null || double.parse(value) < 0) {
                          return '⚠️ Costo inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _mileageController,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'Odómetro en servicio',
                        suffixText: unit,
                        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '⚠️ Requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return '⚠️ Solo números';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nextReviewController,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'Vida útil de la pieza / Duración (Opcional)',
                  prefixIcon: const Icon(Icons.warning_amber),
                  suffixText: unit,
                  helperText: 'Ej: Escribe 8000. La app calculará la meta sola sumándolo al odómetro.',
                  errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (value) {
                  // Si el usuario escribe algo, validamos que sea un número entero positivo
                  if (value != null && value.isNotEmpty) {
                    final lifespan = int.tryParse(value);
                    if (lifespan == null || lifespan <= 0) {
                      return '⚠️ Ingresa un número mayor a 0';
                    }
                    
                    // Validación específica para Cambio de Aceite (Máximo 15000 km)
                    final titleLower = _titleController.text.toLowerCase();
                    if (titleLower.contains('aceite') && lifespan > 15000) {
                      return '⚠️ El aceite dura máximo 15,000 $unit';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLength: 150,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Servicio / Comentarios',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                  helperText: 'Notas, observaciones o detalles que quieras recordar de este servicio.',
                  counterText: '',
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(150),
                ],
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final currentInputMileage = int.parse(_mileageController.text);
                    int? nextReview;

                    if (_nextReviewController.text.isNotEmpty) {
                      int lifespan = int.parse(_nextReviewController.text);
                      nextReview = currentInputMileage + lifespan;
                    }

                    // Si el título contiene " + ", se agruparon múltiples servicios, por lo que la categoría pasa a ser "Varios"
                    final finalCategory = _titleController.text.contains(' + ') ? 'Varios' : _selectedCategory;

                    final maintenance = Maintenance(
                      title: _titleController.text,
                      date: _selectedDate,
                      cost: double.parse(_costController.text),
                      mileageAtService: currentInputMileage,
                      vehicleKey: widget.vehicleKey,
                      category: finalCategory,
                      nextReviewMileage: nextReview,
                      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
                    );

                    final provider = Provider.of<MaintenanceProvider>(context, listen: false);

                    if (isEditing) {
                      provider.editMaintenance(widget.editIndex!, maintenance);
                    } else {
                      provider.addMaintenance(maintenance);
                    }

                    // Actualizar el vehículo
                    bool vehicleChanged = false;
                    if (currentInputMileage > widget.vehicle.mileage) {
                      widget.vehicle.mileage = currentInputMileage;
                      vehicleChanged = true;
                    }
                    
                    // Lógica para actualizar el kilometraje del próximo servicio del vehículo 
                    // solo si es un cambio de aceite principal y no está agrupado.
                    final titleLower = _titleController.text.toLowerCase();
                    final isGrouped = _titleController.text.contains(' + ');
                    
                    if (!isGrouped && nextReview != null && (titleLower.contains('aceite') || titleLower.contains('servicio general') || titleLower.contains('mantenimiento general'))) {
                      widget.vehicle.nextServiceMileage = nextReview;
                      vehicleChanged = true;
                    }

                    if (vehicleChanged) {
                      widget.vehicle.save();
                      // Recargamos los vehículos para que los providers notifiquen a la UI
                      Provider.of<VehicleProvider>(context, listen: false).loadVehicles();
                    }
                    
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Guardar Registro', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
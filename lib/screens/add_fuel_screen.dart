import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/fuel_model.dart';
import '../models/vehicle_model.dart';
import '../providers/fuel_provider.dart';

class AddFuelScreen extends StatefulWidget {
  final Vehicle vehicle;
  final String vehicleKey;

  const AddFuelScreen({super.key, required this.vehicle, required this.vehicleKey});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mileageController.text = widget.vehicle.mileage.toString();
  }

  @override
  void dispose() {
    _litersController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Combustible')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _litersController,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Litros cargados',
                  prefixIcon: Icon(Icons.local_gas_station),
                  errorStyle: TextStyle(color: Colors.redAccent, fontSize: 12),
                  counterText: '',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '⚠️ Este campo es obligatorio';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return '⚠️ Ingresa una cantidad de litros válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'Costo Total (\$)',
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
                    return '⚠️ El costo total es obligatorio';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return '⚠️ Ingresa un costo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mileageController,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'Kilometraje al cargar',
                  prefixIcon: Icon(Icons.speed),
                  errorStyle: TextStyle(color: Colors.redAccent, fontSize: 12),
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '⚠️ El kilometraje es obligatorio';
                  }
                  final mileage = int.tryParse(value);
                  if (mileage == null) {
                    return '⚠️ Ingresa solo números enteros';
                  }
                  if (mileage < widget.vehicle.mileage) {
                    return '⚠️ No puede ser menor al kilometraje actual (${widget.vehicle.mileage})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final currentInputMileage = int.parse(_mileageController.text);

                    // 1. Guardar el registro de gasolina
                    final newLog = FuelLog(
                      date: _selectedDate,
                      liters: double.parse(_litersController.text),
                      totalCost: double.parse(_costController.text),
                      currentMileage: currentInputMileage,
                      vehicleKey: widget.vehicleKey,
                    );
                    Provider.of<FuelProvider>(context, listen: false).addFuelLog(newLog);

                    // 2. ACTUALIZAR ODOMETRO
                    if (currentInputMileage > widget.vehicle.mileage) {
                      widget.vehicle.mileage = currentInputMileage;
                      widget.vehicle.save();
                    }

                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Guardar Repostaje', style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
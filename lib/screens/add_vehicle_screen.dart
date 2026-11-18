import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_model.dart';
import '../providers/vehicle_provider.dart';
import 'package:flutter/services.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- CATÁLOGOS MANUALES EXPANDIDOS ---
  final Map<String, List<String>> _autoCatalog = {
    'Toyota': ['Corolla', 'Hilux', 'Fortuner', '4Runner', 'Yaris', 'Land Cruiser', 'Merú', 'Autana', 'Prado', 'Tacoma', 'Camry', 'Sequoia', 'Rav4', 'Avalon', 'Tundra', 'Highlander', 'FJ Cruiser', 'Otro'],
    'Chevrolet': ['Aveo', 'Optra', 'Cruze', 'Silverado', 'Tahoe', 'Spark', 'Corsa', 'Grand Vitara', 'Suburban', 'Equinox', 'Tracker', 'Malibu', 'Chevelle', 'Caprice', 'Blazer', 'Colorado', 'Groove', 'Otro'],
    'Ford': ['Fiesta', 'Explorer', 'F-150', 'Ranger', 'Mustang', 'EcoSport', 'Ka', 'Bronco', 'Escape', 'Fusion', 'Focus', 'Edge', 'Expedition', 'Super Duty', 'Raptor', 'Falcon', 'Maverick', 'Otro'],
    'Hyundai': ['Tucson', 'Elantra', 'Getz', 'Santa Fe', 'Accent', 'Creta', 'Sonata', 'Veloster', 'Palisade', 'Kona', 'Grand i10', 'H1', 'Otro'],
    'Mitsubishi': ['Lancer', 'Montero', 'Signo', 'Outlander', 'Panel', 'Galant', 'Eclipse', 'ASX', 'L200', 'Space Wagon', 'Otro'],
    'Kia': ['Sportage', 'Rio', 'Picanto', 'Cerato', 'Optima', 'Seltos', 'Sorento', 'Soul', 'Carnival', 'Telluride', 'Stinger', 'Otro'],
    'Honda': ['Civic', 'CR-V', 'Accord', 'Fit', 'Pilot', 'HR-V', 'Odyssey', 'Ridgeline', 'Prelude', 'S2000', 'Otro'],
    'Jeep': ['Grand Cherokee', 'Cherokee', 'Wrangler', 'Compass', 'Renegade', 'Gladiator', 'Commander', 'Liberty', 'Patriot', 'CJ7', 'Otro'],
    'Nissan': ['Frontier', 'Patrol', 'Sentra', 'Kicks', 'Tiida', 'Versa', 'Murano', 'Pathfinder', 'X-Trail', 'Xterra', 'Maxima', 'Rogue', 'Altima', 'Otro'],
    'Fiat': ['Palio', 'Siena', 'Uno', 'Fiorino', 'Punto', 'Strada', 'Idea', 'Bravo', 'Ducato', 'Toro', 'Mobi', 'Argo', 'Otro'],
    'Mazda': ['Mazda 3', 'Mazda 6', 'BT-50', 'Allegro', 'CX-3', 'CX-5', 'CX-9', 'CX-30', 'MX-5 Miata', 'RX-7', 'RX-8', 'Otro'],
    'Volkswagen': ['Gol', 'Jetta', 'Fox', 'Bora', 'Polo', 'Passat', 'Amarok', 'Tiguan', 'Beetle', 'Golf', 'Saveiro', 'Touareg', 'Otro'],
    'Renault': ['Logan', 'Twingo', 'Megane', 'Clio', 'Duster', 'Sandero', 'Kwid', 'Captur', 'Symbol', 'Scenic', 'Kangoo', 'Otro'],
    'Chery': ['Orinoco', 'Arauca', 'Tiggo', 'Grand Tiggo', 'X1', 'Qq', 'Tiggo 2', 'Tiggo 7', 'Tiggo 8', 'Arrizo', 'Otro'],
    'JAC': ['S2', 'S3', 'T8', 'JS4', 'S4', 'S7', 'T6', 'J4', 'Otro'],
    'Changan': ['Alsvin', 'CS15', 'CS35', 'Hunter', 'CS55', 'CS75', 'Eado', 'Uni-T', 'Otro'],
    'Dongfeng': ['S50', 'Rich 6', 'AX7', 'Joyear', 'DFSK', 'Otro'],
    'Geely': ['CK', 'MK', 'Coolray', 'Emgrand', 'Atlas', 'Azkarra', 'Tugella', 'Otro'],
    'MG': ['MG3', 'ZS', 'HS', 'MG5', 'RX5', 'GT', 'Cyberster', 'Otro'],
    'Jetour': ['X70', 'X70 Plus', 'X90', 'Dashing', 'Otro'],
    'GAC Motor': ['GS3', 'GS8', 'Emkoo', 'Empow', 'Otro'],
    'Chery / Chery International': ['Arrizo 5', 'Tiggo 4 Pro', 'Otro'],
    'Mercedes-Benz': ['Clase A', 'Clase C', 'Clase E', 'Clase G', 'Clase S', 'GLE', 'GLS', 'GLC', 'GLA', 'CLA', 'AMG GT', 'Sprinter', 'Otro'],
    'BMW': ['Serie 1', 'Serie 2', 'Serie 3', 'Serie 4', 'Serie 5', 'Serie 7', 'X1', 'X3', 'X4', 'X5', 'X6', 'X7', 'Z4', 'M2', 'M3', 'M4', 'M5', 'Otro'],
    'Audi': ['A1', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'Q2', 'Q3', 'Q5', 'Q7', 'Q8', 'TT', 'R8', 'RS3', 'RS6', 'Otro'],
    'Porsche': ['Cayenne', 'Macan', '911', 'Panamera', 'Taycan', 'Boxster', 'Cayman', 'Otro'],
    'Lexus': ['IS', 'ES', 'LS', 'NX', 'RX', 'GX', 'LX570', 'LX600', 'GX460', 'UX', 'Otro'],
    'Land Rover': ['Range Rover', 'Range Rover Sport', 'Defender', 'Discovery', 'Evoque', 'Velar', 'Freelander', 'Otro'],
    'RAM': ['1500', '2500', '3500', 'TRX', 'Rebel', 'ProMaster', 'Otro'],
    'Subaru': ['Impreza', 'Forester', 'Outback', 'XV', 'Crosstrek', 'WRX', 'BRZ', 'Legacy', 'Otro'],
    'Volvo': ['XC40', 'XC60', 'XC90', 'S60', 'S90', 'V40', 'C40', 'Otro'],
    'Alfa Romeo': ['Giulia', 'Stelvio', 'Tonale', 'Giulietta', 'Otro'],
    'Mini': ['Cooper', 'Countryman', 'Clubman', 'Paceman', 'Otro'],
    'Tesla': ['Model S', 'Model 3', 'Model X', 'Model Y', 'Cybertruck', 'Otro'],
    'BYD': ['Song Plus', 'Yuan Plus', 'Han', 'Tang', 'Qin', 'Dolphin', 'Seagull', 'King', 'Otro'],
    'Haval': ['H6', 'Jolion', 'H9', 'Big Dog', 'Otro'],
    'Great Wall': ['Wingle 5', 'Wingle 7', 'Poer', 'Safe', 'Hover', 'Otro'],
    'Daewoo': ['Cielo', 'Lanos', 'Matiz', 'Nubira', 'Leganza', 'Tacuma', 'Otro'],
    'Lada': ['Niva', 'Samara', '1200', 'Priora', 'Otro'],
    'Ferrari': ['458 Italia', '488', 'F8 Tributo', 'Roma', 'Portofino', 'SF90', 'Purosangue', 'LaFerrari', 'Otro'],
    'Lamborghini': ['Urus', 'Huracán', 'Aventador', 'Revuelto', 'Gallardo', 'Murciélago', 'Otro'],
    'Maserati': ['Ghibli', 'Levante', 'Quattroporte', 'MC20', 'Grecale', 'GranTurismo', 'Otro'],
    'Bentley': ['Continental GT', 'Bentayga', 'Flying Spur', 'Mulsanne', 'Otro'],
    'Rolls-Royce': ['Phantom', 'Ghost', 'Cullinan', 'Wraith', 'Dawn', 'Spectre', 'Otro'],
    'Aston Martin': ['DB11', 'DB12', 'Vantage', 'DBS', 'DBX', 'Valhalla', 'Otro'],
    'McLaren': ['720S', '750S', 'Artura', 'GT', 'P1', 'Senna', 'Otro'],
    'Bugatti': ['Chiron', 'Veyron', 'Tourbillon', 'Divo', 'Bolide', 'Otro'],
    'Otro': ['Modelo Personalizado'],
  };

  final Map<String, List<String>> _motoCatalog = {
    'Empire Keeway': ['Horse', 'Owen', 'Arsen', 'TX', 'Outlook', 'RKV', 'Superlight', 'Matrix', 'EK Express', 'Owen 150', 'Horse 150', 'Horse KW', 'Otro'],
    'Bera': ['SBR', 'BR 150', 'León', 'Socialista', 'Merú', 'Bera 200', 'Bera 250', 'Cripton', 'R1', 'Jaguar', 'Bera Gts', 'Otro'],
    'Toro': ['TR 150', 'Rex', 'León', 'Cuervo', 'Toro 200', 'Toro Enduro', 'Toro Xpress', 'Otro'],
    'MD': ['Cóndor', 'Águila', 'Gavilán', 'Trepador', 'Haojin', 'Tucán', 'Cardenal', 'Falcón', 'Lechuza', 'Otro'],
    'Escuda': ['150', '200', 'Fox', 'Shark', 'Otro'],
    'Skygo': ['SG 150', 'Executive', 'Knight', 'Nomad', 'Phoenix', 'Otro'],
    'Ava': ['150', 'León', 'Tornado', 'Ava 200', 'Otro'],
    'UM': ['Renegade', 'DSR', 'Max', 'Duty', 'Fastwind', 'Xtreet', 'Otro'],
    'Suzuki': ['GN 125', 'EN 125', 'V-Strom 650', 'V-Strom 1050', 'DR 650', 'GSX-R 600', 'GSX-R 750', 'GSX-R 1000', 'Gixxer 150', 'Gixxer 250', 'AX 100', 'Hayabusa', 'Katana', 'Burgman', 'Inazuma', 'Marauder', 'Otro'],
    'Yamaha': ['DT 175', 'XTZ 125', 'XTZ 250 Lander', 'MT-03', 'MT-07', 'MT-09', 'MT-10', 'R3', 'R1', 'R6', 'FZ 16', 'FZ-S', 'Ténéré 700', 'Crypton', 'BWS', 'TMAX', 'XMAX', 'FJR 1300', 'V-Max', 'Virago', 'DragStar', 'Otro'],
    'Honda': ['CB 190R', 'CB 160F', 'XR 150', 'XR 190', 'Tornado 250', 'Africa Twin', 'CBR 600RR', 'CBR 1000RR', 'Transalp', 'Navi', 'Dio', 'PCX 150', 'Gold Wing', 'Rebel 300', 'Rebel 500', 'Shadow 750', 'CB 500X', 'CB 650R', 'CBR 500R', 'NC 750X', 'Varadero', 'Otro'],
    'Kawasaki': ['KLR 650', 'Versys 300', 'Versys 650', 'Versys 1000', 'Ninja 300', 'Ninja 400', 'Ninja 650', 'Ninja ZX-6R', 'Ninja ZX-10R', 'Z300', 'Z400', 'Z650', 'Z900', 'Z1000', 'Vulcan S', 'Eliminator', 'KLX 250', 'Brute Force', 'Otro'],
    'Bajaj': ['Pulsar NS 200', 'Pulsar NS 160', 'Pulsar N 250', 'Pulsar RS 200', 'Rouser 200', 'Boxer 100', 'Boxer CT 100', 'Dominar 400', 'Dominar 250', 'Discover 125', 'Platina 100', 'Otro'],
    'Royal Enfield': ['Himalayan 410', 'Himalayan 450', 'Interceptor 650', 'Continental GT 650', 'Classic 350', 'Meteor 350', 'Hunter 350', 'Super Meteor 650', 'Bullet 350', 'Scram 411', 'Otro'],
    'TVS': ['Apache RTR 160', 'Apache RTR 180', 'Apache RTR 200 4V', 'Apache RR 310', 'Raider 125', 'Ntorq 125', 'Wego', 'HLX 150', 'Otro'],
    'CFMoto': ['NK 300', 'NK 400', 'NK 650', 'MT 450', 'MT 650', 'MT 800', 'CL-X 700', 'Papio', 'ST 125', 'Otro'],
    'Zontes': ['T310', 'T350', 'R310', 'R350', 'X310', 'GK 350', 'S350', '350E', 'Otro'],
    'Benelli': ['TRK 502', 'TRK 502X', 'TRK 702', 'Leoncino 250', 'Leoncino 500', 'TNT 135', 'TNT 300', '302S', 'Imperiale 400', '502C', 'Otro'],
    'Kymco': ['Agility 125', 'Agility RS', 'AK 550', 'Downtown 350i', 'Like 150i', 'Xciting S 400', 'People S', 'Grand Dink', 'Otro'],
    'Vespa': ['Primavera 150', 'GTS 300', 'Sprint 150', 'LX 125', 'Elettrica', '946', 'Otro'],
    'BMW Motorrad': ['R 1250 GS', 'R 1300 GS', 'R 1250 GS Adventure', 'F 750 GS', 'F 850 GS', 'F 900 GS', 'S 1000 RR', 'S 1000 XR', 'S 1000 R', 'R 12', 'R 18', 'G 310 R', 'G 310 GS', 'C 400 X', 'K 1600 GTL', 'Otro'],
    'KTM': ['Duke 200', 'Duke 250', 'Duke 390', 'Duke 790', 'Duke 890', 'Adventure 390', 'Adventure 790', 'Adventure 890', 'Adventure 1290', 'EXC 250', 'EXC 350', 'RC 200', 'RC 390', 'Super Duke 1290', 'Super Duke 1390', 'Otro'],
    'Ducati': ['Multistrada V2', 'Multistrada V4', 'Monster 821', 'Monster 937', 'Panigale V2', 'Panigale V4', 'Scrambler Icon', 'Scrambler Full Throttle', 'Streetfighter V2', 'Streetfighter V4', 'Diavel V4', 'DesertX', 'Hypermotard', 'SuperSport', 'Otro'],
    'Triumph': ['Tiger 850 Sport', 'Tiger 900', 'Tiger 1200', 'Bonneville T100', 'Bonneville T120', 'Speed Twin 900', 'Speed Twin 1200', 'Scrambler 900', 'Scrambler 1200', 'Speed Triple 1200', 'Street Triple 765', 'Trident 660', 'Rocket 3', 'Otro'],
    'Harley-Davidson': ['Sportster S', 'Iron 883', 'Forty-Eight', 'Fat Boy 114', 'Fat Bob 114', 'Street Glide', 'Road Glide', 'Road King', 'Pan America 1250', 'Nightster', 'Breakout', 'Heritage Classic', 'Tri Glide', 'Otro'],
    'Aprilia': ['RSV4 Factory', 'Tuono V4', 'Tuono 660', 'RS 660', 'RS 125', 'Caponord', 'Dorsoduro', 'SX 125', 'RX 125', 'Otro'],
    'Husqvarna': ['Svartpilen 200', 'Svartpilen 401', 'Vitpilen 401', 'Norden 901', 'TE 300', 'FE 450', 'FC 250', 'Otro'],
    'GasGas': ['EC 250', 'EC 300', 'MC 125', 'MC 250F', 'SM 700', 'ES 700', 'Otro'],
    'Moto Guzzi': ['V7 Stone', 'V7 Special', 'V85 TT', 'V100 Mandello', 'Audace', 'California', 'Otro'],
    'Indian Motorcycle': ['Scout 60', 'Scout Bobber', 'Chief Dark Horse', 'Challenger', 'Roadmaster', 'FTR 1200', 'Otro'],
    'Husaberg': ['FE 390', 'FE 570', 'TE 300', 'Otro'],
    'Sym': ['Crox 125', 'Jet 14', 'Maxsym 400', 'Fiddle III', 'Joymax Z', 'Otro'],
    'Loncin': ['LX 250', 'GP 300', 'Otro'],
    'QJ Motor': ['SRK 400', 'SRT 550', 'SRT 800', 'SRV 300', 'Otro'],
    'Otro': ['Modelo Personalizado'],
  };

  String _vehicleType = 'Auto'; // 'Auto' o 'Moto'
  String? _selectedBrand;
  String? _selectedModel;
  String _selectedUnit = 'km';
  bool _isLoading = false;

  // Controladores únicamente para los campos numéricos
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _nextServiceController = TextEditingController(text: '5000');

  Map<String, List<String>> get _currentCatalog => _vehicleType == 'Auto' ? _autoCatalog : _motoCatalog;

  @override
  void dispose() {
    _yearController.dispose();
    _mileageController.dispose();
    _nextServiceController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN SEGURA DE GUARDADO ---
  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBrand == null || _selectedBrand!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa o selecciona una marca'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedModel == null || _selectedModel!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa o selecciona un modelo'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final newVehicle = Vehicle(
          brand: _selectedBrand!,
          model: _selectedModel!,
          year: int.parse(_yearController.text),
          mileage: int.parse(_mileageController.text),
          distanceUnit: _selectedUnit,
          nextServiceMileage: int.parse(_mileageController.text) + int.parse(_nextServiceController.text),
          vehicleType: _vehicleType,
        );

        await Provider.of<VehicleProvider>(context, listen: false).addVehicle(newVehicle);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_vehicleType == 'Auto' ? 'Auto' : 'Moto'} guardado con éxito'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el vehículo: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vehicleType == 'Auto' ? 'Configurar Nuevo Auto' : 'Configurar Nueva Moto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- SELECTOR DE TIPO (AUTO / MOTO) ---
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _vehicleType = 'Auto';
                            _selectedBrand = null;
                            _selectedModel = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _vehicleType == 'Auto' ? const Color(0xFFE50914) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car, color: _vehicleType == 'Auto' ? Colors.black : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Auto', style: TextStyle(color: _vehicleType == 'Auto' ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _vehicleType = 'Moto';
                            _selectedBrand = null;
                            _selectedModel = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _vehicleType == 'Moto' ? const Color(0xFFE50914) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.two_wheeler, color: _vehicleType == 'Moto' ? Colors.black : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Moto', style: TextStyle(color: _vehicleType == 'Moto' ? Colors.black : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- AUTOCOMPLETE DE MARCA ---
              Autocomplete<String>(
                key: ValueKey('brand_autocomplete_$_vehicleType'),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _currentCatalog.keys;
                  }
                  return _currentCatalog.keys.where((String brand) {
                    return brand.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _selectedBrand = selection;
                    _selectedModel = null;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: _vehicleType == 'Auto' ? 'Marca del Auto' : 'Marca de la Moto',
                      prefixIcon: Icon(_vehicleType == 'Auto' ? Icons.directions_car : Icons.two_wheeler),
                      helperText: 'Escribe para buscar o agregar una marca',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedBrand = value;
                        _selectedModel = null;
                      });
                    },
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingresa o selecciona una marca' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- AUTOCOMPLETE DE MODELO ---
              Autocomplete<String>(
                key: ValueKey('model_autocomplete_$_vehicleType'),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final List<String> availableModels = (_selectedBrand != null && _currentCatalog.containsKey(_selectedBrand))
                      ? _currentCatalog[_selectedBrand]!
                      : ['Modelo Personalizado'];

                  if (textEditingValue.text.isEmpty) {
                    return availableModels;
                  }
                  return availableModels.where((String model) {
                    return model.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _selectedModel = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      prefixIcon: Icon(Icons.style),
                      helperText: 'Escribe o selecciona un modelo',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedModel = value;
                      });
                    },
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingresa o selecciona un modelo' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // --- AÑO ---
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Año (ej. 2005)', prefixIcon: Icon(Icons.calendar_today)),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length != 4) return 'Debe tener 4 dígitos';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- KILOMETRAJE Y UNIDAD ---
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _mileageController,
                      maxLength: 8,
                      decoration: const InputDecoration(labelText: 'Kilometraje Actual', prefixIcon: Icon(Icons.speed), counterText: ''),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: const [
                        DropdownMenuItem(value: 'km', child: Text('Km')),
                        DropdownMenuItem(value: 'mi', child: Text('Millas')),
                      ],
                      onChanged: (val) => setState(() => _selectedUnit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- ALERTA DE SERVICIO ---
              TextFormField(
                controller: _nextServiceController,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'Alerta Próximo Servicio cada:',
                  prefixIcon: const Icon(Icons.notifications_active),
                  helperText: 'Rango permitido: 5000 a 15000 $_selectedUnit',
                  suffixText: _selectedUnit,
                  counterText: '',
                  errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
                  final interval = int.tryParse(value);
                  if (interval == null) {
                    return '⚠️ Ingresa un número válido';
                  }
                  if (interval < 5000 || interval > 15000) {
                    return '⚠️ El rango debe ser entre 5000 y 15000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // --- BOTÓN DE GUARDAR ---
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveVehicle,
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
                    : const Icon(Icons.save),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _isLoading ? 'Guardando...' : 'Guardar ${_vehicleType == 'Auto' ? 'Auto' : 'Moto'} en Vehio',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
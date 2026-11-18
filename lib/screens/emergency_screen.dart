import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergencia Vial')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Guía rápida de acción',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.tire_repair, color: const Color(0xFFE50914)),
              title: Text('Cómo cambiar un caucho espichado', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "1. Oríllate en un lugar seguro y plano.\n"
                        "2. Enciende las luces de emergencia y coloca el triángulo de seguridad.\n"
                        "3. Afloja las tuercas antes de levantar el vehículo.\n"
                        "4. Coloca el gato hidráulico en el punto de apoyo y levanta el auto.\n"
                        "5. Retira las tuercas, cambia el caucho y aprieta levemente.\n"
                        "6. Baja el auto y aprieta las tuercas firmemente en forma de estrella.",
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.car_crash, color: Colors.redAccent),
              title: Text('Qué hacer en caso de choque', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "1. Mantén la calma y verifica si hay heridos. Llama al 911 de ser necesario.\n"
                        "2. No muevas los vehículos a menos que obstruyan peligrosamente el tráfico.\n"
                        "3. Toma fotos de los daños, placas y posición de los vehículos.\n"
                        "4. Intercambia datos con el otro conductor (Cédula, Licencia, Póliza de seguro).\n"
                        "5. Llama a tu aseguradora o fiscal de tránsito de inmediato.",
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: ExpansionTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Qué hacer al accidentarse (Falla mecánica)', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "1. Trata de llevar el vehículo al hombrillo o zona segura.\n"
                        "2. Enciende las luces intermitentes (luces de emergencia).\n"
                        "3. Si el motor se sobrecalienta, apágalo inmediatamente y no abras la tapa del radiador.\n"
                        "4. Coloca tus conos o triángulos reflectivos a 30 metros detrás del vehículo.\n"
                        "5. Llama a tu servicio de grúa o mecánico de confianza.",
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
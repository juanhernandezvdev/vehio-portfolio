import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Políticas y Privacidad'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Icon(Icons.shield, size: 60, color: Color(0xFFE50914)),
          const SizedBox(height: 20),
          const Text(
            'Políticas de Privacidad de Vehio',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildSection('1. Recopilación de Datos Personales', 'Vehio recopila información de identificación básica (nombre y correo electrónico) a través de los proveedores de autenticación (Google, Facebook, GitHub). Esta recolección cumple con lo establecido en la Ley N° 29733 (Perú) y normativas afines aplicables en Venezuela.'),
          _buildSection('2. Datos del Vehículo y Uso', 'Recopilamos información sobre la marca, modelo, año, kilometraje, registros de mantenimiento y gastos vehiculares. Estos datos se usan para brindar las funcionalidades principales de la aplicación (alertas, recordatorios y estadísticas).'),
          _buildSection('3. Almacenamiento, Flujo Transfronterizo y Seguridad', 'Toda la información se procesa y almacena utilizando la infraestructura de Google Firebase (EE. UU.). Los datos en tránsito viajan cifrados. Opcionalmente, datos sensibles como archivos PDF e imágenes se almacenan localmente en tu dispositivo mediante Hive cifrado.'),
          _buildSection('4. Analíticas, Publicidad y Cookies', 'La aplicación utiliza Google AdMob para la versión gratuita y Firebase Analytics. Estas herramientas utilizan identificadores de dispositivo (como AAID en Android o IDFA en iOS) para recopilar métricas de uso y mostrar anuncios personalizados según tus intereses. Al usar la app, otorgas tu consentimiento para el uso de estos rastreadores.'),
          _buildSection('5. Restricción de Edad', 'Vehio está diseñada para ser utilizada por personas mayores de 13 años. Para realizar la adquisición del servicio "Vehio Premium" (suscripciones), el usuario declara tener 18 años de edad o contar con la autorización explícita de su tutor legal titular del método de pago.'),
          _buildSection('6. Derechos ARCO y Eliminación de Cuenta', 'Tienes el derecho absoluto a Acceder, Rectificar, Cancelar u Oponerte (ARCO) al tratamiento de tus datos. Puedes ejercer tu derecho de Cancelación eliminando permanentemente tu cuenta y toda tu base de datos desde la sección de Configuración en cualquier momento, de manera irrevocable.'),
          const SizedBox(height: 30),
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE50914), foregroundColor: Colors.white),
              child: const Text('Entendido y Volver', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE50914))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }
}
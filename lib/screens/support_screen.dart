import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'privacy_policy_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // --- FUNCIÓN PARA ABRIR EL CORREO DE SOPORTE ---
  Future<void> _launchSupportEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'soporte@garajepro.com',
      queryParameters: {'subject': 'Soporte GarajePro - Ayuda requerida'},
    );

    try {
      final launched = await launchUrl(emailLaunchUri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la aplicación de correo.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al intentar abrir el correo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y Soporte')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Soporte Técnico', style: TextStyle(color: const Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Preguntas Frecuentes (FAQs)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navegamos a una pantalla dedicada y limpia de FAQs
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Chat / Contacto de Soporte Técnico'),
            subtitle: const Text('Envíanos un correo directo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchSupportEmail(context),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Acerca de Vehio', style: TextStyle(color: const Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Términos de Servicio y Descargo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Términos de Servicio'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Al utilizar Vehio, aceptas el uso responsable de la aplicación para la gestión de tus vehículos y registros de mantenimiento. Las alertas son meramente informativas y no sustituyen el criterio de un mecánico profesional.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Políticas de Privacidad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('Licencias de Software'),
            subtitle: const Text('Créditos de paquetes de código abierto'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Vehio',
                applicationVersion: '1.0.0',
                applicationIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.directions_car, size: 40, color: const Color(0xFFE50914)),
                ),
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versión de la aplicación'),
            trailing: Text('v1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// --- PANTALLA DEDICADA DE PREGUNTAS FRECUENTES (FAQS) ---
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preguntas Frecuentes')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ExpansionTile(
            leading: Icon(Icons.directions_car, color: const Color(0xFFE50914)),
            title: Text('¿Cómo agrego un vehículo?', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Presiona el botón "+" ubicado en la parte inferior de la pantalla principal. Selecciona si se trata de un Auto o una Moto, completa los datos de marca, modelo, año y kilometraje actual, y guárdalo.',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            leading: Icon(Icons.notifications_active, color: const Color(0xFFE50914)),
            title: Text('¿Cómo funcionan las alertas de mantenimiento?', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'La aplicación compara de forma inteligente el kilometraje actual registrado de tu vehículo con el próximo servicio programado. Al faltar 500 unidades o menos, la app te notificará de manera preventiva.',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            leading: Icon(Icons.cloud_sync, color: const Color(0xFFE50914)),
            title: Text('¿Se pierden mis datos si cambio de teléfono?', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No. Tus datos se sincronizan automáticamente con la nube a través de tu cuenta vinculada. Si inicias sesión en un nuevo dispositivo con el mismo correo, tu garaje y registros aparecerán intactos.',
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ExpansionTile(
            leading: Icon(Icons.delete_forever, color: Colors.redAccent),
            title: Text('¿Cómo puedo eliminar mis datos permanentemente?', style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Puedes ir a Configuración y Seguridad > Zona de Peligro > Eliminar cuenta y datos. Esto borrará por completo tu información tanto de la nube como del almacenamiento local.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
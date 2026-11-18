import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Términos de Servicio (ToS)')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text(
            'Términos y Condiciones de Uso de Vehio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Última actualización: Octubre 2026',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          SizedBox(height: 20),
          Text(
            '1. Aceptación de los Términos\n'
                'Al crear una cuenta y acceder a la aplicación "Vehio", el usuario acepta en su totalidad los presentes Términos de Servicio y nuestras Políticas de Privacidad. Si no estás de acuerdo, no debes utilizar la aplicación.\n\n'

                '2. Descargo de Responsabilidad (Disclaimer)\n'
                'Vehio es una herramienta digital de gestión informativa y asistencia. Las alertas, cálculos de kilometraje y recordatorios de servicio generados por la aplicación se basan exclusivamente en los datos ingresados manualmente por el usuario. La aplicación NO se sincroniza directamente con la computadora de abordo del vehículo (OBD-II) y NO sustituye, en ningún caso, el diagnóstico técnico, la inspección física, ni el criterio de un taller o mecánico profesional calificado.\n\n'
                'Vehio, sus desarrolladores, propietarios o afiliados no asumen ninguna responsabilidad civil, penal o comercial por: fallas mecánicas, accidentes de tránsito, daños materiales, lesiones personales o pérdidas financieras derivadas del estado de un vehículo, omisiones de mantenimiento o errores en los datos registrados por la aplicación.\n\n'

                '3. Responsabilidad sobre Documentos y Fotos (UGC)\n'
                'La función de "Documentos" permite almacenar fotografías o escaneos digitales. Vehio no revisa, censura ni se hace responsable por el contenido subido por el usuario. El usuario asume toda la responsabilidad legal por la veracidad, origen, legalidad y sensibilidad de los documentos (tales como identificaciones, facturas o títulos de propiedad) almacenados en su dispositivo o respaldados en la nube.\n\n'

                '4. Política de Pagos y Suscripciones (Vehio Premium)\n'
                'Vehio ofrece planes de suscripción "Premium" facturados a través de las plataformas de Google Play Store y Apple App Store. La administración, los cobros y la renovación automática de las suscripciones están sujetos estrictamente a las condiciones de servicio de dichas tiendas.\n\n'

                '5. Política de Reembolsos\n'
                'Al tratarse de la adquisición y entrega inmediata de un bien intangible y digital (funciones y beneficios Premium desbloqueados por software), Vehio no emite reembolsos directos ni aplica devoluciones o "Delivery" de bienes físicos. Toda solicitud de cancelación de suscripción o reembolso por cobros no reconocidos debe ser procesada directamente por el usuario a través del soporte técnico de Google Play o Apple, según corresponda.\n\n'
                
                '6. Marcas Registradas\n'
                'Todos los logotipos, emblemas y nombres de fabricantes vehiculares (ej. Ford, Toyota, BMW) mostrados en la aplicación son marcas comerciales de sus respectivos propietarios. Su uso en Vehio es meramente ilustrativo bajo el principio de "Uso Legítimo" para ayudar al usuario a identificar visualmente el modelo de su propio vehículo. Vehio no está afiliada, autorizada ni patrocinada por ninguna de las marcas automotrices.',
            style: TextStyle(height: 1.5, fontSize: 15),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = false;
  
  final _phoneController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('notifications').get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            _pushEnabled = doc.data()!['push'] ?? true;
            _emailEnabled = doc.data()!['email'] ?? false;
            _smsEnabled = doc.data()!['sms'] ?? false;
            _phoneController.text = doc.data()!['phone'] ?? '';
          });
        }
      } catch (e) {
        debugPrint("Error loading preferences: $e");
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('notifications').set({
          'push': _pushEnabled,
          'email': _emailEnabled,
          'sms': _smsEnabled,
          'phone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferencias guardadas exitosamente.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias de Alertas'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Elige cómo quieres que Vehio te avise cuando tus vehículos o repuestos requieran atención.',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                activeColor: const Color(0xFFE50914),
                title: const Text('Notificaciones Locales (Push)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Recibe alertas directamente en tu teléfono al abrir la app.'),
                value: _pushEnabled,
                onChanged: (val) => setState(() => _pushEnabled = val),
              ),
              const Divider(),
              
              SwitchListTile(
                activeColor: const Color(0xFFE50914),
                title: const Text('Correos Electrónicos', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Recibe reportes y alertas en tu bandeja de entrada.'),
                value: _emailEnabled,
                onChanged: (val) => setState(() => _emailEnabled = val),
              ),
              const Divider(),

              SwitchListTile(
                activeColor: const Color(0xFFE50914),
                title: const Text('Mensajes de Texto (SMS)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Recibe alertas urgentes por SMS.'),
                value: _smsEnabled,
                onChanged: (val) => setState(() => _smsEnabled = val),
              ),
              
              if (_smsEnabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Teléfono',
                      hintText: '+1234567890',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nota: El envío de correos y SMS requiere configuración adicional en el servidor (Firebase Extensions). Además, la operadora podría aplicar cargos extra por recibir mensajes SMS.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _savePreferences,
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Guardar Preferencias', style: TextStyle(fontSize: 16)),
                ),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE50914), foregroundColor: Colors.white),
              )
            ],
          ),
    );
  }
}
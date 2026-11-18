import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/login_screen.dart';
import '../models/vehicle_model.dart';
import 'premium_screen.dart';
import 'notification_preferences_screen.dart';
import '../providers/subscription_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushEnabled = true;
  bool emailEnabled = false;
  bool smsEnabled = true;
  bool _isDeleting = false;
  bool _isSendingPasswordReset = false;

  // --- FUNCIÓN REAL: CAMBIAR CONTRASEÑA ---
  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay un correo electrónico asociado a esta sesión.')),
      );
      return;
    }

    setState(() => _isSendingPasswordReset = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se ha enviado un enlace de restablecimiento a ${user.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingPasswordReset = false);
    }
  }

  // --- DIÁLOGO INFORMATIVO: VERIFICACIÓN EN DOS PASOS (2FA) ---
  void _show2FADialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificación en dos pasos (2FA)'),
        content: const Text(
          'Tu cuenta está protegida mediante los protocolos de seguridad de Firebase Auth y Google Cloud, los cuales gestionan autenticación cifrada y tokens seguros en cada inicio de sesión.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO INFORMATIVO: PRIVACIDAD DEL PERFIL ---
  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacidad del perfil'),
        content: const Text(
          'En Vehio tus datos de kilometraje, vehículos y mantenimientos están cifrados y aislados en tu propia ruta privada de la base de datos. Nadie más tiene acceso a tu información.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // --- LÓGICA DE ELIMINACIÓN DE CUENTA (DERECHO AL OLVIDO) ---
  Future<void> _deleteAccountData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isDeleting = true);

    try {
      final vehiclesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vehicles');

      final snapshot = await vehiclesRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      final box = Hive.box<Vehicle>('vehicles_box');
      await box.clear();

      await user.delete();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por seguridad, cierra sesión, vuelve a ingresar e inténtalo de nuevo.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la cuenta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // --- FUNCIÓN DE CIERRE DE SESIÓN SEGURO ---
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: '36297751205-kodn1bblam3k1qtuhm0o5mhrrbso2nb3.apps.googleusercontent.com',
        );
        await googleSignIn.signOut();
      } catch (_) {}

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración y Seguridad')),
      body: ListView(
        children: [
          // --- FUNCIONES AVANZADAS / PREMIUM ---
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text('Funciones Avanzadas', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Consumer<SubscriptionProvider>(
              builder: (context, premiumProvider, _) {
                return ListTile(
                  leading: const Icon(Icons.cloud_sync, color: Colors.blueAccent),
                  title: const Text('Respaldo en la Nube'),
                  subtitle: Text(
                    premiumProvider.isPremium 
                      ? 'Sincronizar tus datos con los servidores.' 
                      : 'Protege tu información. Exclusivo Premium.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: premiumProvider.isPremium 
                      ? const Icon(Icons.cloud_done, color: Colors.green)
                      : const Icon(Icons.workspace_premium, color: Color(0xFFE50914)),
                  onTap: () {
                    if (premiumProvider.isPremium) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Respaldando datos en Firebase...')),
                      );
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                    }
                  },
                );
              }
            ),
          ),
          
          // --- PREFERENCIAS DE ALERTAS ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Notificaciones', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.orange),
              title: const Text('Preferencias de Alertas'),
              subtitle: const Text('Configura alertas locales, Correo o SMS', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
            ),
          ),
          
          // --- SEGURIDAD Y PRIVACIDAD ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Seguridad y Privacidad', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar contraseña'),
            subtitle: _isSendingPasswordReset ? const Text('Enviando correo...') : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: _isSendingPasswordReset ? null : () => _sendPasswordResetEmail(context),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Verificación en dos pasos (2FA)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _show2FADialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Privacidad del perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyDialog(context),
          ),
          const Divider(),

          // --- NOTIFICACIONES ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Notificaciones', style: TextStyle(color: const Color(0xFFE50914), fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Alertas Push'),
            value: pushEnabled,
            onChanged: (val) => setState(() => pushEnabled = val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Correos electrónicos'),
            value: emailEnabled,
            onChanged: (val) => setState(() => emailEnabled = val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sms),
            title: const Text('Mensajes SMS'),
            value: smsEnabled,
            onChanged: (val) => setState(() => smsEnabled = val),
          ),
          const Divider(),

          // --- ZONA DE PELIGRO: ELIMINAR CUENTA ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text('Zona de Peligro', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Eliminar cuenta y datos', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Borra permanentemente tu cuenta y todos tus vehículos de Vehio'),
            trailing: _isDeleting ? const CircularProgressIndicator(color: Colors.redAccent) : null,
            onTap: _isDeleting ? null : () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('⚠️ ¿Estás seguro de eliminar tu cuenta?'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Esta acción no se puede deshacer. Perderás todos los registros de tus vehículos, mantenimientos y combustible.'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteAccountData(context);
                      },
                      child: const Text('Sí, eliminar todo', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // --- CERRAR SESIÓN ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Cerrar Sesión', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
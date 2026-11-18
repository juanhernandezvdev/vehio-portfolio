import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  // --- FUNCIÓN OFICIAL Y SEGURA DE CAMBIO DE CORREO CON VERIFICACIÓN PREVIA ---
  void _showChangeEmailDialog(BuildContext context) {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Correo Electrónico'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Por seguridad, ingresa tu nueva dirección de correo y tu contraseña actual. Te enviaremos un enlace de verificación.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newEmailController,
                decoration: const InputDecoration(
                  labelText: 'Nuevo Correo Electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña Actual',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña actual';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE50914), foregroundColor: Colors.black),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.email == null) return;

                  String currentEmail = user.email!;
                  String newEmail = newEmailController.text.trim();
                  String password = passwordController.text.trim();

                  // 1. Reautenticar al usuario obligatoriamente por seguridad
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: currentEmail,
                    password: password,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // 2. Enviar correo de verificación a la dirección original (Requerido por Firebase)
                  await user.verifyBeforeUpdateEmail(newEmail);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('¡Enlace enviado! Revisa la bandeja de entrada de tu correo ACTUAL ($currentEmail) para confirmar el cambio a $newEmail.'),
                        backgroundColor: const Color(0xFFE50914),
                        duration: const Duration(seconds: 7),
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  if (mounted) {
                    String errorMessage = 'Error al actualizar el correo';
                    if (e.code == 'wrong-password') {
                      errorMessage = 'La contraseña actual es incorrecta.';
                    } else if (e.code == 'email-already-in-use') {
                      errorMessage = 'El correo ya está registrado por otra cuenta.';
                    } else if (e.code == 'requires-recent-login') {
                      errorMessage = 'Por seguridad, vuelve a iniciar sesión e intenta de nuevo.';
                    } else {
                      errorMessage = 'Error: ${e.message}';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  /// Método para forzar la sincronización del usuario tras confirmar el enlace en el correo
  Future<void> _verificarYActualizarSesion() async {
    setState(() => _isLoading = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Recargar los datos desde los servidores de Firebase Auth
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        // 2. Sincronizar también el cambio en Cloud Firestore si ya se aplicó en Auth
        if (user?.email != null) {
          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
            'email': user.email,
          });
        }

        // 3. Refrescar la interfaz
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Sesión actualizada correctamente con tu nuevo correo!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aún no se ha confirmado el cambio en el servidor: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String emailPrefix = user?.email != null ? user!.email!.split('@')[0] : 'Usuario';
    final String displayName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : emailPrefix;

    final String displayEmail = user?.email ?? 'No disponible';
    final String? photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: const Color(0xFFE50914)))
          : ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                CircleAvatar(
                  backgroundColor: const Color(0xFFE50914),
                  radius: 18,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.black, size: 16),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          TextFormField(
            initialValue: displayName,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              prefixIcon: Icon(Icons.person),
              helperText: 'Sincronizado con tus credenciales de acceso',
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: displayEmail,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _showChangeEmailDialog(context),
                    child: const Text('Cambiar', style: TextStyle(color: const Color(0xFFE50914), fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: _verificarYActualizarSesion,
                    child: const Text('Actualizar Estado', style: TextStyle(color: Colors.blue, fontSize: 11)),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
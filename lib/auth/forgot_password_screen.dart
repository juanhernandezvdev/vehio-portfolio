import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Maneja el flujo de recuperación de contraseña mediante Firebase Auth.
/// Envía un enlace seguro al correo electrónico del usuario.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Envía el correo de restablecimiento de contraseña si la entrada es válida.
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('Por favor, ingresa una dirección de correo válida.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        _showSnackBar('Correo de restablecimiento enviado. Revisa tu bandeja de entrada.', Colors.green);
        Navigator.pop(context); // Regresa a la pantalla de inicio de sesión
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Ocurrió un error al enviar el correo.';
        if (e.code == 'user-not-found') {
          message = 'No existe una cuenta registrada con este correo.';
        }
        _showSnackBar(message, Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Método auxiliar para mostrar snackbars.
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 80, color: const Color(0xFFE50914)),
            const SizedBox(height: 24),
            const Text(
              'Recuperar Contraseña',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE50914),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('ENVIAR ENLACE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
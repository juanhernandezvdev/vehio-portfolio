import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Variables de estado para alternar la visibilidad de las contraseñas
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Crear el usuario en Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // 2. Actualizar el displayName en Firebase Auth
          await user.updateDisplayName(_nameController.text.trim());

          // 3. Guardar la información en Cloud Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'nombreCompleto': _nameController.text.trim(),
            'correo': _emailController.text.trim(),
            'fechaRegistro': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta creada con éxito'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        String mensajeError = 'Ocurrió un error al registrarse';
        if (e.code == 'email-already-in-use') {
          mensajeError = 'Este correo ya está registrado.';
        } else if (e.code == 'weak-password') {
          mensajeError = 'La contraseña es muy débil.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crear Cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87), // Título oscurecido
                ),
                const SizedBox(height: 30),

                // Nombre Completo
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500), // Texto oscuro e intenso
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    labelStyle: const TextStyle(color: Colors.black87), // Etiqueta oscura
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.black87), // Ícono oscuro
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => (value != null && value.trim().isNotEmpty) ? null : 'Ingresa tu nombre completo',
                ),
                const SizedBox(height: 20),

                // Correo electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500), // Texto oscuro e intenso
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: const TextStyle(color: Colors.black87), // Etiqueta oscura
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.black87), // Ícono oscuro
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => (value != null && value.contains('@')) ? null : 'Correo inválido',
                ),
                const SizedBox(height: 20),

                // Contraseña con botón para mostrar/ocultar
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500), // Texto oscuro e intenso
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.black87), // Etiqueta oscura
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.black87), // Ícono oscuro
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black87, // Ícono oscuro
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => (value != null && value.length >= 6) ? null : 'Mínimo 6 caracteres',
                ),
                const SizedBox(height: 20),

                // Confirmar Contraseña con botón para mostrar/ocultar
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500), // Texto oscuro e intenso
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    labelStyle: const TextStyle(color: Colors.black87), // Etiqueta oscura
                    prefixIcon: const Icon(Icons.lock_reset, color: Colors.black87), // Ícono oscuro
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black87, // Ícono oscuro
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
                    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Botón de Registro
                ElevatedButton(
                  onPressed: _isLoading ? null : _registrarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('REGISTRARSE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
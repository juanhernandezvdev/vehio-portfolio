import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'forgot_password_screen.dart';
import '/screens/home_screen.dart';
import '../screens/terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- STATE VARIABLES ---
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isSocialLoading = false;
  bool _acceptedTerms = false;

  // Variables de visibilidad para las contraseñas
  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirmPassword = true;

  // --- CONTROLLERS & KEYS ---
  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpFormKey = GlobalKey<FormState>();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _isSignUp = !_isSignUp;
      _acceptedTerms = false;
    });
  }

  Future<void> _saveUserData(User user, {String? extraName}) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    // Lanzamos la escritura en segundo plano sin detener la transición de la pantalla
    userRef.set({
      'uid': user.uid,
      'email': user.email ?? '',
      'name': extraName ?? user.displayName ?? 'Usuario',
      'photoUrl': user.photoURL ?? '',
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((e) => debugPrint('Error sincronizando usuario: \$e'));
  }

  Future<void> _signIn() async {
    if (!_acceptedTerms) {
      _showError('Debes aceptar los Términos y la Política de Privacidad.');
      return;
    }

    if (_signInFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential creds = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _signInEmailController.text.trim(),
          password: _signInPasswordController.text.trim(),
        );

        if (creds.user != null) {
          await _saveUserData(creds.user!);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        _showError(e.code == 'invalid-credential' ? 'Correo o contraseña inválidos.' : 'Error al iniciar sesión: ${e.message}');
      } catch (e) {
        _showError('Ocurrió un error inesperado: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_acceptedTerms) {
      _showError('Debes aceptar los Términos y la Política de Privacidad para registrarte.');
      return;
    }

    if (_signUpFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _signUpEmailController.text.trim(),
          password: _signUpPasswordController.text.trim(),
        );
        if (creds.user != null) {
          String fullName = _signUpNameController.text.trim();
          await creds.user!.updateDisplayName(fullName);
          await _saveUserData(creds.user!, extraName: fullName);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String msg = 'Error al registrarse';
        if (e.code == 'email-already-in-use') msg = 'Este correo ya está registrado.';
        if (e.code == 'weak-password') msg = 'La contraseña es muy débil.';
        _showError(msg);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_acceptedTerms) {
      _showError('Debes aceptar los Términos y la Política de Privacidad.');
      return;
    }

    setState(() => _isSocialLoading = true);
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        GoogleAuthProvider provider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: '36297751205-kodn1bblam3k1qtuhm0o5mhrrbso2nb3.apps.googleusercontent.com',
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          setState(() => _isSocialLoading = false);
          return;
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      if (userCredential.user != null) {
        await _saveUserData(userCredential.user!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      _showError('No se pudo conectar con Google.');
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    if (!_acceptedTerms) {
      _showError('Debes aceptar los Términos y la Política de Privacidad.');
      return;
    }

    setState(() => _isSocialLoading = true);
    try {
      FacebookAuthProvider provider = FacebookAuthProvider();
      UserCredential userCredential = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);

      if (userCredential.user != null) {
        await _saveUserData(userCredential.user!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      _showError('No se pudo conectar con Facebook.');
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  Future<void> _signInWithGitHub() async {
    if (!_acceptedTerms) {
      _showError('Debes aceptar los Términos y la Política de Privacidad.');
      return;
    }

    setState(() => _isSocialLoading = true);
    try {
      GithubAuthProvider provider = GithubAuthProvider();
      UserCredential userCredential = kIsWeb
          ? await FirebaseAuth.instance.signInWithPopup(provider)
          : await FirebaseAuth.instance.signInWithProvider(provider);

      if (userCredential.user != null) {
        await _saveUserData(userCredential.user!);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      _showError('No se pudo conectar con GitHub.');
    } finally {
      if (mounted) setState(() => _isSocialLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildTermsCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: _acceptedTerms,
            activeColor: const Color(0xFFE50914),
            checkColor: Colors.black,
            // --- REMARCAMOS LA CASILLA CON UN BORDE NEGRO ---
            side: const BorderSide(color: Colors.black87, width: 2.0),
            onChanged: (val) {
              setState(() => _acceptedTerms = val ?? false);
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Al tocar el texto en el login, ahora abre los Términos de Servicio.
                // (Se asume que en el menú lateral o ajustes se mostrará la otra pantalla de privacidad).
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                );
              },
              child: const Text(
                'Acepto los Términos, el Descargo y la Política de Privacidad',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black, // Color negro intenso
                  fontWeight: FontWeight.w600, // Grosor extra
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade200, Colors.grey.shade300, const Color(0x33E50914)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Personalizado del Login
                Container(
                  width: 100, // Ajustado para un logo
                  height: 100, // Ajustado para un logo
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Fondo transparente
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/logos/login_logo.png', // Nuevo logo del login
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.garage, size: 40, color: Color(0xFFE50914)); // Fallback si no está
                      },
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 35,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isDesktop = constraints.maxWidth > 700;

                        if (!isDesktop) {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _isSignUp
                                ? SingleChildScrollView(
                              key: const ValueKey('mobile_register_view'),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSignUpForm(),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _toggleView,
                                    child: const Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            )
                                : SingleChildScrollView(
                              key: const ValueKey('mobile_login_view'),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSignInForm(),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _toggleView,
                                    child: const Text('¿No tienes cuenta? Regístrate', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            ),
                          );
                        }

                        final double panelWidth = constraints.maxWidth / 2;

                        return Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: panelWidth,
                              child: IgnorePointer(
                                ignoring: _isSignUp,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: _isSignUp ? 0.0 : 1.0,
                                  child: Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                                      child: _buildSignInForm(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: panelWidth,
                              child: IgnorePointer(
                                ignoring: !_isSignUp,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 400),
                                  opacity: _isSignUp ? 1.0 : 0.0,
                                  child: Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 24.0),
                                      child: _buildSignUpForm(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                              left: _isSignUp ? 0 : panelWidth,
                              top: 0,
                              bottom: 0,
                              width: panelWidth,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE50914), // Únicamente color rojo, sin degradado
                                ),
                                padding: const EdgeInsets.all(36.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(height: 20), // Eliminado el contenedor "Vehio" que el usuario encerró en el círculo
                                    Expanded(
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: _isSignUp
                                              ? _buildToggleLeftContent()
                                              : _buildToggleRightContent(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('o continuar con', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIconButton(
              icon: Icons.g_mobiledata_rounded,
              color: Colors.black,
              onPressed: _isSocialLoading ? null : _signInWithGoogle,
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialIconButton({required IconData icon, required Color color, required VoidCallback? onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildSignInForm() {
    return Form(
      key: _signInFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Iniciar Sesión', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 14),
          TextFormField(
            controller: _signInEmailController,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: const TextStyle(color: Colors.black87),
              prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Colors.black87),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _signInPasswordController,
            obscureText: _obscureSignInPassword,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              labelStyle: const TextStyle(color: Colors.black87),
              prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.black87),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignInPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black87,
                ),
                onPressed: () {
                  setState(() {
                    _obscureSignInPassword = !_obscureSignInPassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: const Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 2),
          _buildTermsCheckbox(),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: (_isLoading) ? null : () {
              if (!_acceptedTerms) {
                _showError('Debes aceptar los Términos y la Política de Privacidad.');
              } else {
                _signIn();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white, // Letras blancas para contraste en fondo rojo
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          _buildSocialButtons(),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Crear Cuenta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _signUpNameController,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Nombre Completo',
              labelStyle: const TextStyle(color: Colors.black87),
              prefixIcon: const Icon(Icons.person_outline, size: 18, color: Colors.black87),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu nombre' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpEmailController,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: const TextStyle(color: Colors.black87),
              prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Colors.black87),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpPasswordController,
            obscureText: _obscureSignUpPassword,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              labelStyle: const TextStyle(color: Colors.black87),
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.black87),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black87,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureSignUpPassword = !_obscureSignUpPassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _signUpConfirmPasswordController,
            obscureText: _obscureSignUpConfirmPassword,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Confirmar Contraseña',
              labelStyle: const TextStyle(color: Colors.black87),
              prefixIcon: const Icon(Icons.lock_reset, size: 18, color: Colors.black87),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSignUpConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black87,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureSignUpConfirmPassword = !_obscureSignUpConfirmPassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirma tu contraseña';
              if (v != _signUpPasswordController.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 4),
          _buildTermsCheckbox(),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: (_isLoading) ? null : () {
              if (!_acceptedTerms) {
                _showError('Debes aceptar los Términos y la Política de Privacidad.');
              } else {
                _signUp();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white, // Letras blancas para contraste en fondo rojo
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          _buildSocialButtons(),
        ],
      ),
    );
  }

  Widget _buildToggleRightContent() {
    return Column(
      // Se quitó la GlobalKey redundante
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¡Hola, amigo!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('Ingresa tus datos personales y comienza tu viaje en Vehio.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15)),
        const SizedBox(height: 30),
        OutlinedButton(
          onPressed: _toggleView,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white, width: 2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildToggleLeftContent() {
    return Column(
      // Se quitó la GlobalKey redundante
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¡Bienvenido de nuevo!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        const Text('Para mantenerte conectado con tu garaje, inicia sesión con tu información personal.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 15)),
        const SizedBox(height: 30),
        OutlinedButton(
          onPressed: _toggleView,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white, width: 2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }
}
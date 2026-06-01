import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'persona_state.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() {
    // Mock Authentication Logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isLogin ? 'Welcome Back!' : 'Account Created!')),
    );
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pinkAccent, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.child_care, size: 100, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'Ruby Boby',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text('Your Child\'s AI Best Friend', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 50),

                // Auth Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      children: [
                        Text(
                          _isLogin ? 'Login to Parent Account' : 'Create Parent Account',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 25),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(_isLogin ? 'Login' : 'Sign Up', style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin ? 'New to Ruby Boby? Sign Up' : 'Already have an account? Login'),
                        ),
                        
                        // Google Login Integration
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.grey, thickness: 0.8)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            const Expanded(child: Divider(color: Colors.grey, thickness: 0.8)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          onPressed: _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            backgroundColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                margin: const EdgeInsets.only(right: 12),
                                child: CustomPaint(
                                  painter: _GoogleLogoPainter(),
                                ),
                              ),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  void _showGoogleSignInDialog() {
    String? customEmail;
    bool isSigningIn = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        child: CustomPaint(painter: _GoogleLogoPainter()),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Google',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5F6368),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose an account',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'to continue to Ruby Boby',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                  ),
                  const SizedBox(height: 24),

                  if (isSigningIn) ...[
                    const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.pinkAccent),
                      ),
                    ),
                  ] else ...[
                    _googleAccountTile(
                      name: 'Ahmed Rakib',
                      email: 'ahmed.rakib@gmail.com',
                      initial: 'A',
                      color: Colors.blueAccent,
                      onTap: () {
                        setModalState(() => isSigningIn = true);
                        _authenticateGoogleAccount('ahmed.rakib@gmail.com', setModalState);
                      },
                    ),
                    const Divider(height: 1),
                    _googleAccountTile(
                      name: 'Rakib SUST',
                      email: 'rakibsustbd@gmail.com',
                      initial: 'R',
                      color: Colors.indigoAccent,
                      onTap: () {
                        setModalState(() => isSigningIn = true);
                        _authenticateGoogleAccount('rakibsustbd@gmail.com', setModalState);
                      },
                    ),
                    const Divider(height: 1),
                    _googleAccountTile(
                      name: 'Rakib Test',
                      email: 'rakiiiiiiib@gmail.com',
                      initial: 'R',
                      color: Colors.teal,
                      onTap: () {
                        setModalState(() => isSigningIn = true);
                        _authenticateGoogleAccount('rakiiiiiiib@gmail.com', setModalState);
                      },
                    ),
                    const Divider(height: 1),
                    _googleAccountTile(
                      name: 'Guest Parent',
                      email: 'guest.parent@gmail.com',
                      initial: 'G',
                      color: Colors.deepOrangeAccent,
                      onTap: () {
                        setModalState(() => isSigningIn = true);
                        _authenticateGoogleAccount('guest.parent@gmail.com', setModalState);
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: TextField(
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Enter another gmail address',
                          prefixIcon: const Icon(Icons.add_rounded, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.blue),
                            onPressed: () {
                              if (customEmail != null && customEmail!.contains('@')) {
                                setModalState(() => isSigningIn = true);
                                _authenticateGoogleAccount(customEmail!, setModalState);
                              } else {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid Gmail address!')),
                                );
                              }
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[500]!.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) {
                          customEmail = val.trim();
                        },
                        onSubmitted: (val) {
                          if (val.contains('@')) {
                            setModalState(() => isSigningIn = true);
                            _authenticateGoogleAccount(val.trim(), setModalState);
                          }
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'To continue, Google will share your name, email address, language preference, and profile picture with Ruby Boby.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _googleAccountTile({
    required String name,
    required String email,
    required String initial,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3C4043))),
      subtitle: Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
      onTap: onTap,
    );
  }

  void _authenticateGoogleAccount(String email, StateSetter setModalState) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    
    if (!mounted) return;
    
    await AuthService.saveSession(email);
    await PersonaState.loadPersonas();
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed in with Google as $email 🎉', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _handleGoogleSignIn() {
    if (AuthService.googleClientId != null && AuthService.googleClientId!.isNotEmpty) {
      _runRealGoogleSignIn();
    } else {
      _showSetupOrMockDialog();
    }
  }

  void _runRealGoogleSignIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.pinkAccent),
                SizedBox(height: 16),
                Text('Connecting to Google...', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final account = await AuthService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (account != null) {
        await PersonaState.loadPersonas();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully authenticated as ${account.email} 🎉', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Google Sign-In Error'),
            content: Text(
              'A real OAuth sign-in attempt failed. This is usually because the app is running locally and Google Cloud Client ID hasn\'t been registered, or the current localhost port is not whitelisted.\n\nError details:\n$e'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showGoogleSignInDialog();
                },
                child: const Text('Use Simulation instead'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSetupOrMockDialog() {
    final clientController = TextEditingController(text: AuthService.googleClientId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 10),
            const Text('Google Auth Setup', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To perform a real Google / Gmail login, you need to register a Web Client ID in the Google Cloud Console.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: clientController,
              decoration: InputDecoration(
                labelText: 'Google Web Client ID',
                hintText: '123456...apps.googleusercontent.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Note: Whitelist the origin URL: http://localhost:63989 (your current port) in the Cloud Console settings.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showGoogleSignInDialog(); // Open simulator
            },
            child: const Text('Use Simulator'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
            onPressed: () {
              final id = clientController.text.trim();
              if (id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Client ID or use the simulator.')),
                );
                return;
              }
              AuthService.googleClientId = id;
              Navigator.pop(ctx);
              _runRealGoogleSignIn();
            },
            child: const Text('Apply & Sign In'),
          ),
        ],
      ),
    );
  }
}

// ─── Google Logo Painter ─────────────────────────────────────────────────────

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.28;
      
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -3.14 * 0.75, 3.14 * 0.5, false, paint);
    
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -3.14 * 0.25, 3.14 * 0.5, false, paint);
    
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.14 * 0.25, 3.14 * 0.5, false, paint);
    
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14 * 0.75, 3.14 * 0.5, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

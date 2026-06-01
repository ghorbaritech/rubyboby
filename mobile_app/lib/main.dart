import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'auth_view.dart';
import 'talking_screen.dart';
import 'persona_profile_screen.dart';
import 'persona_state.dart';
import 'parent_dashboard.dart';
import 'voice_service.dart';
import 'custom_avatar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://wvervucbmsgdmryftsgf.supabase.co',
    anonKey: 'sb_publishable_OO1WqQZ3P5xEsIgQ4eMbmQ_MJUgzCWI',
  );

  await VoiceService.init();
  await AuthService.loadSession();
  await PersonaState.loadPersonas();
  runApp(const RubyBobyApp());
}

class RubyBobyApp extends StatelessWidget {
  const RubyBobyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruby Boby',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B9D)),
        useMaterial3: true,
        fontFamily: 'Nunito',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthView(),
        '/home': (context) => const FriendSelectionScreen(),
      },
    );
  }
}

// ─── Friend Selection Screen ──────────────────────────────────────────────────

class _PersonaCard {
  final String id;
  final String name;
  final String subtitle;
  final String? assetImage;     // bundled asset path (Ruby, Boby, Teacher)
  final Uint8List? imageBytes;  // user-uploaded photo bytes (custom friends)
  final List<Color> gradient;
  final String age;
  final String gender;
  final String role;
  final double faceZoom;
  final double faceYOffset;

  const _PersonaCard({
    required this.id,
    required this.name,
    required this.subtitle,
    this.assetImage,
    this.imageBytes,
    required this.gradient,
    required this.age,
    required this.gender,
    required this.role,
    required this.faceZoom,
    required this.faceYOffset,
  });
}

class FriendSelectionScreen extends StatefulWidget {
  const FriendSelectionScreen({super.key});

  @override
  State<FriendSelectionScreen> createState() => _FriendSelectionScreenState();
}

class _FriendSelectionScreenState extends State<FriendSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final customs = PersonaState.savedPersonas;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F6), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello! 👋',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        const Text('Choose Your Friend',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF333333))),
                      ],
                    ),
                    Row(
                      children: [
                        _iconBtn(
                          icon: Icons.dashboard_customize_rounded,
                          color: const Color(0xFFFF6B9D),
                          onTap: () async {
                            final ok = await AuthService.verifyParent(context);
                            if (ok && context.mounted) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const ParentDashboard()));
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _iconBtn(
                          icon: Icons.logout_rounded,
                          color: Colors.grey,
                          onTap: () async {
                            await AuthService.logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, '/');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Friend grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: customs.length + 1,
                  itemBuilder: (context, i) {
                    if (i < customs.length) {
                      final c = customs[i];

                      // Default personas use bundled asset sprites;
                      // custom personas use their stored image bytes
                      String? assetImage;
                      if (c.id == 'Ruby') assetImage = 'assets/images/ruby.png';
                      else if (c.id == 'Boby') assetImage = 'assets/images/boby.png';
                      else if (c.id == 'Teacher') assetImage = 'assets/images/teacher.png';

                      return _FriendTile(
                        card: _PersonaCard(
                          id: c.id,
                          name: c.name,
                          subtitle: c.traits,
                          assetImage: assetImage,
                          imageBytes: c.imageBytes, // null for Ruby/Boby/Teacher
                          gradient: c.gender == 'Boy'
                              ? const [Color(0xFF42A5F5), Color(0xFF26C6DA)]
                              : const [Color(0xFFFF80AB), Color(0xFFFFAB40)],
                          age: c.age,
                          gender: c.gender,
                          role: c.role,
                          faceZoom: c.faceZoom,
                          faceYOffset: c.faceYOffset,
                        ),
                      );
                    }
                    // Add New
                    return _AddNewTile(onTap: () async {
                      final ok = await AuthService.verifyParent(context);
                      if (ok && context.mounted) {
                        final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PersonaProfileScreen()));
                        if (res == true) setState(() {});
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ─── Friend Tile ──────────────────────────────────────────────────────────────

class _FriendTile extends StatelessWidget {
  final _PersonaCard card;
  const _FriendTile({super.key, required this.card});

  Widget _buildTileAvatar({double size = 110}) {
    if (card.id == 'Ruby') {
      return Image.asset('assets/images/ruby.png', height: size, fit: BoxFit.contain);
    }
    if (card.id == 'Boby') {
      return Image.asset('assets/images/boby.png', height: size, fit: BoxFit.contain);
    }
    if (card.id == 'Teacher') {
      return Image.asset('assets/images/teacher.png', height: size, fit: BoxFit.contain);
    }
    return CustomAvatar(
      role: card.role,
      gender: card.gender,
      name: card.name,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TalkingScreen(
            personaId: card.id,
            customName: card.name,
            age: card.age,
            gender: card.gender,
            language: PersonaState.savedPersonas.firstWhere((p) => p.id == card.id, orElse: () => PersonaState.savedPersonas.first).language,
            customImageBytes: card.imageBytes,
            role: card.role,
            faceZoom: card.faceZoom,
            faceYOffset: card.faceYOffset,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: card.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: card.gradient.first.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Character image: asset sprite or custom role avatar
               Positioned(
                bottom: 46,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildTileAvatar(size: 100),
                ),
              ),
              // Info bar at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        card.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white.withOpacity(0.85)),
                      ),
                    ],
                  ),
                ),
              ),
              // Play icon badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                ),
              ),
              // Real photo badge thumbnail (if uploaded)
              if (card.imageBytes != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: Image.memory(
                        card.imageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add New Tile ─────────────────────────────────────────────────────────────

class _AddNewTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddNewTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFFFE0EC), shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Color(0xFFFF6B9D), size: 36),
            ),
            const SizedBox(height: 12),
            const Text('Add Friend',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFFF6B9D))),
            Text('Parent Only',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

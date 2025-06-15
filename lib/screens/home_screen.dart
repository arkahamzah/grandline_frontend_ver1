import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'series_list_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  User? currentUser;
  bool isLoading = true;
  int _selectedIndex = 0;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserProfile();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await AuthService.getProfile();
      setState(() {
        currentUser = user;
        isLoading = false;
      });
      _controller.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        if (e.toString().contains('Unauthorized')) {
          _handleUnauthorized();
        }
      }
    }
  }

  Future<void> _handleUnauthorized() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation,
              secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFF232327),
            title: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFD4AF37)),
                SizedBox(width: 12),
                Text(
                  'Sign Out',
                  style: TextStyle(color: Color(0xFFE8E8E8)),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation,
                secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation,
                child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  // Method untuk clear avatar cache
  Future<void> _clearAvatarCache() async {
    try {
      if (currentUser?.profileImageUrl != null) {
        // Clear cache untuk original URL tanpa query parameters
        String originalUrl = currentUser!.profileImageUrl!.split('?')[0];
        await CachedNetworkImage.evictFromCache(originalUrl);
        await CachedNetworkImage.evictFromCache(currentUser!.profileImageUrl!);
        print('🧹 Avatar cache cleared');
      }
    } catch (e) {
      print('Error clearing avatar cache: $e');
    }
  }

  Widget _buildProfileAvatar() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation,
                  secondaryAnimation) => const ProfileScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation,
                  child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
          if (result == true) {
            // IMPORTANT: Clear cache dan reload profile setelah update
            await _clearAvatarCache();
            await _loadUserProfile();
          }
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.8),
                const Color(0xFFFFD700).withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: currentUser?.profileImageUrl != null
                ? _buildAvatarImage(currentUser!.profileImageUrl!)
                : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4AF37).withOpacity(0.3),
                    const Color(0xFFFFD700).withOpacity(0.3),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // IMPROVED: Helper method untuk avatar image yang mendukung GIF dengan cache busting
  Widget _buildAvatarImage(String imageUrl) {
    // Enhanced GIF detection - check both URL and file extension
    bool isGif = imageUrl.toLowerCase().contains('.gif') ||
        imageUrl.toLowerCase().endsWith('.gif') ||
        imageUrl.toLowerCase().contains('gif');

    // Generate unique key untuk force rebuild
    final imageKey = ValueKey('avatar_${currentUser?.id}_${DateTime.now().millisecondsSinceEpoch}');

    if (isGif) {
      // Use Image.network for GIF animations dengan cache busting
      return Image.network(
        imageUrl,
        key: imageKey,
        fit: BoxFit.cover,
        headers: const {
          'Accept': 'image/gif,image/*,*/*',
          'Cache-Control': 'no-cache',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  const Color(0xFFFFD700).withOpacity(0.3),
                ],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 20,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  const Color(0xFFFFD700).withOpacity(0.3),
                ],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 20,
              color: Colors.white,
            ),
          );
        },
      );
    } else {
      // Use CachedNetworkImage for static images dengan cache busting
      return CachedNetworkImage(
        imageUrl: imageUrl,
        key: imageKey,
        fit: BoxFit.cover,
        httpHeaders: const {
          'Cache-Control': 'no-cache',
        },
        placeholder: (context, url) =>
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4AF37).withOpacity(0.3),
                    const Color(0xFFFFD700).withOpacity(0.3),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
        errorWidget: (context, url, error) =>
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFD4AF37).withOpacity(0.3),
                    const Color(0xFFFFD700).withOpacity(0.3),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
      );
    }
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const SeriesListScreen();
      case 1:
        return const FavoritesScreen(); // Use real FavoritesScreen
      case 2:
        return _buildComingSoonPage(
          icon: Icons.library_books_rounded,
          title: 'Library',
          subtitle: 'Your reading history and progress',
          description: 'Continue reading where you left off',
        );
      default:
        return const SeriesListScreen();
    }
  }

  Widget _buildComingSoonPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),

          // Animated Icon Container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD4AF37).withOpacity(0.2),
                        const Color(0xFFFFD700).withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 64,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Title with shimmer effect
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        LinearGradient(
                          colors: [
                            const Color(0xFFE8E8E8),
                            const Color(0xFFD4AF37),
                            const Color(0xFFE8E8E8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF232327),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFE8E8E8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

          // Coming Soon Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.2),
                  const Color(0xFFFFD700).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: const Color(0xFFD4AF37),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Coming Soon',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Additional Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1D),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'re working hard to bring you amazing new features!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Use the custom logo from assets
            Image.asset(
              'assets/logo.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'GrandLine',
              style: TextStyle(
                color: Color(0xFFE8E8E8),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1D),
        elevation: 0,
        actions: [
          if (currentUser != null) _buildProfileAvatar(),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF9E9E9E),
            ),
            color: const Color(0xFF232327),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation,
                          secondaryAnimation) => const ProfileScreen(),
                      transitionsBuilder: (context, animation,
                          secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                  if (result == true) {
                    // Clear cache dan reload profile setelah update
                    await _clearAvatarCache();
                    await _loadUserProfile();
                  }
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) =>
            [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_rounded, color: Color(0xFF9E9E9E)),
                    SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: TextStyle(color: Color(0xFFE8E8E8)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFD4AF37)),
                    SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(color: Color(0xFFE8E8E8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4AF37),
          strokeWidth: 3,
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: _buildCurrentPage(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1D),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: const Color(0xFF9E9E9E),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books_rounded),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/image_picker_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  User? user;
  bool isLoading = true;
  bool isEditMode = false;
  bool isUploadingImage = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late AnimationController _editController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _editAnimation;

  // Key untuk force rebuild image widget
  Key _imageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfile();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _editController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _editAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _editController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.getProfile();
      setState(() {
        user = profile;
        _nameController.text = profile.name;
        _emailController.text = profile.email;
        isLoading = false;
        // Generate new key untuk force rebuild image
        _imageKey = UniqueKey();
      });
      _controller.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Failed to load profile: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedUser = await AuthService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      setState(() {
        user = updatedUser;
        isEditMode = false;
      });

      _editController.reverse();
      _showSuccess('Profile updated successfully!');
    } catch (e) {
      _showError('Failed to update profile: $e');
    }
  }

  Future<void> _updateImage(File imageFile) async {
    setState(() {
      isUploadingImage = true;
    });

    try {
      // Check if it's a GIF before upload
      final isGif = imageFile.path.toLowerCase().endsWith('.gif');
      print('📤 Uploading ${isGif ? 'GIF' : 'static'} image: ${imageFile.path}');

      final updatedUser = await AuthService.updateProfileImage(imageFile);

      // CLEAR CACHED NETWORK IMAGE CACHE SEBELUM UPDATE STATE
      await _clearImageCache();

      setState(() {
        user = updatedUser;
        isUploadingImage = false;
        // PENTING: Generate new key untuk force rebuild image widget
        _imageKey = UniqueKey();
      });

      // Force additional rebuild untuk memastikan image ter-update
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          // Force rebuild lagi dengan delay
          _imageKey = UniqueKey();
        });
      }

      print('✅ Profile image updated: ${updatedUser.profileImageUrl}');
      _showSuccess(isGif
          ? 'Animated GIF profile photo updated successfully!'
          : 'Profile photo updated successfully!');
    } catch (e) {
      setState(() {
        isUploadingImage = false;
      });

      String errorMessage = e.toString();
      if (errorMessage.contains('Validation failed')) {
        errorMessage = 'Invalid image file. Please try a different image.';
      } else if (errorMessage.contains('413')) {
        errorMessage = 'Image file too large. Please use smaller image.';
      } else if (errorMessage.contains('422')) {
        errorMessage = 'Invalid image format. Please use JPG, PNG, GIF, or WEBP.';
      } else {
        errorMessage = 'Failed to upload image. Please try again.';
      }
      _showError(errorMessage);
    }
  }

  // Method untuk clear cache CachedNetworkImage
  Future<void> _clearImageCache() async {
    try {
      // Clear cache untuk user profile image
      if (user?.profileImageUrl != null) {
        await CachedNetworkImage.evictFromCache(user!.profileImageUrl!);
        print('🧹 Cache cleared for: ${user!.profileImageUrl}');
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });

    if (isEditMode) {
      _editController.forward();
    } else {
      _editController.reverse();
      // Reset form data
      if (user != null) {
        _nameController.text = user!.name;
        _emailController.text = user!.email;
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildProfileImage() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  const Color(0xFFFFD700).withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: user?.profileImageUrl != null
                  ? _buildProfileImageWidget(user!.profileImageUrl!)
                  : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFD4AF37).withOpacity(0.3),
                      const Color(0xFFFFD700).withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Camera Button
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: isUploadingImage
                  ? null
                  : () {
                ImagePickerService.showPicker(
                  context: context,
                  onImageSelected: (File file) {
                    _updateImage(file);
                  },
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUploadingImage
                    ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // IMPROVED: Helper method untuk handle different image types dengan cache busting
  Widget _buildProfileImageWidget(String imageUrl) {
    // Enhanced GIF detection - check both URL and file extension
    bool isGif = imageUrl.toLowerCase().contains('.gif') ||
        imageUrl.toLowerCase().endsWith('.gif') ||
        imageUrl.toLowerCase().contains('gif');

    // ADD CACHE BUSTING PARAMETER untuk force refresh
    String cacheBustingUrl = imageUrl;
    if (!imageUrl.contains('?')) {
      cacheBustingUrl += '?v=${DateTime.now().millisecondsSinceEpoch}';
    }

    print('Image URL: $imageUrl');
    print('Cache busting URL: $cacheBustingUrl');
    print('Is GIF detected: $isGif');

    if (isGif) {
      // Use Image.network for GIF animations dengan cache busting
      return Image.network(
        cacheBustingUrl,
        key: _imageKey, // PENTING: Use key untuk force rebuild
        fit: BoxFit.cover,
        headers: const {
          'Accept': 'image/gif,image/*,*/*',
          'Cache-Control': 'no-cache', // Force no cache
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('GIF loaded successfully');
            return child;
          }
          print('Loading GIF progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  const Color(0xFFFFD700).withOpacity(0.1),
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
                strokeWidth: 3,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading GIF: $error');
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  const Color(0xFFFFD700).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 60,
              color: Colors.white,
            ),
          );
        },
      );
    } else {
      // Use CachedNetworkImage for static images dengan cache busting
      print('Using CachedNetworkImage for static image');
      return CachedNetworkImage(
        imageUrl: cacheBustingUrl,
        key: _imageKey, // PENTING: Use key untuk force rebuild
        fit: BoxFit.cover,
        httpHeaders: const {
          'Cache-Control': 'no-cache', // Force no cache
        },
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.3),
                const Color(0xFFFFD700).withOpacity(0.1),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD4AF37),
              strokeWidth: 3,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          print('Error loading static image: $error');
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD4AF37).withOpacity(0.3),
                  const Color(0xFFFFD700).withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 60,
              color: Colors.white,
            ),
          );
        },
      );
    }
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF232327),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Name Field
            TextFormField(
              controller: _nameController,
              enabled: isEditMode,
              style: const TextStyle(
                color: Color(0xFFE8E8E8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: isEditMode
                      ? const Color(0xFFD4AF37)
                      : Colors.white.withOpacity(0.6),
                ),
                filled: true,
                fillColor: isEditMode
                    ? const Color(0xFF1A1A1D)
                    : Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isEditMode
                        ? const Color(0xFFD4AF37).withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isEditMode
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              enabled: isEditMode,
              style: const TextStyle(
                color: Color(0xFFE8E8E8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: isEditMode
                      ? const Color(0xFFD4AF37)
                      : Colors.white.withOpacity(0.6),
                ),
                filled: true,
                fillColor: isEditMode
                    ? const Color(0xFF1A1A1D)
                    : Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isEditMode
                        ? const Color(0xFFD4AF37).withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isEditMode
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4AF37),
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            if (!isEditMode) ...[
              const SizedBox(height: 16),

              // Member Since
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Member Since',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateTime.parse(user!.createdAt)
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                          style: const TextStyle(
                            color: Color(0xFFE8E8E8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          if (isEditMode) ...[
            // Save & Cancel Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleEditMode,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFE8E8E8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleEditMode,
                icon: const Icon(Icons.edit_rounded),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Change Password Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showSuccess('Change password feature coming soon!');
                },
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE8E8E8),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFFE8E8E8),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1D),
        foregroundColor: const Color(0xFFE8E8E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4AF37),
          strokeWidth: 3,
        ),
      )
          : user == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load profile',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFFE8E8E8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Profile Image
              _buildProfileImage(),

              const SizedBox(height: 12),

              // Tap to change photo hint
              Text(
                'Tap camera icon to change photo\n(Supports JPG, PNG, GIF, WEBP)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Info Card
              _buildInfoCard(),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
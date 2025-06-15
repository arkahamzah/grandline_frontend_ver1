import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/comic.dart';

class ImageReaderScreen extends StatefulWidget {
  final Comic comic;

  const ImageReaderScreen({super.key, required this.comic});

  @override
  State<ImageReaderScreen> createState() => _ImageReaderScreenState();
}

class _ImageReaderScreenState extends State<ImageReaderScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int currentPage = 0;
  bool showControls = true;
  bool isFullscreen = false;

  late AnimationController _controlsController;
  late AnimationController _pageInfoController;
  late Animation<double> _controlsAnimation;
  late Animation<double> _pageInfoAnimation;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _setFullscreen();
  }

  void _setupControllers() {
    _pageController = PageController();

    _controlsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pageInfoController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _setupAnimations() {
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeInOut,
    ));

    _pageInfoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageInfoController,
      curve: Curves.easeOut,
    ));

    if (showControls) {
      _controlsController.forward();
    }
  }

  void _setFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    setState(() {
      isFullscreen = true;
    });
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    setState(() {
      isFullscreen = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsController.dispose();
    _pageInfoController.dispose();
    _exitFullscreen();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      showControls = !showControls;
    });

    if (showControls) {
      _controlsController.forward();
    } else {
      _controlsController.reverse();
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showPageInfo() {
    _pageInfoController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _pageInfoController.reverse();
        }
      });
    });
  }

  Widget _buildPageIndicator() {
    return FadeTransition(
      opacity: _pageInfoAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 60, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          '${currentPage + 1} / ${widget.comic.pageCount}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (page) {
        setState(() {
          currentPage = page;
        });
        _showPageInfo();
      },
      itemCount: widget.comic.pagesUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: _toggleControls,
          child: InteractiveViewer(
            maxScale: 4.0,
            minScale: 0.8,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.comic.pagesUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFD4AF37),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading page ${index + 1}...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load page ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopControls() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(width: 16),

            // Chapter Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${widget.comic.chapterNumber}',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.comic.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Page Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '${currentPage + 1}/${widget.comic.pageCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Slider
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${currentPage + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFFD4AF37),
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: const Color(0xFFD4AF37),
                        overlayColor: const Color(0xFFD4AF37).withOpacity(0.2),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: currentPage.toDouble(),
                        min: 0,
                        max: (widget.comic.pageCount - 1).toDouble(),
                        divisions: widget.comic.pageCount - 1,
                        onChanged: (value) {
                          _goToPage(value.round());
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${widget.comic.pageCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Previous Button
                Container(
                  decoration: BoxDecoration(
                    color: currentPage > 0
                        ? const Color(0xFFD4AF37).withOpacity(0.2)
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentPage > 0
                          ? const Color(0xFFD4AF37).withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: currentPage > 0
                        ? () => _goToPage(currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: currentPage > 0
                        ? const Color(0xFFD4AF37)
                        : Colors.white.withOpacity(0.5),
                    iconSize: 32,
                  ),
                ),

                // Settings Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Implement reading settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reading settings coming soon!'),
                          backgroundColor: Color(0xFFD4AF37),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_rounded),
                    color: Colors.white,
                  ),
                ),

                // Next Button
                Container(
                  decoration: BoxDecoration(
                    color: currentPage < widget.comic.pageCount - 1
                        ? const Color(0xFFD4AF37).withOpacity(0.2)
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentPage < widget.comic.pageCount - 1
                          ? const Color(0xFFD4AF37).withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: currentPage < widget.comic.pageCount - 1
                        ? () => _goToPage(currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: currentPage < widget.comic.pageCount - 1
                        ? const Color(0xFFD4AF37)
                        : Colors.white.withOpacity(0.5),
                    iconSize: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Image Viewer
          _buildImageViewer(),

          // Page Indicator (top right)
          Positioned(
            top: 0,
            right: 0,
            child: _buildPageIndicator(),
          ),

          // Top Controls
          if (showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopControls(),
            ),

          // Bottom Controls
          if (showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
        ],
      ),
    );
  }
}
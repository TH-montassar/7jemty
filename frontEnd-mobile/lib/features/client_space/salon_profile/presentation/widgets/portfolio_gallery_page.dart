import 'package:flutter/material.dart';

class PortfolioGalleryPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const PortfolioGalleryPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<PortfolioGalleryPage> createState() => _PortfolioGalleryPageState();
}

class _PortfolioGalleryPageState extends State<PortfolioGalleryPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // باش الصفحة تتحل ديركت على التصويرة اللّي كليكا علاها
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // خلفية كحلة باش التصويرة تضوي
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // نكتبو الفوق قداش من تصويرة شاف (مثال: 2 / 9)
        title: Text(
          "${_currentIndex + 1} / ${widget.images.length}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      // Extend body باش التصويرة تاخو الشاشة كاملة ورا الـ AppBar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. عارض الصور (يخليك تسوايبي)
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                // هذي تخلي الكليون ينجم يعمل Zoom بصباعو
                child: Center(
                  child: Hero(
                    tag: 'portfolio_${widget.images[index]}',
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

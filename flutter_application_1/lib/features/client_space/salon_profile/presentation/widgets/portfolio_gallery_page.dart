import 'package:hjamty/core/localization/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:hjamty/core/constants/app_colors.dart';

class PortfolioGalleryPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const PortfolioGalleryPage({super.key, required this.images, required this.initialIndex});

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
          style: const TextStyle(color: Colors.white, fontSize: 16)
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
              return InteractiveViewer( // هذي تخلي الكليون ينجم يعمل Zoom بصباعو
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
          
          // 2. فلسة الحجز (Réserver ce style) اللوطة
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: تهزو لصفحة الـ Booking
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context, 'redirecting_to_reservation')), backgroundColor: AppColors.primaryBlue),
                  );
                },
                icon: const Icon(Icons.content_cut, color: Colors.white, size: 20),
                label: Text(tr(context, 'reserve_this_style'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionRed, // لون يجبد العين
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

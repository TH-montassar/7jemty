import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/portfolio_gallery_page.dart';

class PortfolioTab extends StatelessWidget {
  const PortfolioTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Mock Data: ليستة التصاور (حطيت نفس التصويرة باش نجربو، إنت تنجم تبدلهم)
    final List<String> portfolioImages = [
      'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1503342394128-c104d54dba01?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1503342394128-c104d54dba01?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1503342394128-c104d54dba01?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?auto=format&fit=crop&w=500&q=80',
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,        // 3 تصاور في السطر كيما الانستغرام
        crossAxisSpacing: 10,     // الفراغ بالعرض
        mainAxisSpacing: 10,      // الفراغ بالطول
      ),
      itemCount: portfolioImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // 🚀 2. كي يكليكي تهزو للـ Galerie ونبعثولو الليستة والـ Index اللي كليكا عليه
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PortfolioGalleryPage(
                  images: portfolioImages,
                  initialIndex: index,
                ),
              ),
            );
          },
          // 🚀 3. استعملنا Hero باش التصويرة تتأنما وقتلي تتحل وتتسكر
          child: Hero(
            tag: 'portfolio_${portfolioImages[index]}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                portfolioImages[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}
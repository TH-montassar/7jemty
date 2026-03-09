import 'package:flutter/material.dart';
import 'package:hjamty/features/client_space/salon_profile/presentation/widgets/portfolio_gallery_page.dart';

class PortfolioTab extends StatelessWidget {
  final Map<String, dynamic> salonData;

  const PortfolioTab({super.key, required this.salonData});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> portfolioList = salonData['portfolio'] ?? [];
    final List<String> portfolioImages = portfolioList
        .map((img) => img['imageUrl'] as String)
        .toList();

    if (portfolioImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              "Aucune image dans la galerie.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 تصاور في السطر كيما الانستغرام
        crossAxisSpacing: 10, // الفراغ بالعرض
        mainAxisSpacing: 10, // الفراغ بالطول
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
              child: Image.network(portfolioImages[index], fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }
}

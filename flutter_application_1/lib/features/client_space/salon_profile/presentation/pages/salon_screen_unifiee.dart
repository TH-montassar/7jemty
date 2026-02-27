import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../services/salon_service.dart';
import '../../../../patron_space/create_salon_screen.dart';
import '../widgets/salon_info_section.dart';
import '../widgets/sticky_tab_bar_delegate.dart';
import '../widgets/tafasil_tab.dart';
import '../widgets/services_tab.dart';
import '../widgets/specialist_tab.dart';
import '../widgets/rendezvous_tab.dart';
import '../widgets/reviews_tab.dart';
import '../../../../../core/localization/translation_service.dart';
// Needed for tr() if any string is localized

class SalonScreenUnifiee extends StatefulWidget {
  final bool isPatron;
  final int initialTabIndex;
  final bool openAddForm;

  const SalonScreenUnifiee({
    super.key,
    required this.isPatron,
    this.initialTabIndex = 0,
    this.openAddForm = false,
  });

  @override
  State<SalonScreenUnifiee> createState() => _SalonScreenUnifieeState();
}

class _SalonScreenUnifieeState extends State<SalonScreenUnifiee>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _salonData;
  late TabController _tabController;

  // ---------------------------------------------------------------------------
  // PATRON CONTROLLERS (For InfoTab / Paramètres)
  // ---------------------------------------------------------------------------
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _googleMapsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();

  // Image cover
  final TextEditingController _coverImageController = TextEditingController();
  Uint8List? _coverImageBytes;
  List<Map<String, String>> _socialLinks = [];

  // ---------------------------------------------------------------------------
  // PATRON CONTROLLERS (For Services Tab)
  // ---------------------------------------------------------------------------
  final TextEditingController _srvNameController = TextEditingController();
  final TextEditingController _srvDescController = TextEditingController();
  final TextEditingController _srvPriceController = TextEditingController();
  final TextEditingController _srvDurationController = TextEditingController();
  final TextEditingController _srvUrlController = TextEditingController();
  bool _isAddingService = false;
  bool _isSrvUrlMode = true;
  Uint8List? _srvSelectedImageBytes;

  // ---------------------------------------------------------------------------
  // PATRON CONTROLLERS (For Equipe Tab)
  // ---------------------------------------------------------------------------
  final TextEditingController _empNameController = TextEditingController();
  final TextEditingController _empPhoneController = TextEditingController();
  final TextEditingController _empPasswordController = TextEditingController();
  final TextEditingController _empRoleController = TextEditingController();
  final TextEditingController _empBioController = TextEditingController();
  final TextEditingController _empImageUrlController = TextEditingController();
  bool _isAddingSpecialist = false;
  bool _empPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final tabLength = widget.isPatron ? 6 : 4;
    final safeIndex = widget.initialTabIndex < tabLength
        ? widget.initialTabIndex
        : 0;
    _tabController = TabController(
      length: tabLength,
      vsync: this,
      initialIndex: safeIndex,
    );

    if (widget.openAddForm && widget.initialTabIndex == 1) {
      _isAddingService = true;
    }
    if (widget.openAddForm && widget.initialTabIndex == 2) {
      _isAddingSpecialist = true;
    }

    _fetchSalonData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _googleMapsController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _coverImageController.dispose();
    _websiteController.dispose();
    _specialityController.dispose();

    _srvNameController.dispose();
    _srvDescController.dispose();
    _srvPriceController.dispose();
    _srvDurationController.dispose();
    _srvUrlController.dispose();

    _empNameController.dispose();
    _empPhoneController.dispose();
    _empPasswordController.dispose();
    _empRoleController.dispose();
    _empBioController.dispose();
    _empImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalonData() async {
    setState(() => _isLoading = true);
    try {
      final response = await SalonService.getMySalon();
      final data = response['data'] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        _salonData = data;
        _isLoading = false;

        if (widget.isPatron && data != null && data.isNotEmpty) {
          _nameController.text = data['name']?.toString() ?? '';
          _descController.text = data['description']?.toString() ?? '';
          _phoneController.text = data['contactPhone']?.toString() ?? '';
          _addressController.text = data['address']?.toString() ?? '';
          _googleMapsController.text = data['googleMapsUrl']?.toString() ?? '';
          _websiteController.text = data['websiteUrl']?.toString() ?? '';
          _coverImageController.text = data['coverImageUrl']?.toString() ?? '';
          _specialityController.text = data['speciality']?.toString() ?? '';

          if (data['socialLinks'] != null) {
            final links = data['socialLinks'] as List;
            _socialLinks = links.map((link) {
              return {
                'platform': link['platform'] as String,
                'url': link['url'] as String,
              };
            }).toList();
          } else {
            _socialLinks = [];
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSaveAll() async {
    setState(() => _isLoading = true);
    try {
      String? finalCoverUrl = _coverImageController.text;
      if (_coverImageBytes != null) {
        final base64String = base64Encode(_coverImageBytes!);
        finalCoverUrl = 'data:image/jpeg;base64,$base64String';
      }

      await SalonService.updateSalonInfo(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        googleMapsUrl: _googleMapsController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        coverImageUrl: finalCoverUrl,
        speciality: _specialityController.text.trim(),
        socialLinks: _socialLinks.isNotEmpty ? _socialLinks : null,
      );

      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Mabrouk! 🎉',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: const Text(
          'Sauvegarde réussie',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.successGreen,
        backgroundColor: AppColors.successGreen,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );

      await _fetchSalonData();
    } catch (error) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Mochkla',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          error.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed,
        backgroundColor: AppColors.actionRed,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _coverImageBytes = bytes;
        _coverImageController.clear();
      });
    }
  }

  Future<void> _pickSrvImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _srvSelectedImageBytes = bytes;
        _isSrvUrlMode = false;
        _srvUrlController.clear();
      });
    }
  }

  Future<void> _handleAddService() async {
    if (_srvNameController.text.isEmpty ||
        _srvPriceController.text.isEmpty ||
        _srvDurationController.text.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Maaloumet ne9sa'),
        description: const Text('Lesm, soum wel wa9t lezmin'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);

      String? finalImageUrl;
      if (_isSrvUrlMode) {
        finalImageUrl = _srvUrlController.text.trim();
        if (finalImageUrl.isEmpty) finalImageUrl = null;
      } else if (_srvSelectedImageBytes != null) {
        final base64Image = base64Encode(_srvSelectedImageBytes!);
        finalImageUrl = "data:image/jpeg;base64,$base64Image";
      }

      await SalonService.createService(
        name: _srvNameController.text.trim(),
        price: double.parse(_srvPriceController.text.trim()),
        durationMinutes: int.parse(_srvDurationController.text.trim()),
        description: _srvDescController.text.trim(),
        imageUrl: finalImageUrl,
      );

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Zadna Service 🎉'),
        autoCloseDuration: const Duration(seconds: 3),
      );

      _srvNameController.clear();
      _srvPriceController.clear();
      _srvDurationController.clear();
      _srvDescController.clear();
      _srvUrlController.clear();
      setState(() {
        _srvSelectedImageBytes = null;
        _isAddingService = false;
      });

      await _fetchSalonData();
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Mochkla'),
        description: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper UI for images
  Widget _imagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primaryBlue,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    // If patron and no salon found
    if (widget.isPatron && _salonData == null) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "Ma famma hatta salon.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateSalonScreen(),
                        ),
                      ).then((_) => _fetchSalonData());
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      "Aamel salon mte3ek",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _fetchSalonData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Tijdid"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Determine the tabs based on role
    final List<Widget> tabs = [];
    final List<Widget> tabViews = [];

    if (widget.isPatron) {
      tabs.addAll([
        const Tab(text: "Paramètres"),
        const Tab(text: "Services"),
        const Tab(text: "Equipe"),
        const Tab(text: "Horaires"),
        const Tab(text: "Galerie"),
        const Tab(text: "Rendez-vous"),
      ]);
      tabViews.addAll([
        _buildInfoTabEditable(),
        _buildServicesTabEditable(),
        _buildEquipeTabEditable(),
        const Center(child: Text("Horaires Editables (Coming soon)")),
        const Center(child: Text("Galerie Editables (Coming soon)")),
        const RendezvousTab(), // The patron sees this
      ]);
    } else {
      tabs.addAll([
        const Tab(text: "Tafasil"),
        const Tab(text: "Services"),
        const Tab(text: "Spécialiste"),
        const Tab(text: "Avis"),
      ]);
      tabViews.addAll([
        const TafasilTab(),
        const ServicesTab(),
        const SpecialistTab(),
        const ReviewsTab(),
      ]);
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // 1. Header Image & AppBar
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryBlue,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (widget.isPatron)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 16.0,
                      top: 8,
                      bottom: 8,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _handleSaveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.white),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text(
                        "Sajjel kol chay",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: widget.isPatron
                    ? Text(
                        _salonData?['name']?.toString() ?? "Mon Salon",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      )
                    : null,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _salonData?['coverImageUrl'] ??
                          'https://images.unsplash.com/photo-1503951914875-452162b7f30a?auto=format&fit=crop&w=800&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey),
                    ),
                    Container(color: Colors.black.withOpacity(0.3)),
                  ],
                ),
              ),
            ),

            // 2. Infos Salon (Nom, Adresse, Rating, Status)
            if (!widget.isPatron)
              SliverToBoxAdapter(
                child: SalonInfoSection(salonData: _salonData ?? {}),
              ),

            // 3. Sticky Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.primaryBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primaryBlue,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: tabs,
                ),
              ),
            ),
          ];
        },

        // 4. Tab content
        body: TabBarView(controller: _tabController, children: tabViews),
      ),
    );
  }

  // ============================================
  // INFO TAB (Paramètres) - EDITABLE FOR PATRON
  // ============================================
  Widget _buildInfoTabEditable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cover Image ──
          _buildSectionHeader(
            Icons.image_outlined,
            "Taswira mta3 salon (cover)",
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickCoverImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _coverImageBytes != null
                      ? Image.memory(
                          _coverImageBytes!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : (_coverImageController.text.isNotEmpty &&
                            !_coverImageController.text.startsWith('data:'))
                      ? Image.network(
                          _coverImageController.text,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            _imagePlaceholder(),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const Icon(
                              Icons.add_a_photo,
                              color: AppColors.primaryBlue,
                              size: 22,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: const Icon(Icons.upload_outlined, size: 18),
                      label: const Text("Plodi mel galerie"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInputField(
                      _coverImageController,
                      "aw 7ott URL mte3 taswira...",
                      Icons.link,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // ── Identité ──
          _buildSectionHeader(Icons.storefront_outlined, "Identité"),
          const SizedBox(height: 12),
          _buildLabelInput("Esm e-salon"),
          _buildInputField(_nameController, "Esm e-salon", Icons.title),
          const SizedBox(height: 10),
          _buildLabelInput("Description"),
          _buildInputField(
            _descController,
            "Chneya les services w el jaw fel salon?",
            Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 10),
          _buildLabelInput("Spécialité"),
          _buildInputField(
            _specialityController,
            "ex: Coiffure, Barbershop...",
            Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 30),

          // ── Contact ──
          _buildSectionHeader(Icons.contact_phone_outlined, "Contact"),
          const SizedBox(height: 12),
          _buildLabelInput("Numéro de contact"),
          _buildInputField(
            _phoneController,
            "ex: 50 123 456",
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 30),

          // ── Localisation ──
          _buildSectionHeader(Icons.location_on_outlined, "Localisation"),
          const SizedBox(height: 12),
          _buildLabelInput("Adresse"),
          _buildInputField(
            _addressController,
            "Adresse complète",
            Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          _buildLabelInput("Google Maps URL"),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
                  _googleMapsController,
                  "https://maps.google.com/?q=...",
                  Icons.map_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Material(
                  color: _googleMapsController.text.isNotEmpty
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _googleMapsController.text.isNotEmpty
                        ? () async {
                            try {
                              await launchUrl(
                                Uri.parse(_googleMapsController.text),
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {
                              await launchUrl(
                                Uri.parse(_googleMapsController.text),
                                mode: LaunchMode.platformDefault,
                              );
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: const Icon(
                        Icons.open_in_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // ── Web & Réseaux sociaux ──
          _buildLabelInput("Site web"),
          _buildInputField(
            _websiteController,
            "https://www.mon-salon.com",
            Icons.language_outlined,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.share_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Réseaux sociaux",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSocialLinksList(),
          const SizedBox(height: 12),
          _SocialLinkAdder(
            existingPlatforms: _socialLinks.map((l) => l['platform']!).toList(),
            onAdd: (platform, url) {
              setState(() {
                _socialLinks.add({'platform': platform, 'url': url});
              });
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ... (Helper UI methods like _buildSectionHeader, _buildLabelInput, _buildInputField, etc.)
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildLabelInput(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hintText,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppColors.primaryBlue, size: 20)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 20),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLinksList() {
    return Column(
      children: _socialLinks.map((link) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _socialIcon(link['platform']!),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _platformLabel(link['platform']!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      link['url']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _socialLinks.remove(link));
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _socialIcon(String platform) {
    switch (platform) {
      case 'instagram':
        return const Text('📸', style: TextStyle(fontSize: 20));
      case 'facebook':
        return const Icon(Icons.facebook, color: Colors.blue, size: 20);
      case 'tiktok':
        return const Text('🎵', style: TextStyle(fontSize: 20)); // Fake TikTok
      case 'snapchat':
        return const Text('👻', style: TextStyle(fontSize: 20));
      case 'youtube':
        return const Icon(Icons.video_library, color: Colors.red, size: 20);
      case 'twitter':
        return const Text('🐦', style: TextStyle(fontSize: 20)); // X
      case 'linkedin':
        return const Text('💼', style: TextStyle(fontSize: 20));
      default:
        return const Icon(Icons.link, color: Colors.grey, size: 20);
    }
  }

  String _platformLabel(String platform) {
    switch (platform) {
      case 'instagram':
        return "Instagram";
      case 'facebook':
        return "Facebook";
      case 'tiktok':
        return "TikTok";
      case 'snapchat':
        return "Snapchat";
      case 'youtube':
        return "YouTube";
      case 'twitter':
        return "X (Twitter)";
      case 'linkedin':
        return "LinkedIn";
      default:
        return "Autre";
    }
  }

  // ============================================
  // SERVICES TAB - EDITABLE FOR PATRON
  // ============================================
  Widget _buildServicesTabEditable() {
    final services = _salonData?['services'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Les services",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingService = !_isAddingService;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(
                  _isAddingService ? Icons.close : Icons.add,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  _isAddingService ? "Saker" : "Zid service",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isAddingService) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "SERVICE JDID",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isSrvUrlMode = true;
                            _srvSelectedImageBytes = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSrvUrlMode
                              ? AppColors.primaryBlue
                              : Colors.white,
                          foregroundColor: _isSrvUrlMode
                              ? Colors.white
                              : AppColors.textDark,
                          elevation: 0,
                          side: BorderSide(
                            color: _isSrvUrlMode
                                ? AppColors.primaryBlue
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(
                          Icons.link,
                          size: 16,
                          color: _isSrvUrlMode
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                        label: const Text("URL"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _pickSrvImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isSrvUrlMode
                              ? AppColors.primaryBlue
                              : Colors.white,
                          foregroundColor: !_isSrvUrlMode
                              ? Colors.white
                              : AppColors.textDark,
                          elevation: 0,
                          side: BorderSide(
                            color: !_isSrvUrlMode
                                ? AppColors.primaryBlue
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(
                          Icons.upload,
                          size: 16,
                          color: !_isSrvUrlMode ? Colors.white : Colors.grey,
                        ),
                        label: Text(
                          "Plodi mel galerie",
                          style: TextStyle(
                            color: !_isSrvUrlMode ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isSrvUrlMode)
                    _buildInputField(
                      _srvUrlController,
                      "Hott lien mtaa taswira...",
                      Icons.link,
                    )
                  else if (_srvSelectedImageBytes != null)
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _srvSelectedImageBytes!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: -10,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _srvSelectedImageBytes = null;
                                  _isSrvUrlMode = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Esm el service"),
                  _buildInputField(
                    _srvNameController,
                    "Esm service",
                    Icons.design_services,
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Soum (TND)"),
                  _buildInputField(
                    _srvPriceController,
                    "Soum",
                    Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Wa9t (bl minute)"),
                  _buildInputField(
                    _srvDurationController,
                    "Wa9t (min)",
                    Icons.timer_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Description"),
                  _buildInputField(
                    _srvDescController,
                    "Detail 3el service...",
                    Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleAddService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Sajjel el service",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (services.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Ma famma 7atta service ltawa.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final srv = services[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          srv['imageUrl'] ?? 'https://via.placeholder.com/60',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.cut_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              srv['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${srv['durationMinutes']} min",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${srv['price']} TND",
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ============================================
  // EQUIPE TAB - EDITABLE FOR PATRON
  // ============================================
  Future<void> _handleAddSpecialist() async {
    if (_empNameController.text.isEmpty ||
        _empPhoneController.text.isEmpty ||
        _empPasswordController.text.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Maaloumet ne9sa'),
        description: const Text('Esm, noumro wel kelmet essir lezmin'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    try {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);
      await SalonService.createEmployeeAccount(
        name: _empNameController.text.trim(),
        phoneNumber: _empPhoneController.text.trim(),
        password: _empPasswordController.text.trim(),
        role: _empRoleController.text.trim().isEmpty
            ? null
            : _empRoleController.text.trim(),
        bio: _empBioController.text.trim().isEmpty
            ? null
            : _empBioController.text.trim(),
        imageUrl: _empImageUrlController.text.trim().isEmpty
            ? null
            : _empImageUrlController.text.trim(),
      );
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Spécialiste mzid 🎉'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      _empNameController.clear();
      _empPhoneController.clear();
      _empPasswordController.clear();
      _empRoleController.clear();
      _empBioController.clear();
      _empImageUrlController.clear();
      setState(() => _isAddingSpecialist = false);
      await _fetchSalonData();
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Mochkla'),
        description: Text(e.toString().replaceAll('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildEquipeTabEditable() {
    final employees = (_salonData?['employees'] as List<dynamic>?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${employees.length} spécialiste${employees.length != 1 ? 's' : ''}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _isAddingSpecialist = !_isAddingSpecialist),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(
                  _isAddingSpecialist ? Icons.close : Icons.person_add_alt_1,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  _isAddingSpecialist ? "Saker" : "+ Zid Spécialiste",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isAddingSpecialist) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "SPÉCIALISTE JDID",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabelInput("Esm el spécialiste *"),
                  _buildInputField(
                    _empNameController,
                    "Esm w Lqeb",
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Noumro Téléphone *"),
                  _buildInputField(
                    _empPhoneController,
                    "ex: 50 123 456",
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Kelmet essir *"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _empPasswordController,
                            obscureText: !_empPasswordVisible,
                            decoration: InputDecoration(
                              hintText: "Kelmet essir mte3 el compte",
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _empPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _empPasswordVisible = !_empPasswordVisible,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Spécialité / Rôle"),
                  _buildInputField(
                    _empRoleController,
                    "ex: Coiffeur, Barbier...",
                    Icons.auto_awesome_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Bio (optionnel)"),
                  _buildInputField(
                    _empBioController,
                    "Quelques mots sur le spécialiste...",
                    Icons.info_outline,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _buildLabelInput("Photo URL (optionnel)"),
                  _buildInputField(
                    _empImageUrlController,
                    "https://... lien mte3 taswira",
                    Icons.image_outlined,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleAddSpecialist,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Enregistrer le Spécialiste",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (employees.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Ma famma 7atta spécialiste ltawa.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final emp = employees[index] as Map<String, dynamic>;
                final name = emp['name']?.toString() ?? 'Spécialiste';
                final role = emp['role']?.toString() ?? 'Spécialiste';
                final bio = emp['bio'] as String?;
                final imageUrl = emp['imageUrl'] as String?;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (bio != null && bio.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                bio,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SOCIAL ADDER COMPONENT
// ---------------------------------------------------------------------------
class _SocialLinkAdder extends StatefulWidget {
  final List<String> existingPlatforms;
  final Function(String platform, String url) onAdd;

  const _SocialLinkAdder({
    required this.existingPlatforms,
    required this.onAdd,
  });

  @override
  State<_SocialLinkAdder> createState() => _SocialLinkAdderState();
}

class _SocialLinkAdderState extends State<_SocialLinkAdder> {
  bool _expanded = false;
  String _selectedPlatform = 'instagram';
  final _urlController = TextEditingController();

  static const _platforms = [
    {'id': 'instagram', 'label': 'Instagram'},
    {'id': 'facebook', 'label': 'Facebook'},
    {'id': 'tiktok', 'label': 'TikTok'},
    {'id': 'snapchat', 'label': 'Snapchat'},
    {'id': 'youtube', 'label': 'YouTube'},
    {'id': 'twitter', 'label': 'X (Twitter)'},
    {'id': 'linkedin', 'label': 'LinkedIn'},
    {'id': 'other', 'label': 'Autre'},
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (widget.existingPlatforms.contains(_selectedPlatform) &&
        _selectedPlatform != 'other') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${_platforms.firstWhere((p) => p['id'] == _selectedPlatform)['label']} deja mawjouda!",
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onAdd(_selectedPlatform, url);
    _urlController.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final available = _platforms
        .where(
          (p) =>
              !widget.existingPlatforms.contains(p['id']) || p['id'] == 'other',
        )
        .toList();

    if (!_expanded) {
      return OutlinedButton.icon(
        onPressed: available.isEmpty
            ? null
            : () => setState(() {
                _expanded = true;
                _selectedPlatform = available.first['id']!;
              }),
        icon: const Icon(Icons.add, size: 18),
        label: Text(
          available.isEmpty ? "Zedna kol platform" : "+ Zid réseau social",
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: BorderSide(
            color: available.isEmpty
                ? Colors.grey.shade300
                : AppColors.primaryBlue,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedPlatform,
            decoration: InputDecoration(
              labelText: "Platform",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: available
                .map(
                  (p) => DropdownMenuItem<String>(
                    value: p['id'],
                    child: Text(p['label']!),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedPlatform = v!),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: "https://...",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Zid",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _expanded = false),
                child: const Text(
                  "Batel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

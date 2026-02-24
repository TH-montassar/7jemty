import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../../core/constants/app_colors.dart';
import '../../services/salon_service.dart';

class SalonSettingsScreen extends StatefulWidget {
  const SalonSettingsScreen({super.key});

  @override
  State<SalonSettingsScreen> createState() => _SalonSettingsScreenState();
}

class _SalonSettingsScreenState extends State<SalonSettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _salonData;
  late TabController _tabController;

  // Controllers pour l'onglet "Info"
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Controllers pour l'onglet "Personnel"
  final TextEditingController _specUrlController = TextEditingController();
  final TextEditingController _specNameController = TextEditingController();
  final TextEditingController _specRoleController = TextEditingController();
  final TextEditingController _specBioController = TextEditingController();
  bool _isAddingSpecialist = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchSalonData();
  }

  Future<void> _fetchSalonData() async {
    try {
      final response = await SalonService.getMySalon();
      if (!mounted) return;

      setState(() {
        _salonData = response['data'];

        // Populate Info Tab
        _nameController.text = _salonData?['name'] ?? '';
        _descController.text = _salonData?['description'] ?? '';
        _phoneController.text = _salonData?['contactPhone'] ?? '';
        _addressController.text = _salonData?['address'] ?? '';

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Erreur',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          e.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed,
        backgroundColor: AppColors.actionRed,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        showProgressBar: false,
      );
    }
  }

  Future<void> _handleSaveAll() async {
    // Appel API pour sauvegarder toutes les modifications du salon.
    // Pour l'instant on sauvegarde uniquement les "Info" (updateSalonInfo)
    try {
      FocusScope.of(context).unfocus();
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 2),
        title: const Text(
          'Enregistrement...',
          style: TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.primaryBlue,
        backgroundColor: AppColors.primaryBlue,
        showProgressBar: false,
      );

      await SalonService.updateSalonInfo(
        description: _descController.text,
        contactPhone: _phoneController.text,
        // TODO: Backend does not currently support updating "name" and "address"
        // in updateSalonSchema. It only supports description and contactPhone.
      );

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Enregistré 🎉',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        primaryColor: AppColors.successGreen,
        backgroundColor: AppColors.successGreen,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        showProgressBar: false,
      );
    } catch (error) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
        title: const Text(
          'Erreur',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          error.toString(),
          style: const TextStyle(color: Colors.white),
        ),
        primaryColor: AppColors.actionRed,
        backgroundColor: AppColors.actionRed,
        icon: const Icon(Icons.error_outline, color: Colors.white),
        showProgressBar: false,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    _specUrlController.dispose();
    _specNameController.dispose();
    _specRoleController.dispose();
    _specBioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_salonData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Aucun salon trouvé.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchSalonData,
              child: const Text("Rafraîchir"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Paramètres du salon",
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              "@${_salonData?['name']?.toString().replaceAll(' ', '').toLowerCase() ?? 'mon_salon'}",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _handleSaveAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(
                Icons.save_outlined,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                "Tout enregistrer",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primaryBlue,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              splashBorderRadius: BorderRadius.circular(20),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 6),
                        Text("Info"),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.cut_outlined, size: 16),
                        SizedBox(width: 6),
                        Text("Services"),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.group_outlined, size: 16),
                        SizedBox(width: 6),
                        Text("Personnel"),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16),
                        SizedBox(width: 6),
                        Text("Horaires"),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.image_outlined, size: 16),
                        SizedBox(width: 6),
                        Text("Galerie"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildServicesTab(),
          _buildPersonnelTab(),
          _buildHorairesTab(),
          _buildGalerieTab(),
        ],
      ),
    );
  }

  // ============================================
  // TABS BUILDERS
  // ============================================

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Informations générales",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          _buildLabelInput("Nom du salon"),
          _buildInputField(
            _nameController,
            "Nom du Salon (ex: Barbershop VIP)",
            Icons.title,
          ),
          const SizedBox(height: 16),
          _buildLabelInput("Description"),
          _buildInputField(
            _descController,
            "Description du salon",
            Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _buildLabelInput("Téléphone de contact"),
          _buildInputField(
            _phoneController,
            "Numéro de contact du salon",
            Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildLabelInput("Adresse complète"),
          _buildInputField(
            _addressController,
            "Adresse",
            Icons.location_on_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return const Center(
      child: Text(
        "Gestion des services (À venir)",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildPersonnelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Gérer le personnel",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAddingSpecialist = !_isAddingSpecialist;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: Icon(
                  _isAddingSpecialist ? Icons.close : Icons.add,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  _isAddingSpecialist ? "Fermer" : "Ajouter un spécialiste",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isAddingSpecialist) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "NOUVEAU SPÉCIALISTE",
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
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textDark,
                          elevation: 0,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text("URL"),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.upload,
                          size: 16,
                          color: Colors.grey,
                        ),
                        label: const Text(
                          "Upload",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    _specUrlController,
                    "Enter direct image URL...",
                    null,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(_specNameController, "Nom complet", null),
                  const SizedBox(height: 12),
                  _buildInputField(
                    _specRoleController,
                    "Rôle (ex: Maître Barbier)",
                    null,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    _specBioController,
                    "Bio",
                    null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Enregistrer",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isAddingSpecialist = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Annuler",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  "Aucun spécialiste ajouté",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorairesTab() {
    final List<String> jours = [
      "Lundi",
      "Mardi",
      "Mercredi",
      "Jeudi",
      "Vendredi",
      "Samedi",
      "Dimanche",
    ];
    // Mocking state (fermé le lundi)

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Heures d'ouverture",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          ...jours.map((jour) {
            bool isOuvert = jour != "Lundi";
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      jour,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOuvert
                            ? AppColors.successGreen.withAlpha(20)
                            : AppColors.actionRed.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOuvert ? "Ouvert" : "Fermé",
                        style: TextStyle(
                          color: isOuvert
                              ? AppColors.successGreen
                              : AppColors.actionRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isOuvert) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "09:00 AM",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "à",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "06:00 PM",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGalerieTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Galerie du salon",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ), // Should be dashed ideally
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "AJOUTER À LA GALERIE",
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textDark,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text("URL"),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.upload,
                        size: 16,
                        color: Colors.grey,
                      ),
                      label: const Text(
                        "Upload",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  TextEditingController(),
                  "Enter direct image URL...",
                  null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  "NEW IMAGE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  Widget _buildLabelInput(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hintText,
    IconData? icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: icon != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(icon, color: Colors.grey.shade400, size: 20),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
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
}

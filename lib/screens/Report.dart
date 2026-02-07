import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // متغيرات الحالة (State)
  String selectedCategory = 'نفايات';
  String selectedPriority = 'مرتفعة';
  final TextEditingController _descriptionController = TextEditingController();

  File? _image; // لتخزين الصورة الملتقطة
  String _locationStatus = "سيئون ، حي الوحدة"; // نص الموقع الافتراضي
  bool _isLoadingLocation = false; // لحالة تحميل الموقع

  // قائمة الفئات المعروضة في الشبكة
  final List<Map<String, dynamic>> categories = [
    {
      'id': 'نفايات',
      'label': 'نفايات',
      'icon': Icons.delete_outline,
      'color': const Color(0xFF27ae60),
      'bg': const Color(0xFFe8f5e9),
    },
    {
      'id': 'بناء',
      'label': 'بناء وصيانة',
      'icon': Icons.construction,
      'color': const Color(0xFFe67e22),
      'bg': const Color(0xFFfff3e0),
    },
    {
      'id': 'إنارة',
      'label': 'إنارة',
      'icon': Icons.lightbulb_outline,
      'color': const Color(0xFFf1c40f),
      'bg': const Color(0xFFfef9e7),
    },
    {
      'id': 'مياه',
      'label': 'مياه',
      'icon': Icons.opacity,
      'color': const Color(0xFF3498db),
      'bg': const Color(0xFFebf5fb),
    },
    {
      'id': 'حدائق',
      'label': 'حدائق',
      'icon': Icons.park_outlined,
      'color': const Color(0xFF1abc9c),
      'bg': const Color(0xFFeafff5),
    },
    {
      'id': 'أخرى',
      'label': 'أخرى',
      'icon': Icons.help_outline,
      'color': const Color(0xFF95a5a6),
      'bg': const Color(0xFFf4f6f7),
    },
  ];

  // دالة التقاط الصورة
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // لتقليل حجم الصورة قبل إرسالها لـ Laravel
      );

      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // دالة تحديد الموقع الجغرافي
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _locationStatus =
              "إحداثيات: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      debugPrint("Error location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("نوع البلاغ *", style: sectionTitleStyle),
                    const SizedBox(height: 15),
                    _buildCategoryGrid(),
                    const SizedBox(height: 30),
                    const Text("الأولوية *", style: sectionTitleStyle),
                    const SizedBox(height: 15),
                    _buildPrioritySelector(),
                    const SizedBox(height: 30),
                    const Text("الموقع *", style: sectionTitleStyle),
                    const SizedBox(height: 15),
                    _buildLocationCard(),
                    const SizedBox(height: 30),
                    const Text("الصورة (اختياري)", style: sectionTitleStyle),
                    const SizedBox(height: 15),
                    _buildImagePicker(),
                    const SizedBox(height: 30),
                    const Text("ملاحظات إضافية", style: sectionTitleStyle),
                    const SizedBox(height: 15),
                    _buildDescriptionField(),
                    const SizedBox(height: 35),
                    _buildPointsInfo(),
                    const SizedBox(height: 35),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // الجزء العلوي (Header)
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2ecc71), Color(0xFF27ae60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              const Text(
                "بلاغ جديد",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Text(
              "ساعد في تحسين مدينتك من خلال الإبلاغ عن المشكلات، سنعمل على حلها في أقرب وقت.",
              style: TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // شبكة اختيار نوع البلاغ
  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        bool isSelected = selectedCategory == cat['id'];
        return GestureDetector(
          onTap: () => setState(() => selectedCategory = cat['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF2ecc71) : Colors.grey.shade200,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: cat['bg'],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(cat['icon'], color: cat['color'], size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  cat['label'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // اختيار الأولوية
  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _priorityItem(
          "منخفضة",
          const Color(0xFFdcfce7),
          const Color(0xFF166534),
        ),
        const SizedBox(width: 10),
        _priorityItem(
          "متوسطة",
          const Color(0xFFfef9c3),
          const Color(0xFF854d0e),
        ),
        const SizedBox(width: 10),
        _priorityItem(
          "مرتفعة",
          const Color(0xFFfee2e2),
          const Color(0xFF991b1b),
        ),
      ],
    );
  }

  Widget _priorityItem(String label, Color bg, Color text) {
    bool isActive = selectedPriority == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPriority = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? text : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFf1f5f9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _locationStatus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "الموقع الحالي للمخالفة",
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748b)),
                ),
              ],
            ),
          ),
          _isLoadingLocation
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : TextButton(
                onPressed: _getCurrentLocation,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "تحديد",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200, // زيادة الطول قليلاً لعرض الصورة بشكل أوضح
        decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFcbd5e1), width: 2),
          image:
              _image != null
                  ? DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            _image == null
                ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 42,
                      color: Color(0xFF94a3b8),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "اضغط لالتقاط صورة للمخالفة",
                      style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
                    ),
                  ],
                )
                : Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _image = null),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "صف المشكلة بدقة لمساعدة الفريق الميداني...",
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
        ),
      ),
    );
  }

  Widget _buildPointsInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFf5f3ff),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFddd6fe)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF7c3aed), size: 26),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "نظام النقاط",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5b21b6),
                  ),
                ),
                const Text(
                  "ستحصل على 100 نقطة عند قبول البلاغ، و 250 نقطة إذا تم تصنيفه كحالة طارئة.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6d28d9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        debugPrint(
          "Sending: $selectedCategory, Location: $_locationStatus, Image: ${_image?.path}",
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF27ae60),
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: const Text(
        "إرسال البلاغ للصندوق",
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

const sectionTitleStyle = TextStyle(
  fontSize: 16,
  color: Color(0xFF0f172a),
  fontWeight: FontWeight.bold,
);

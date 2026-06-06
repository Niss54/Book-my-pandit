import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = context.read<AuthProvider>();
    
    await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      imagePath: _selectedImage?.path,
    );
    
    if (mounted) {
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage!), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F8),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('User not found.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFF6ED),
                              border: Border.all(color: const Color(0xFFFF9933), width: 2),
                            ),
                            child: ClipOval(
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                  : (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: user.profilePictureUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: Color(0xFF8F4E00)),
                                        )
                                      : const Icon(Icons.person, size: 60, color: Color(0xFF8F4E00)),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8F4E00),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 20),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8F4E00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

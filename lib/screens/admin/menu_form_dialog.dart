import 'package:flutter/material.dart';
import 'package:kebuli_mimi/models/menu_model.dart';
import 'package:kebuli_mimi/services/menu_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:kebuli_mimi/utils/error_handler.dart';

class MenuFormDialog extends StatefulWidget {
  final Menu? menu;
  final MenuService menuService;

  const MenuFormDialog({super.key, this.menu, required this.menuService});

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  Kategori? _selectedKategori;
  late Future<List<Kategori>> _kategoriFuture;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  bool get _isEditing => widget.menu != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menu?.namaMenu);
    _priceController = TextEditingController(
      text: widget.menu?.harga.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(
      text: widget.menu?.deskripsi,
    );
    _kategoriFuture = widget.menuService.getCategories();

    if (_isEditing) {
      _selectedKategori = widget.menu?.kategori;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (selectedImage != null) {
      setState(() {
        _imageFile = selectedImage;
      });
    }
  }

  Future<void> _saveMenu() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedKategori == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih kategori terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      final data = {
        'nama_menu': _nameController.text,
        'harga': double.parse(_priceController.text),
        'deskripsi': _descriptionController.text,
        'id_kategori': _selectedKategori!.id,
      };

      try {
        if (_isEditing) {
          await widget.menuService.updateMenu(
            widget.menu!.id,
            data,
            imageFile: _imageFile,
            oldImageUrl: widget.menu!.gambar,
          );
        } else {
          await widget.menuService.addMenu(data, imageFile: _imageFile);
        }
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          if (mounted) ErrorHandler.showSnackBar(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Menu' : 'Tambah Menu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Menu',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Harga tidak boleh kosong';
                  if (double.tryParse(value) == null)
                    return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveMenu,
          child:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<Kategori>>(
      future: _kategoriFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Gagal memuat kategori.');
        }

        final categories = snapshot.data!;
        // Pastikan nilai awal (_selectedKategori) ada di dalam list
        if (_isEditing &&
            _selectedKategori != null &&
            !categories.contains(_selectedKategori)) {
          _selectedKategori = categories.firstWhere(
            (c) => c.id == _selectedKategori!.id,
            orElse: () => categories.first,
          );
        }

        return DropdownButtonFormField<Kategori>(
          value: _selectedKategori,
          decoration: const InputDecoration(
            labelText: 'Kategori',
            border: OutlineInputBorder(),
          ),
          items:
              categories.map((Kategori kategori) {
                return DropdownMenuItem<Kategori>(
                  value: kategori,
                  child: Text(kategori.namaKategori),
                );
              }).toList(),
          onChanged: (Kategori? newValue) {
            setState(() {
              _selectedKategori = newValue;
            });
          },
          validator: (value) => value == null ? 'Kategori harus dipilih' : null,
        );
      },
    );
  }

  Widget _buildImagePicker() {
    // UI Logic untuk memilih gambar
    return Center(
      child: Column(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                _imageFile != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imageFile!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                    : (widget.menu?.gambar != null &&
                            widget.menu!.gambar!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.menu!.gambar!,
                            fit: BoxFit.cover,
                          ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )),
          ),
          TextButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Pilih Gambar'),
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }
}

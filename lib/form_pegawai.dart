import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'model_pegawai.dart';
import 'database_helper.dart';
import 'utils.dart';

class FormPegawai extends StatefulWidget {
  final Pegawai? pegawai;
  const FormPegawai({super.key, this.pegawai});

  @override
  State<FormPegawai> createState() => _FormPegawaiState();
}

class _FormPegawaiState extends State<FormPegawai> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _posisiController = TextEditingController();
  final _gajiController = TextEditingController();
  final _alamatController = TextEditingController();

  double _latitude = 0.0;
  double _longitude = 0.0;
  String _fotoPath = '';
  bool _isLoadingLocation = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.pegawai != null) {
      final p = widget.pegawai!;
      _namaController.text = p.nama;
      _posisiController.text = p.posisi;
      _gajiController.text = p.gaji.toString();
      _alamatController.text = p.alamat;
      _latitude = p.latitude;
      _longitude = p.longitude;
      _fotoPath = p.foto;
    }
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    final position = await Utils.getCurrentLocation();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    }
    setState(() => _isLoadingLocation = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final savedPath = await Utils.saveImageToLocal(File(image.path));
        setState(() => _fotoPath = savedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pegawai = Pegawai(
      id: widget.pegawai?.id,
      nama: _namaController.text,
      posisi: _posisiController.text,
      gaji: int.parse(_gajiController.text),
      alamat: _alamatController.text,
      latitude: _latitude,
      longitude: _longitude,
      foto: _fotoPath,
    );

    if (widget.pegawai == null) {
      await DatabaseHelper().insert(pegawai);
    } else {
      await DatabaseHelper().update(pegawai);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.pegawai == null ? 'Data disimpan' : 'Data diperbarui')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pegawai == null ? 'Tambah Pegawai' : 'Edit Pegawai'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto
              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _fotoPath.isNotEmpty ? FileImage(File(_fotoPath)) : null,
                    child: _fotoPath.isEmpty
                        ? const Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Nama harus diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _posisiController,
                decoration: const InputDecoration(
                  labelText: 'Posisi/Jabatan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (v) => v!.isEmpty ? 'Posisi harus diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gajiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gaji',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v!.isEmpty) return 'Gaji harus diisi';
                  if (int.tryParse(v) == null) return 'Harus angka';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 20),
              // Lokasi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lokasi GPS',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            if (_isLoadingLocation)
                              const LinearProgressIndicator()
                            else
                              Text(
                                'Lat: ${_latitude.toStringAsFixed(6)}\nLong: ${_longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Segarkan Lokasi',
                        onPressed: _getLocation,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
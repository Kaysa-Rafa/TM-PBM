import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class AddDataPage extends StatefulWidget {
  @override
  _AddDataPageState createState() => _AddDataPageState();
}

class _AddDataPageState extends State<AddDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _posisiCtrl = TextEditingController();
  final _gajiCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  File? _imageFile;
  double? lat, lng;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;

  // Ganti IP ini
  final String baseUrl = 'http://192.168.x.x/crud_pegawai/';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Otomatis deteksi GPS saat form dibuka
  }

  // ---------- PERMISSION & GET POSITION (GPS) ----------
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Izin ditolak, tampilkan pesan
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Izin lokasi diperlukan')));
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Izin ditolak selamanya, arahkan ke pengaturan
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buka pengaturan untuk mengizinkan lokasi')));
        setState(() => _isLoadingLocation = false);
        return;
      }
      // Dapatkan posisi terbaru
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      print('Error getting location: $e');
    }
    setState(() => _isLoadingLocation = false);
  }

  // ---------- AMBIL FOTO DARI KAMERA/GALERI ----------
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: Icon(Icons.camera_alt), title: Text('Kamera'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
            ListTile(leading: Icon(Icons.photo_library), title: Text('Galeri'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
          ],
        ),
      ),
    );
  }

  // ---------- KIRIM DATA DENGAN MULTIPART REQUEST (FOTO) ----------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoadingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Menunggu lokasi...')));
      return;
    }
    setState(() => _isSubmitting = true);

    // Buat URI endpoint
    var uri = Uri.parse('${baseUrl}create.php');
    // Siapkan MultipartRequest
    var request = http.MultipartRequest('POST', uri);

    // Tambahkan field teks biasa
    request.fields['nama'] = _namaCtrl.text;
    request.fields['posisi'] = _posisiCtrl.text;
    request.fields['gaji'] = _gajiCtrl.text;
    request.fields['alamat'] = _alamatCtrl.text;
    request.fields['latitude'] = lat?.toString() ?? '';
    request.fields['longitude'] = lng?.toString() ?? '';

    // Jika ada file foto, lampirkan sebagai multipart file
    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', _imageFile!.path),
      );
      // 'foto' adalah key yang diharapkan oleh backend
    }

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil ditambahkan')));
        Navigator.pop(context, true); // Kembali & refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah Pegawai')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Preview foto
              GestureDetector(
                onTap: _showPicker,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null ? Icon(Icons.add_a_photo, size: 30, color: Colors.teal) : null,
                ),
              ),
              SizedBox(height: 20),
              TextFormField(controller: _namaCtrl, decoration: InputDecoration(labelText: 'Nama', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Harus diisi' : null),
              SizedBox(height: 12),
              TextFormField(controller: _posisiCtrl, decoration: InputDecoration(labelText: 'Posisi', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Harus diisi' : null),
              SizedBox(height: 12),
              TextFormField(controller: _gajiCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Gaji', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Harus diisi' : null),
              SizedBox(height: 12),
              TextFormField(controller: _alamatCtrl, maxLines: 3, decoration: InputDecoration(labelText: 'Alamat', border: OutlineInputBorder())),
              SizedBox(height: 20),
              // Tampilkan status lokasi
              _isLoadingLocation
                  ? LinearProgressIndicator()
                  : Row(
                children: [
                  Icon(Icons.location_on, color: Colors.teal),
                  SizedBox(width: 8),
                  Text(lat != null ? 'Lokasi terdeteksi' : 'Lokasi tidak tersedia'),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: Icon(Icons.save),
                  label: Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
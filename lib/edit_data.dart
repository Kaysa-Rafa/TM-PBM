import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class EditDataPage extends StatefulWidget {
  final Map<String, dynamic> pegawai;

  const EditDataPage({Key? key, required this.pegawai}) : super(key: key);

  @override
  _EditDataPageState createState() => _EditDataPageState();
}

class _EditDataPageState extends State<EditDataPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaCtrl;
  late TextEditingController _posisiCtrl;
  late TextEditingController _gajiCtrl;
  late TextEditingController _alamatCtrl;
  File? _imageFile;
  double? lat, lng;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;

  // Ganti IP ini
  final String baseUrl = 'http://192.168.x.x/crud_pegawai/';
  final String uploadsUrl = 'http://192.168.x.x/crud_pegawai/uploads/';

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data lama
    final p = widget.pegawai;
    _namaCtrl = TextEditingController(text: p['nama']);
    _posisiCtrl = TextEditingController(text: p['posisi']);
    _gajiCtrl = TextEditingController(text: p['gaji'].toString());
    _alamatCtrl = TextEditingController(text: p['alamat']);
    // Ambil GPS saat ini (overwrite koordinat lama)
    _getCurrentLocation();
  }

  // ---------- PERMISSION & GPS ----------
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Izin lokasi diperlukan')));
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buka pengaturan untuk mengizinkan lokasi')));
        setState(() => _isLoadingLocation = false);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      print('Error getting location: $e');
    }
    setState(() => _isLoadingLocation = false);
  }

  // ---------- AMBIL FOTO BARU (KAMERA/GALERI) ----------
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

  // ---------- KIRIM DATA EDIT DENGAN MULTIPART ----------
  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoadingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Menunggu lokasi...')));
      return;
    }
    setState(() => _isSubmitting = true);

    var uri = Uri.parse('${baseUrl}update.php');
    var request = http.MultipartRequest('POST', uri);

    // Field teks
    request.fields['id'] = widget.pegawai['id'].toString();
    request.fields['nama'] = _namaCtrl.text;
    request.fields['posisi'] = _posisiCtrl.text;
    request.fields['gaji'] = _gajiCtrl.text;
    request.fields['alamat'] = _alamatCtrl.text;
    request.fields['latitude'] = lat?.toString() ?? '';
    request.fields['longitude'] = lng?.toString() ?? '';

    // Kirim foto baru hanya jika user memilih gambar baru
    if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', _imageFile!.path),
      );
    }
    // Jika tidak ada foto baru, backend akan mempertahankan foto lama (sesuaikan logika backend)

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil diubah')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengupdate data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final oldFoto = widget.pegawai['foto'];
    final oldImageUrl = (oldFoto != null && oldFoto.toString().isNotEmpty) ? '$uploadsUrl$oldFoto' : null;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Pegawai')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Tampilkan foto lama atau foto baru yang dipilih
              GestureDetector(
                onTap: _showPicker,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (oldImageUrl != null ? NetworkImage(oldImageUrl) as ImageProvider : null),
                  child: (_imageFile == null && oldImageUrl == null)
                      ? Icon(Icons.add_a_photo, size: 30, color: Colors.teal)
                      : null,
                ),
              ),
              SizedBox(height: 8),
              TextButton(onPressed: _showPicker, child: Text('Ganti Foto')),
              SizedBox(height: 20),
              TextFormField(controller: _namaCtrl, decoration: InputDecoration(labelText: 'Nama', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Harus diisi' : null),
              SizedBox(height: 12),
              TextFormField(controller: _posisiCtrl, decoration: InputDecoration(labelText: 'Posisi', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Harus diisi' : null),
              SizedBox(height: 12),
              TextFormField(controller: _gajiCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Gaji', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Harus diisi' : null),
              SizedBox(height: 12),
              TextFormField(controller: _alamatCtrl, maxLines: 3, decoration: InputDecoration(labelText: 'Alamat', border: OutlineInputBorder())),
              SizedBox(height: 20),
              _isLoadingLocation
                  ? LinearProgressIndicator()
                  : Row(
                children: [
                  Icon(Icons.location_on, color: Colors.teal),
                  SizedBox(width: 8),
                  Text(lat != null ? 'Lokasi diperbarui' : 'Lokasi tidak tersedia'),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  icon: Icon(Icons.save),
                  label: Text('Update'),
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
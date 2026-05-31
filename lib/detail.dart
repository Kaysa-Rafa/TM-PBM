import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_data.dart';

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> pegawai;

  const DetailPage({Key? key, required this.pegawai}) : super(key: key);

  // Ganti IP ini
  final String baseUrl = 'http://192.168.x.x/crud_pegawai/';

  Future<void> _deleteData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Yakin hapus data ${pegawai['nama']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus'),
            style: ElevatedButton.styleFrom(primary: Colors.red),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await http.delete(Uri.parse('${baseUrl}delete.php?id=${pegawai['id']}'));
      Navigator.pop(context, true); // Kembali dan beri sinyal refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = '${baseUrl}uploads/${pegawai['foto']}'; // Sesuaikan folder upload
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pegawai'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteData(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: pegawai['foto'] != null && pegawai['foto'].toString().isNotEmpty
                    ? Image.network(fotoUrl, width: 160, height: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, size: 160))
                    : Icon(Icons.person, size: 160),
              ),
            ),
            SizedBox(height: 24),
            _infoCard('Nama', pegawai['nama'] ?? '-'),
            _infoCard('Posisi', pegawai['posisi'] ?? '-'),
            _infoCard('Gaji', 'Rp ${pegawai['gaji'] ?? 0}'),
            _infoCard('Alamat', pegawai['alamat'] ?? '-'),
            _infoCard('Latitude', pegawai['latitude']?.toString() ?? '-'),
            _infoCard('Longitude', pegawai['longitude']?.toString() ?? '-'),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditDataPage(pegawai: pegawai)),
                  );
                  if (result == true) Navigator.pop(context, true); // Refresh list
                },
                icon: Icon(Icons.edit),
                label: Text('Edit Data'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
            Expanded(flex: 3, child: Text(value)),
          ],
        ),
      ),
    );
  }
}
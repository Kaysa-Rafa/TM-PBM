import 'dart:io';
import 'package:flutter/material.dart';
import 'model_pegawai.dart';

class DetailPegawai extends StatelessWidget {
  final Pegawai pegawai;
  const DetailPegawai({super.key, required this.pegawai});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pegawai'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 70,
                backgroundImage:
                    pegawai.foto.isNotEmpty ? FileImage(File(pegawai.foto)) : null,
                child: pegawai.foto.isEmpty
                    ? Text(pegawai.nama[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40))
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfo(Icons.person, 'Nama', pegawai.nama),
            _buildInfo(Icons.work, 'Posisi', pegawai.posisi),
            _buildInfo(Icons.attach_money, 'Gaji', 'Rp ${pegawai.gaji}'),
            _buildInfo(Icons.home, 'Alamat', pegawai.alamat),
            _buildInfo(Icons.location_on, 'Lokasi',
                '${pegawai.latitude}, ${pegawai.longitude}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
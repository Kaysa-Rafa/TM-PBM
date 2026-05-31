class Pegawai {
  int? id;
  String nama;
  String posisi;
  int gaji;
  String foto;
  double latitude;
  double longitude;
  String alamat;

  Pegawai({
    this.id,
    required this.nama,
    required this.posisi,
    required this.gaji,
    this.foto = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.alamat = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'posisi': posisi,
      'gaji': gaji,
      'foto': foto,
      'latitude': latitude,
      'longitude': longitude,
      'alamat': alamat,
    };
  }

  factory Pegawai.fromMap(Map<String, dynamic> map) {
    return Pegawai(
      id: map['id'],
      nama: map['nama'],
      posisi: map['posisi'],
      gaji: map['gaji'],
      foto: map['foto'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      alamat: map['alamat'] ?? '',
    );
  }
}
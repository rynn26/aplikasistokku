class Pegawai {
  final int id;
  final String nama;
  final String? jenisKelamin;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? alamat;
  final String? noHp;
  final String? email;
  final String? jabatan;
  final String? tanggalMasuk;
  final double gaji;
  final String status;
  final String? catatan;
  final String? foto;
  final String? createdAt;

  const Pegawai({
    required this.id,
    required this.nama,
    this.jenisKelamin,
    this.tempatLahir,
    this.tanggalLahir,
    this.alamat,
    this.noHp,
    this.email,
    this.jabatan,
    this.tanggalMasuk,
    this.gaji = 0,
    this.status = 'aktif',
    this.catatan,
    this.foto,
    this.createdAt,
  });

  factory Pegawai.fromJson(Map<String, dynamic> json) => Pegawai(
        id:            json['id'] ?? 0,
        nama:          json['nama'] ?? '',
        jenisKelamin:  json['jenis_kelamin'],
        tempatLahir:   json['tempat_lahir'],
        tanggalLahir:  json['tanggal_lahir'],
        alamat:        json['alamat'],
        noHp:          json['no_hp'],
        email:         json['email'],
        jabatan:       json['jabatan'],
        tanggalMasuk:  json['tanggal_masuk'],
        gaji:          (json['gaji'] as num?)?.toDouble() ?? 0,
        status:        json['status'] ?? 'aktif',
        catatan:       json['catatan'],
        foto:          json['foto'],
        createdAt:     json['created_at'],
      );

  bool get isAktif => status == 'aktif';
  String get jenisKelaminLabel => jenisKelamin == 'L' ? 'Laki-laki' : jenisKelamin == 'P' ? 'Perempuan' : '-';
}

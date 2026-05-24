/// Model untuk tabel `ingredient_histories`
/// Mencatat semua perubahan stok bahan baku: masuk, keluar, atau penyesuaian
class IngredientHistory {
  final int id;
  final int ingredientId;
  final int? userId;
  final String? userName;
  final String? role;
  final String tipe; // 'masuk' | 'keluar' | 'penyesuaian'
  final double qty;
  final double stokSebelum;
  final double stokSesudah;
  final String? referensiTipe; // 'manufaktur' | 'koreksi' | 'manual'
  final int? referensiId;
  final String? catatan;
  final String? createdAt;

  IngredientHistory({
    required this.id,
    required this.ingredientId,
    this.userId,
    this.userName,
    this.role,
    required this.tipe,
    required this.qty,
    required this.stokSebelum,
    required this.stokSesudah,
    this.referensiTipe,
    this.referensiId,
    this.catatan,
    this.createdAt,
  });

  factory IngredientHistory.fromJson(Map<String, dynamic> json) {
    return IngredientHistory(
      id: json['id'] ?? 0,
      ingredientId: json['ingredient_id'] ?? 0,
      userId: json['user_id'],
      userName: json['user_name'],
      role: json['role'],
      tipe: json['tipe'] ?? 'masuk',
      qty: double.tryParse('${json['qty']}') ?? 0,
      stokSebelum: double.tryParse('${json['stok_sebelum']}') ?? 0,
      stokSesudah: double.tryParse('${json['stok_sesudah']}') ?? 0,
      referensiTipe: json['referensi_tipe'],
      referensiId: json['referensi_id'],
      catatan: json['catatan'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'ingredient_id': ingredientId,
    'tipe': tipe,
    'qty': qty,
    'stok_sebelum': stokSebelum,
    'stok_sesudah': stokSesudah,
    'referensi_tipe': referensiTipe,
    'referensi_id': referensiId,
    'catatan': catatan,
  };

  /// Warna badge berdasarkan tipe
  /// 'masuk' → hijau, 'keluar' → merah, 'penyesuaian' → biru
  String get tipeLabel {
    switch (tipe) {
      case 'masuk': return 'Masuk';
      case 'keluar': return 'Keluar';
      case 'penyesuaian': return 'Penyesuaian';
      default: return tipe;
    }
  }
}

class AnalysisResult {
  final String duygu;
  final String niyet;
  final String ton;
  final int ciddiyet;
  final String mesajYorumu;
  final List<String> tavsiyeler;

  AnalysisResult({
    required this.duygu,
    required this.niyet,
    required this.ton,
    required this.ciddiyet,
    required this.mesajYorumu,
    required this.tavsiyeler,
  });

  Map<String, dynamic> toMap() {
    return {
      'duygu': duygu,
      'niyet': niyet,
      'ton': ton,
      'ciddiyet': ciddiyet,
      'mesajYorumu': mesajYorumu,
      'tavsiyeler': tavsiyeler,
    };
  }

  factory AnalysisResult.fromMap(Map<String, dynamic> map) {
    return AnalysisResult(
      duygu: map['duygu'] ?? '',
      niyet: map['niyet'] ?? 'Belirlenemedi',
      ton: map['ton'] ?? '',
      ciddiyet: map['ciddiyet'] ?? 5,
      mesajYorumu: map['mesaj_yorumu'] ?? map['mesajYorumu'] ?? '',
      tavsiyeler: List<String>.from(map['tavsiyeler'] ?? map['cevapOnerileri'] ?? []),
    );
  }

  @override
  String toString() {
    return 'AnalysisResult(duygu: $duygu, niyet: $niyet, ton: $ton, ciddiyet: $ciddiyet)';
  }
} 
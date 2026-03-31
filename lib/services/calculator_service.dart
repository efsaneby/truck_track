class CalculatorService {
  // --- CAO 2026 TABLOLARI (MEERDAAGSE - ÇOK GÜNLÜK SEFERLER İÇİN) ---
  // Bu tablolar Meerdaagse kuralındaki (1.65 / 3.77 / 5.89) hesaplamaların maktu sonuçlarıdır.
  static const Map<int, double> ilkGunTablo = {
    0: 54.44,
    1: 52.79,
    2: 51.14,
    3: 49.49,
    4: 47.84,
    5: 46.19,
    6: 44.54,
    7: 42.89,
    8: 41.24,
    9: 39.59,
    10: 37.94,
    11: 36.29,
    12: 34.64,
    13: 32.99,
    14: 31.34,
    15: 29.69,
    16: 28.04,
    17: 11.55,
    18: 9.90,
    19: 8.25,
    20: 6.60,
    21: 4.95,
    22: 3.30,
    23: 1.65,
  };

  static const Map<int, double> sonGunTablo = {
    0: 0.0,
    1: 1.65,
    2: 3.30,
    3: 4.95,
    4: 6.60,
    5: 8.25,
    6: 9.90,
    7: 11.55,
    8: 13.20,
    9: 14.85,
    10: 16.50,
    11: 18.15,
    12: 19.80,
    13: 34.17,
    14: 35.82,
    15: 37.47,
    16: 39.12,
    17: 40.77,
    18: 42.42,
    19: 46.19,
    20: 49.96,
    21: 53.73,
    22: 57.50,
    23: 61.27,
    24: 65.04,
  };

  // --- UI ANLIK HESAPLAMA (SAYAC İÇİN) ---
  static double anlikSaniyelikKazancGetir({
    required bool isWork,
    required int gecenSaniye,
  }) {
    return isWork ? (13.0 / 3600.0) : (40.0 / 86400.0);
  }

  // --- 1. SENARYO: TEK GÜNLÜK (EENDAAGSE) HESAPLAYICI ---
  static double tekGunlukHarcirahHesapla(int basSaat, int bitSaat) {
    DateTime simdi = DateTime.now();
    DateTime bas = DateTime(simdi.year, simdi.month, simdi.day, basSaat, 0);
    DateTime bit = DateTime(simdi.year, simdi.month, simdi.day, bitSaat, 0);

    // Gece yarısı geçişi kontrolü
    if (bit.isBefore(bas)) bit = bit.add(const Duration(days: 1));

    int toplamDakika = bit.difference(bas).inMinutes;

    // KURAL: 4 saat ve altı ise ödeme yok
    if (toplamDakika <= 240) return 0.0;

    // KURAL: 14:00 sonrası çıkış ve 12 saat üzeri sefer (Fix bedel: 15.73)
    if (bas.hour > 14 && toplamDakika >= 720) {
      return 15.73;
    }

    double toplamEuro = 0.0;
    DateTime kontrolAnu = bas;

    // Dakika bazlı hassas hesaplama
    while (kontrolAnu.isBefore(bit)) {
      if (kontrolAnu.day == bas.day) {
        bool isEvening = kontrolAnu.hour >= 18 && kontrolAnu.hour < 24;
        bool isEarlyDeparture = bas.hour <= 14;

        if (isEvening && isEarlyDeparture) {
          toplamEuro += (3.77 / 60.0); // Zamlı tarife
        } else {
          toplamEuro += (0.83 / 60.0); // Standart tarife
        }
      } else {
        // Gece yarısından sonrası (Tek günlük sefer sarktıysa)
        toplamEuro += (0.83 / 60.0);
      }
      kontrolAnu = kontrolAnu.add(const Duration(minutes: 1));
    }

    return double.parse(toplamEuro.toStringAsFixed(2));
  }

  // --- 2. SENARYO: ÇOK GÜNLÜK (MEERDAAGSE) HESAPLAYICI ---
  // Ana Motor: Hem Tek Gün hem Çok Günü yönetir
  static double hesaplaHarcirah2026({
    required int baslangicSaat,
    required int bitisSaat,
    int tamGun = 0,
    bool konaklamaVarMi = false,
  }) {
    // Eğer aynı gün gidip gelindiyse (Konaklama yoksa)
    if (!konaklamaVarMi && tamGun == 0) {
      return tekGunlukHarcirahHesapla(baslangicSaat, bitisSaat);
    }

    // Eğer sefer konaklamalıysa (Meerdaagse)
    double toplam = 0.0;

    // İlk Gün (Çıkış saatine göre hazır maktu değer)
    toplam += ilkGunTablo[baslangicSaat] ?? 0.0;

    // Ara Günler (24 saat dışarıda olunan her tam gün için 65.04€)
    toplam += tamGun * 65.04;

    // Son Gün (Dönüş saatine göre hazır maktu değer)
    toplam += sonGunTablo[bitisSaat] ?? 0.0;

    return double.parse(toplam.toStringAsFixed(2));
  }

  // Direksiyon (Sürüş) saatlik ücreti
  static double direksiyonHesapla(double saat) => saat * 13.0;
}

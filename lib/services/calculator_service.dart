import 'package:truck_track/models/app_data.dart';

class CalculatorService {
  static double maasHesapla(double calisilanSaat, double saatlikUcret) {
    double toplam = calisilanSaat * saatlikUcret;
    return toplam; // Sonucu dışarı gönder
  }

  static double harcirahHesaplaGercekci({
    required int tamGunSayisi,
    required bool haftaSonuMu,
    required bool aksamYemegiDahilMi,
  }) {
    double gunlukStandart = 53.0; // Örnek CAO rakamı
    double haftaSonuPrimi = 22.0; // Hafta sonu ekstrası
    double yemekKesintisi = AppData.gunlukYemekBedeli; // Eğer yemek şirkettentse kesinti

    double toplam = tamGunSayisi * gunlukStandart;

    if (haftaSonuMu) toplam += haftaSonuPrimi;
    if (aksamYemegiDahilMi) toplam -= yemekKesintisi;

    return toplam;
  }

  static double fazlaMesaiHesapla(double toplamSaat, double saatlikUcret) {
    double normalBaraj = 174.0;
    double fazlaMesaiCarpani = 1.30; // %130

    if (toplamSaat <= normalBaraj) {
      return toplamSaat * saatlikUcret;
    } else {
      double normalKazanc = normalBaraj * saatlikUcret;
      double fazlaMesaiSaati = toplamSaat - normalBaraj;
      double fazlaMesaiKazanci =
          fazlaMesaiSaati * (saatlikUcret * fazlaMesaiCarpani);

      return normalKazanc + fazlaMesaiKazanci;
    }
  }

  static double geceZammiHesapla(double geceSaati, double saatlikUcret) {
    double geceCarpani = 0.19; // %19 ek ödeme oranı
    // Formül: Gece Saati * (Saatlik Ücret * 0.19)
    return geceSaati * (saatlikUcret * geceCarpani);
  }
}

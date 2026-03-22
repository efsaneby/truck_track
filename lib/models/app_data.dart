import 'salary_model.dart';

class AppData {
  // Tüm basamakların listesi (Kitapçığımız)
  static List<SalaryStep> maasTablosu = [
    SalaryStep(basamakAdi: "D0", saatlikUcret: 15.10),
    SalaryStep(basamakAdi: "D1", saatlikUcret: 15.40),
    SalaryStep(basamakAdi: "D6", saatlikUcret: 16.50),
    SalaryStep(basamakAdi: "E0", saatlikUcret: 17.20),
    SalaryStep(basamakAdi: "E1", saatlikUcret: 17.85),
  ];

  // Varsayılan seçim (İleride bunu veritabanından okuyacağız)
  static SalaryStep varsayilanBasamak = maasTablosu[2]; // Yani D6

  static double gunlukYemekBedeli = 12.50;
}

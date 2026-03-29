import 'salary_model.dart';

class AppData {
  // 1 Ocak 2026 TLN/VNB Resmi Maaş Tablosu [cite: 2]
  static List<SalaryStep> maasTablosu = <SalaryStep>[
    // --- A Grubu ---
    SalaryStep(basamakAdi: "A1", saatlikUcret: 14.71),
    SalaryStep(basamakAdi: "A2", saatlikUcret: 14.80),
    SalaryStep(basamakAdi: "A3", saatlikUcret: 15.39),
    SalaryStep(basamakAdi: "A4", saatlikUcret: 16.00),
    SalaryStep(basamakAdi: "A5", saatlikUcret: 16.64),
    SalaryStep(basamakAdi: "A6", saatlikUcret: 17.31),

    // --- B Grubu ---
    SalaryStep(basamakAdi: "B1", saatlikUcret: 14.98),
    SalaryStep(basamakAdi: "B2", saatlikUcret: 15.58),
    SalaryStep(basamakAdi: "B3", saatlikUcret: 16.20),
    SalaryStep(basamakAdi: "B4", saatlikUcret: 16.85),
    SalaryStep(basamakAdi: "B5", saatlikUcret: 17.52),
    SalaryStep(basamakAdi: "B6", saatlikUcret: 18.22),

    // --- C Grubu ---
    SalaryStep(basamakAdi: "C1", saatlikUcret: 15.63),
    SalaryStep(basamakAdi: "C2", saatlikUcret: 16.25),
    SalaryStep(basamakAdi: "C3", saatlikUcret: 16.90),
    SalaryStep(basamakAdi: "C4", saatlikUcret: 17.58),
    SalaryStep(basamakAdi: "C5", saatlikUcret: 18.28),
    SalaryStep(basamakAdi: "C6", saatlikUcret: 19.01),

    // --- D Grubu ---
    SalaryStep(basamakAdi: "D1", saatlikUcret: 16.64),
    SalaryStep(basamakAdi: "D2", saatlikUcret: 17.30),
    SalaryStep(basamakAdi: "D3", saatlikUcret: 17.99),
    SalaryStep(basamakAdi: "D4", saatlikUcret: 18.71),
    SalaryStep(basamakAdi: "D5", saatlikUcret: 19.46),
    SalaryStep(basamakAdi: "D6", saatlikUcret: 20.24),

    // --- E Grubu ---
    SalaryStep(basamakAdi: "E1", saatlikUcret: 17.45),
    SalaryStep(basamakAdi: "E6", saatlikUcret: 21.23),
    SalaryStep(basamakAdi: "E7", saatlikUcret: 22.08),

    // --- F Grubu ---
    SalaryStep(basamakAdi: "F1", saatlikUcret: 18.24),
    SalaryStep(basamakAdi: "F8", saatlikUcret: 24.00),

    // --- G & H Grubu (Yönetici/Özel) ---
    SalaryStep(basamakAdi: "G9", saatlikUcret: 26.37),
    SalaryStep(basamakAdi: "H10", saatlikUcret: 28.89),
  ];

  // Seçili Basamak: Listeden istediğini index ile seçebilirsin.
  // D6 basamağı listenin 23. elemanı (0'dan başladığı için index: 23)
  static SalaryStep varsayilanBasamak = maasTablosu[23];

  // --- VNB TOESLAGEN (EK ÖDEME) ORANLARI ---
  static const double fazlaMesai130 = 1.30;
  static const double cumartesiFarki = 1.50;
  static const double pazarFarki = 2.00;
  static const double geceZammiOrani = 1.19;

  // --- HARCIRAH VE BEKLEME ---
  static const double gunlukHarcirah = 45.00;
  static const double overstaanNet = 15.73;
  static const double overstaanBrut = 28.20;
}

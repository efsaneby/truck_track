import 'package:flutter/material.dart';

void main() {
  runApp(const TruckTrackApp());
}

class TruckTrackApp extends StatefulWidget {
  const TruckTrackApp({super.key});

  @override
  State<TruckTrackApp> createState() => _TruckTrackAppState();
}

class _TruckTrackAppState extends State<TruckTrackApp> {
  bool isWorkActive = false; // Mesai şu an açık mı?
  bool isStayActive = false; // Konaklama şu an açık mı?
  String statusMessage = "Henüz iş başı yapılmadı";
  String stayMessage = "Konaklama kapali";

  List<SalaryStep> maasTablosu = [
    SalaryStep(basamakAdi: "D0", saatlikUcret: 15.10),
    SalaryStep(basamakAdi: "D6", saatlikUcret: 16.50),
    SalaryStep(basamakAdi: "E0", saatlikUcret: 17.20),
  ];

  SalaryStep seciliBasamak = SalaryStep(basamakAdi: "D6", saatlikUcret: 16.50);

  double maasHesapla(double calisilanSaat, double saatlikUcret) {
    double toplam = calisilanSaat * saatlikUcret;
    return toplam; // Sonucu dışarı gönder
  }

  double harcirahHesapla(double konaklamaGunu, double gunlukHarcirah) {
    double toplam = konaklamaGunu * gunlukHarcirah;
    return toplam; // Sonucu dışarı gönder
  }

  double fazlaMesaiHesapla(double toplamSaat, double saatlikUcret) {
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

  double geceZammiHesapla(double geceSaati, double saatlikUcret) {
    double geceCarpani = 0.19; // %19 ek ödeme oranı
    // Formül: Gece Saati * (Saatlik Ücret * 0.19)
    return geceSaati * (saatlikUcret * geceCarpani);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "TruckTrack Dashboard",
            style: TextStyle(
              color: Colors.black87, // Yazıyı koyu yapalım
              fontWeight: FontWeight.w900, // Daha kalın, tok bir yazı
              letterSpacing:
                  1.2, // Harflerin arasını biraz açalım (modern durur)
            ),
          ),
          centerTitle: true, // Başlığı ortaya alalım
          backgroundColor: Colors.white, // Arka planı bembeyaz yapalım
          elevation: 0, // AppBar'ın altındaki o çirkin gölgeyi kaldıralım
        ),
        body: Column(
          children: [
            // TURUNCU KUTU (MESAI)
            InkWell(
              onTap: () {
                setState(() {
                  isWorkActive = !isWorkActive;
                  double aylikToplam = 190;
                  double geceMesaisi = 10;
                  double anaKazanc = fazlaMesaiHesapla(
                    aylikToplam,
                    seciliBasamak.saatlikUcret,
                  );
                  double geceKazanci = geceZammiHesapla(
                    geceMesaisi,
                    seciliBasamak.saatlikUcret,
                  );
                  double toplamKazanc = anaKazanc + geceKazanci;
                  statusMessage = isWorkActive
                      ? "Mesai Basladi. (Tahmini kazanc: €${toplamKazanc.toStringAsFixed(2)})"
                      : "Mesai Durduruldu";
                });
              },
              child: Container(
                margin: const EdgeInsets.all(20),
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isWorkActive ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    statusMessage,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // MAVI KUTU (KONAKLAMA)
            InkWell(
              onTap: () {
                setState(() {
                  isStayActive = !isStayActive;
                  double gunlukStandart = 40.0;
                  double toplamHarcirah = harcirahHesapla(1, gunlukStandart);
                  if (isStayActive) {
                    stayMessage =
                        "KONAKLAMA AÇIK! (Harcırah: $toplamHarcirah €)";
                  } else {
                    stayMessage = "Konaklama Durduruldu.";
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isStayActive
                      ? Colors.green
                      : Colors
                            .blue[900], // Aktifse daha canlı bir mavi, değilse koyu mavi
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    stayMessage,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Şoför Maaş Basamakları Modeli
class SalaryStep {
  final String basamakAdi; // Örn: "D6"
  final double saatlikUcret; // Örn: 16.20

  SalaryStep({required this.basamakAdi, required this.saatlikUcret});
}

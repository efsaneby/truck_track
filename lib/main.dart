import 'package:flutter/material.dart';
import 'package:truck_track/models/app_data.dart';
import 'package:truck_track/models/salary_model.dart';
import 'package:truck_track/services/calculator_service.dart';

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
                  double anaKazanc = CalculatorService.fazlaMesaiHesapla(
                    aylikToplam,
                    AppData.varsayilanBasamak.saatlikUcret,
                  );
                  double geceKazanci = CalculatorService.geceZammiHesapla(
                    geceMesaisi,
                    AppData.varsayilanBasamak.saatlikUcret,
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
                  int toplamGun = 4;
                  bool pazarGunuMu = true;
                  bool aksamYemegiDahilMi = true;
                  double netHarcirah =
                      CalculatorService.harcirahHesaplaGercekci(
                        tamGunSayisi: toplamGun,
                        haftaSonuMu: pazarGunuMu,
                        aksamYemegiDahilMi: aksamYemegiDahilMi,
                      );
                  if (isStayActive) {
                    stayMessage =
                        "KONAKLAMA AÇIK! (Harcırah: €${netHarcirah.toStringAsFixed(2)})";
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

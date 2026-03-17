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
                  // setState: "Flutter, bak bir şeyler değişti, ekranı tazele!" demek.
                  isWorkActive =
                      !isWorkActive; // true ise false yap, false ise true yap.
                  statusMessage = isWorkActive
                      ? "Mesai Devam Ediyor..."
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
                  isStayActive = !isStayActive; // Durumu tersine çevir
                  // İŞTE BURASI IF-ELSE MANTIĞI:
                  if (isStayActive == true) {
                    print("Harcırah sayacı başladı.");
                  } else {
                    print("Harcırah sayacı durduruldu.");
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
                    isStayActive ? "KONAKLAMA AÇIK" : "KONAKLAMA KAPALI",
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

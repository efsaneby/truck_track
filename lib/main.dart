import 'package:flutter/material.dart';
import 'package:truck_track/models/app_data.dart';
import 'package:truck_track/services/calculator_service.dart';
import 'package:truck_track/services/db_helper.dart';

void main() {
  runApp(const TruckTrackApp());
}

class TruckTrackApp extends StatefulWidget {
  const TruckTrackApp({super.key});

  @override
  State<TruckTrackApp> createState() => _TruckTrackAppState();
}

class _TruckTrackAppState extends State<TruckTrackApp> {
  bool isWorkActive = false;
  bool isStayActive = false;
  String statusMessage = "Henüz iş başı yapılmadı";
  String stayMessage = "Konaklama kapalı";
  List<Map<String, dynamic>> tumKayitlar = [];

  @override
  void initState() {
    super.initState();
    listeyiGuncelle(); // Uygulama açılır açılmaz defteri oku
  }

  // Defterdeki her şeyi tazeleyip ekrana basan fonksiyon
  Future<void> listeyiGuncelle() async {
    final veriler = await DbHelper.instance.tumMesaileriGetir();
    setState(() {
      tumKayitlar = veriler;
    });
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
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // TURUNCU KUTU (MESAI)
            InkWell(
              onTap: () async {
                // Önce hesaplamaları yapalım
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

                setState(() {
                  isWorkActive = !isWorkActive;
                  statusMessage = isWorkActive
                      ? "Mesai Başladı. (Tahmini: €${toplamKazanc.toStringAsFixed(2)})"
                      : "Mesai Durduruldu";
                });

                // Eğer mesai başlatıldıysa deftere yazalım
                if (isWorkActive) {
                  Map<String, dynamic> yeniKayit = {
                    'tarih': DateTime.now().toString(),
                    'toplamSaat': aylikToplam,
                    'geceSaati': geceMesaisi,
                    'konaklamaGun': 0,
                    'kazanc': double.parse(toplamKazanc.toStringAsFixed(2)),
                  };

                  await DbHelper.instance.mesaiKaydet(yeniKayit);
                  print("✅ Mesai Deftere Kaydedildi!");
                  listeyiGuncelle(); // Listeyi anında tazele
                }
              },
              child: Container(
                margin: const EdgeInsets.all(20),
                height: 120, // Biraz daralttım liste daha iyi görünsün diye
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isWorkActive ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
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
                  double netHarcirah =
                      CalculatorService.harcirahHesaplaGercekci(
                        tamGunSayisi: 4,
                        haftaSonuMu: true,
                        aksamYemegiDahilMi: true,
                      );
                  stayMessage = isStayActive
                      ? "KONAKLAMA AÇIK! (€${netHarcirah.toStringAsFixed(2)})"
                      : "Konaklama Durduruldu.";
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isStayActive ? Colors.green : Colors.blue[900],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    stayMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Son Kayıtlar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // LİSTE GÖRÜNÜMÜ
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: tumKayitlar.length,
                itemBuilder: (context, index) {
                  final kayit = tumKayitlar[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.history, color: Colors.orange),
                      title: Text(
                        "Tarih: ${kayit['tarih'].toString().substring(0, 10)}",
                      ),
                      subtitle: Text(
                        "Saat: ${kayit['toplamSaat']} | Gece: ${kayit['geceSaati']}",
                      ),
                      trailing: Text(
                        "€${kayit['kazanc']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

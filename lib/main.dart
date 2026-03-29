import 'package:flutter/material.dart';
import 'package:truck_track/models/app_data.dart';
import 'package:truck_track/services/calculator_service.dart';
import 'package:truck_track/services/db_helper.dart';
import 'dart:async';

void main() {
  runApp(const TruckTrackApp());
}

class TruckTrackApp extends StatefulWidget {
  const TruckTrackApp({super.key});

  @override
  State<TruckTrackApp> createState() => _TruckTrackAppState();
}

class _TruckTrackAppState extends State<TruckTrackApp> {
  // DURUM DEĞİŞKENLERİ
  bool isWorkActive = false;
  bool isStayActive = false;
  List<Map<String, dynamic>> tumKayitlar = [];

  // CANLI SAYAÇLAR
  Timer? _workTimer;
  Timer? _stayTimer;
  double _anlikWorkKazanc = 0.0;
  double _anlikStayKazanc = 0.0;

  // AY ÖZETİ
  double aylikToplamEuro = 0.0;
  double aylikToplamSaat = 0.0;

  @override
  void initState() {
    super.initState();
    listeyiGuncelle();
  }

  // VERİTABANINDAN ÖZETLERİ ÇEKER
  Future<void> listeyiGuncelle() async {
    final veriler = await DbHelper.instance.tumMesaileriGetir();
    double euroSayaci = 0.0;
    double saatSayaci = 0.0;

    for (var kayit in veriler) {
      euroSayaci += (kayit['kazanc'] ?? 0.0);
      saatSayaci += (kayit['toplamSaat'] ?? 0.0);
    }

    setState(() {
      tumKayitlar = veriler;
      aylikToplamEuro = euroSayaci;
      aylikToplamSaat = saatSayaci;
    });
  }

  // MESAİ SAYACI BAŞLAT/DURDUR
  void _toggleWork() {
    setState(() {
      isWorkActive = !isWorkActive;
      if (isWorkActive) {
        _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            double saniyelikUcret =
                AppData.varsayilanBasamak.saatlikUcret / 3600;
            _anlikWorkKazanc += saniyelikUcret;
          });
        });
      } else {
        _workTimer?.cancel();
        _kaydetVeSifirla(true);
      }
    });
  }

  // KONAKLAMA SAYACI BAŞLAT/DURDUR
  void _toggleStay() {
    setState(() {
      isStayActive = !isStayActive;
      if (isStayActive) {
        _stayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            // Harcırah saniyelik hesap (Örn: Günlük 45€ / 24s / 3600sn)
            double saniyelikHarcirah = 45.0 / (24 * 3600);
            _anlikStayKazanc += saniyelikHarcirah;
          });
        });
      } else {
        _stayTimer?.cancel();
        _kaydetVeSifirla(false);
      }
    });
  }

  // VERİTABANINA KAYIT VE EKRANI TEMİZLEME
  Future<void> _kaydetVeSifirla(bool isWork) async {
    Map<String, dynamic> yeniKayit = {
      'tarih': DateTime.now().toString(),
      'toplamSaat': isWork
          ? 8.0
          : 0.0, // Şimdilik elle, ileride süreye bağlanacak
      'geceSaati': 0.0,
      'konaklamaGun': isWork ? 0 : 1,
      'kazanc': double.parse(
        (isWork ? _anlikWorkKazanc : _anlikStayKazanc).toStringAsFixed(2),
      ),
    };

    await DbHelper.instance.mesaiKaydet(yeniKayit);
    setState(() {
      if (isWork)
        _anlikWorkKazanc = 0.0;
      else
        _anlikStayKazanc = 0.0;
    });
    listeyiGuncelle();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            "TruckTrack Pro",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildAyOzetiKart(),
            _buildAnaButon(
              baslik: "DİREKSİYON MESAİSİ",
              deger: _anlikWorkKazanc,
              aktifMi: isWorkActive,
              renk: Colors.orange,
              onTap: _toggleWork,
            ),
            _buildAnaButon(
              baslik: "TIRDA KONAKLAMA",
              deger: _anlikStayKazanc,
              aktifMi: isStayActive,
              renk: Colors.blue[800]!,
              onTap: _toggleStay,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Son Kayıtlar",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildKayitListesi()),
          ],
        ),
      ),
    );
  }

  // --- ŞIK TASARIM PARÇALARI ---

  Widget _buildAyOzetiKart() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF232526), Color(0xFF414345)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ozetSutun("BU AY TOPLAM", "€${aylikToplamEuro.toStringAsFixed(2)}"),
          Container(width: 1, height: 40, color: Colors.white24),
          _ozetSutun("TOPLAM SAAT", "${aylikToplamSaat.toStringAsFixed(1)} sa"),
        ],
      ),
    );
  }

  Widget _ozetSutun(String baslik, String deger) {
    return Column(
      children: [
        Text(
          baslik,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          deger,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnaButon({
    required String baslik,
    required double deger,
    required bool aktifMi,
    required Color renk,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        height: 110,
        decoration: BoxDecoration(
          color: aktifMi ? Colors.green : renk,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              aktifMi ? "DURDURMAK İÇİN DOKUN" : baslik,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "€${deger.toStringAsFixed(4)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKayitListesi() {
    return ListView.builder(
      itemCount: tumKayitlar.length,
      itemBuilder: (context, index) {
        final kayit = tumKayitlar[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: ListTile(
            leading: Icon(
              kayit['konaklamaGun'] > 0 ? Icons.bed : Icons.local_shipping,
              color: Colors.blueGrey,
            ),
            title: Text(
              kayit['tarih'].toString().substring(0, 10),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              "€${kayit['kazanc']}",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

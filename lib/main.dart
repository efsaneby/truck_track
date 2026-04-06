import 'package:flutter/material.dart';
import 'package:truck_track/services/calculator_service.dart';
import 'package:truck_track/services/db_helper.dart';
import 'dart:async';
import 'package:intl/intl.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: TruckTrackApp()),
  );
}

class TruckTrackApp extends StatefulWidget {
  const TruckTrackApp({super.key});
  @override
  State<TruckTrackApp> createState() => _TruckTrackAppState();
}

class _TruckTrackAppState extends State<TruckTrackApp> {
  bool isWorkActive = false;
  bool isStayActive = false;
  bool isBreakActive = false;

  Map<String, Map<String, dynamic>> gunlukOzetlerMap = {};
  List<DateTime> ayinTumGunleri = [];
  DateTime _seciliAy = DateTime.now();

  Timer? _workTimer;
  Timer? _stayTimer;

  int _workSaniye = 0;
  int _staySaniye = 0;
  int _molaSaniye = 3600; // Standart 60 Dakika

  double _anlikWorkKazanc = 0.0;
  double _anlikStayKazanc = 0.0;
  double aylikToplamEuro = 0.0;
  double aylikToplamSaat = 0.0;

  @override
  void initState() {
    super.initState();
    listeyiGuncelle();
  }

  // --- MANUEL GÜNCELLEME PANELİ ---
  void _guncellemePaneli(
    String gunKey,
    bool isWork,
    double mevcutMiktar,
    double mevcutSaat,
  ) {
    DateTime baslangicTarihi = DateTime.parse(gunKey);
    DateTime bitisTarihi = DateTime.parse(gunKey);

    // Başlangıç Saati (mevcutSaat'ten geliyor)
    int bH = mevcutSaat.toInt();
    int bM = ((mevcutSaat - bH) * 60).round();
    TimeOfDay baslangicSaat = TimeOfDay(hour: bH % 24, minute: bM);

    // Bitiş Saati (mevcutMiktar'dan geliyor)
    int fH = mevcutMiktar.toInt();
    int fM = ((mevcutMiktar - fH) * 60).round();
    TimeOfDay bitisSaat = TimeOfDay(hour: fH % 24, minute: fM);

    int molaDakika = 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setPanelState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$gunKey Düzenle",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Başlangıç Zamanı"),
                  subtitle: Text(
                    "${DateFormat('dd/MM').format(baslangicTarihi)} - ${baslangicSaat.format(context)}",
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: baslangicTarihi,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: baslangicSaat,
                      );
                      if (time != null)
                        setPanelState(() {
                          baslangicTarihi = date;
                          baslangicSaat = time;
                        });
                    }
                  },
                ),
                ListTile(
                  title: const Text("Bitiş Zamanı"),
                  subtitle: Text(
                    "${DateFormat('dd/MM').format(bitisTarihi)} - ${bitisSaat.format(context)}",
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: bitisTarihi,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: bitisSaat,
                      );
                      if (time != null)
                        setPanelState(() {
                          bitisTarihi = date;
                          bitisSaat = time;
                        });
                    }
                  },
                ),
                if (isWork) ...[
                  const SizedBox(height: 10),
                  const Text(
                    "Mola Süresi",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                          size: 32,
                        ),
                        onPressed: () => setPanelState(() {
                          if (molaDakika > 0) molaDakika--;
                        }),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$molaDakika DK",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 32,
                        ),
                        onPressed: () => setPanelState(() => molaDakika++),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _gunuSilOnay(gunKey, isWork);
                      },
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isWork
                              ? Colors.orange
                              : Colors.blue[800],
                          padding: const EdgeInsets.all(15),
                        ),
                        onPressed: () async {
                          final db = await DbHelper.instance.database;
                          await db.delete(
                            'mesailer',
                            where: "tarih LIKE ? AND konaklamaGun = ?",
                            whereArgs: ['$gunKey%', isWork ? 0 : 1],
                          );

                          await _cokluGunKaydet(
                            baslangicTarihi,
                            bitisTarihi,
                            baslangicSaat,
                            bitisSaat,
                            isWork,
                            molaDakika,
                          );
                          if (mounted) Navigator.pop(context);
                          listeyiGuncelle();
                        },
                        child: const Text(
                          "KAYDET",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- CANLI SAYAÇ KONTROLLERİ ---
  void _toggleWork() {
    setState(() {
      isWorkActive = !isWorkActive;
      if (isWorkActive) {
        _workSaniye = 0;
        _molaSaniye = 3600; // Başlangıçta 60 dk hazır bekler
        isBreakActive = false;
        _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!isBreakActive) {
            _workSaniye++;
            setState(() {
              _anlikWorkKazanc += CalculatorService.anlikSaniyelikKazancGetir(
                isWork: true,
                gecenSaniye: _workSaniye,
              );
            });
          } else {
            _molaSaniye++;
          }
        });
      } else {
        _workTimer?.cancel();
        _kaydetVeSifirla(true);
      }
    });
  }

  void _toggleStay() {
    setState(() {
      isStayActive = !isStayActive;
      if (isStayActive) {
        _staySaniye = 0;
        _stayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _staySaniye++;
          setState(() {
            if (_staySaniye > 14400) _anlikStayKazanc += 40.0 / 86400.0;
          });
        });
      } else {
        _stayTimer?.cancel();
        _kaydetVeSifirla(false);
      }
    });
  }

  // --- VERİTABANI İŞLEMLERİ ---
  Future<void> _kaydetVeSifirla(bool isWork) async {
    final simdi = DateTime.now();
    // Başlangıç zamanını saniye farkından geri giderek buluyoruz
    final baslangicZamani = simdi.subtract(
      Duration(seconds: isWork ? _workSaniye : _staySaniye),
    );

    // Saatleri "08:30" formatına getiriyoruz
    String bS =
        "${baslangicZamani.hour.toString().padLeft(2, '0')}:${baslangicZamani.minute.toString().padLeft(2, '0')}";
    String sS =
        "${simdi.hour.toString().padLeft(2, '0')}:${simdi.minute.toString().padLeft(2, '0')}";

    String bugunKey = DateFormat('yyyy-MM-dd').format(simdi);
    int tip = isWork ? 0 : 1;

    double toplamGecenSaat = (isWork ? _workSaniye : _staySaniye) / 3600.0;
    double sonKazanc = isWork ? _anlikWorkKazanc : _anlikStayKazanc;

    await DbHelper.instance.mesaiKaydet({
      // BURASI DÜZELDİ: Artık tarih stringine [08:30-17:00] ekleniyor
      'tarih': "$bugunKey [$bS-$sS]",
      'toplamSaat': double.parse(toplamGecenSaat.toStringAsFixed(2)),
      'geceSaati': 0.0,
      'konaklamaGun': tip,
      'molaSuresi': isWork ? (_molaSaniye ~/ 60) : 0,
      'kazanc': double.parse(sonKazanc.toStringAsFixed(2)),
    });

    setState(() {
      if (isWork) {
        _anlikWorkKazanc = 0.0;
        _workSaniye = 0;
        _molaSaniye = 3600;
        isBreakActive = false;
      } else {
        _anlikStayKazanc = 0.0;
        _staySaniye = 0;
      }
    });
    listeyiGuncelle();
  }

  Future<void> _cokluGunKaydet(
    DateTime basT,
    DateTime bitT,
    TimeOfDay basS,
    TimeOfDay bitS,
    bool isWork,
    int mola,
  ) async {
    final db = await DbHelper.instance.database;
    DateTime tempDate = DateTime(basT.year, basT.month, basT.day);
    DateTime lastDate = DateTime(bitT.year, bitT.month, bitT.day);

    // Saatleri formatlıyoruz: "08:30" gibi
    String bS =
        "${basS.hour.toString().padLeft(2, '0')}:${basS.minute.toString().padLeft(2, '0')}";
    String sS =
        "${bitS.hour.toString().padLeft(2, '0')}:${bitS.minute.toString().padLeft(2, '0')}";

    while (tempDate.isBefore(lastDate) || tempDate.isAtSameMomentAs(lastDate)) {
      String currentKey = DateFormat('yyyy-MM-dd').format(tempDate);
      double gSaat = 0;

      if (isWork) {
        // Saat farkı hesaplama
        double baslangicOndalik = basS.hour + (basS.minute / 60.0);
        double bitisOndalik = bitS.hour + (bitS.minute / 60.0);
        gSaat = bitisOndalik - baslangicOndalik - (mola / 60.0);
      }

      await db.insert('mesailer', {
        // BURASI KRİTİK: Tarihin yanına saati paketliyoruz
        'tarih': "$currentKey [$bS-$sS]",
        'kazanc': isWork
            ? double.parse((gSaat * 13.0).toStringAsFixed(2))
            : 45.0,
        'toplamSaat': double.parse(gSaat.toStringAsFixed(2)),
        'konaklamaGun': isWork ? 0 : 1,
        'molaSuresi': isWork ? mola : 0,
        'geceSaati': 0.0,
      });
      tempDate = tempDate.add(const Duration(days: 1));
    }
  }

  void _gunuSilOnay(String gunKey, bool isWork) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kaydı Sil"),
        content: const Text("Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İPTAL"),
          ),
          TextButton(
            onPressed: () async {
              final db = await DbHelper.instance.database;
              await db.delete(
                'mesailer',
                where: "tarih LIKE ? AND konaklamaGun = ?",
                whereArgs: ['$gunKey%', isWork ? 0 : 1],
              );
              Navigator.pop(context);
              listeyiGuncelle();
            },
            child: const Text("SİL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> listeyiGuncelle() async {
    final veriler = await DbHelper.instance.tumMesaileriGetir();
    double euroS = 0.0;
    double saatS = 0.0;
    Map<String, Map<String, dynamic>> geciciG = {};
    String ayKey = DateFormat('yyyy-MM').format(_seciliAy);

    for (var kayit in veriler) {
      String kTar = kayit['tarih']?.toString() ?? "";

      if (kTar.contains(ayKey)) {
        double kaz = (kayit['kazanc'] ?? 0.0).toDouble();
        double tSa = (kayit['toplamSaat'] ?? 0.0).toDouble();
        euroS += kaz;
        if (kayit['konaklamaGun'] == 0) saatS += tSa;

        String gKey = kTar.substring(0, 10);

        // Paketi açıyoruz: "2026-04-06 [08:00-17:00]" -> "08:00-17:00"
        String saatAraligi = "";
        if (kTar.contains("[")) {
          saatAraligi = kTar.split("[").last.replaceAll("]", "");
        } else {
          saatAraligi = "---"; // Eski kayıtlar için
        }

        if (!geciciG.containsKey(gKey)) {
          geciciG[gKey] = {
            'tarih': gKey,
            'toplamMaas': 0.0,
            'toplamHarcirah': 0.0,
            'toplamSaat': 0.0,
            'saatDetay': '',
            'hasHarcirah': false,
            'hasMaas': false,
          };
        }

        if (kayit['konaklamaGun'] == 0) {
          geciciG[gKey]!['toplamMaas'] += kaz;
          geciciG[gKey]!['toplamSaat'] += tSa;
          geciciG[gKey]!['saatDetay'] = saatAraligi; // Artık gerçek saat burada
          geciciG[gKey]!['hasMaas'] = true;
        } else {
          geciciG[gKey]!['toplamHarcirah'] += kaz;
          geciciG[gKey]!['hasHarcirah'] = true;
        }
      }
    }

    int sonG = DateTime(_seciliAy.year, _seciliAy.month + 1, 0).day;
    setState(() {
      gunlukOzetlerMap = geciciG;
      ayinTumGunleri = List.generate(
        sonG,
        (i) => DateTime(_seciliAy.year, _seciliAy.month, i + 1),
      ).reversed.toList();
      aylikToplamEuro = euroS;
      aylikToplamSaat = saatS;
    });
  }

  void _ayDegistir(int offset) {
    setState(
      () => _seciliAy = DateTime(_seciliAy.year, _seciliAy.month + offset, 1),
    );
    listeyiGuncelle();
  }

  // --- ARAYÜZ BİLEŞENLERİ ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "TruckTrack Pro 2026",
          style: TextStyle(fontWeight: FontWeight.bold),
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
            aktifMi: isWorkActive && !isBreakActive,
            renk: Colors.orange,
            onTap: _toggleWork,
          ),

          if (isWorkActive) // Canlı Mola Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: InkWell(
                onTap: () => setState(() => isBreakActive = !isBreakActive),
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: isBreakActive
                        ? Colors.redAccent
                        : Colors.blueGrey[700],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isBreakActive
                            ? Icons.pause_circle_filled
                            : Icons.coffee,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isBreakActive ? "MOLA SAYILIYOR..." : "MOLA VER",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const VerticalDivider(
                        color: Colors.white24,
                        indent: 15,
                        endIndent: 15,
                        width: 30,
                      ),
                      Text(
                        "${(_molaSaniye ~/ 60)} dk",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          _buildAnaButon(
            baslik: "TIRDA KONAKLAMA (NET)",
            deger: _anlikStayKazanc,
            aktifMi: isStayActive,
            renk: Colors.blue[800]!,
            onTap: _toggleStay,
          ),
          _buildAyNavigasyon(),
          Expanded(child: _buildKayitListesi()),
        ],
      ),
    );
  }

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
          _ozetSutun("AYLIK TOPLAM", "€${aylikToplamEuro.toStringAsFixed(2)}"),
          Container(width: 1, height: 40, color: Colors.white24),
          _ozetSutun("TOPLAM SAAT", "${aylikToplamSaat.toStringAsFixed(1)} h"),
        ],
      ),
    );
  }

  Widget _ozetSutun(String b, String d) => Column(
    children: [
      Text(b, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      Text(
        d,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

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
        height: 85,
        decoration: BoxDecoration(
          color: aktifMi ? Colors.green : renk,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              aktifMi ? "KAYIT DEVAM EDİYOR..." : baslik,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "€${deger.toStringAsFixed(4)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyNavigasyon() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => _ayDegistir(-1),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_seciliAy).toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
          onPressed: () => _ayDegistir(1),
        ),
      ],
    ),
  );

  Widget _buildKayitListesi() {
    return ListView.builder(
      itemCount: ayinTumGunleri.length,
      itemBuilder: (context, index) {
        final tarihDT = ayinTumGunleri[index];
        final gunKey = DateFormat('yyyy-MM-dd').format(tarihDT);
        final gunData = gunlukOzetlerMap[gunKey];
        bool isWk = tarihDT.weekday > 5;

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: isWk ? Colors.red[700] : Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "${tarihDT.day} ${DateFormat('EEEE').format(tarihDT).substring(0, 3)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: gunData != null && (gunData['hasMaas'] ?? false)
                        ? InkWell(
                            onLongPress: () => _gunuSilOnay(gunKey, true),
                            onTap: () => _guncellemePaneli(
                              gunKey,
                              true,
                              gunData['toplamMaas'],
                              gunData['toplamSaat'],
                            ),
                            child: _gunlukKart(
                              gunData['toplamMaas'],
                              "${gunData['saatDetay']} (${gunData['toplamSaat'].toStringAsFixed(1)}h)",
                              Colors.orange,
                              true,
                            ),
                          )
                        : _bosGunBtn(gunKey, true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: gunData != null && (gunData['hasHarcirah'] ?? false)
                        ? InkWell(
                            onLongPress: () => _gunuSilOnay(gunKey, false),
                            onTap: () => _guncellemePaneli(
                              gunKey,
                              false,
                              gunData['toplamHarcirah'],
                              24,
                            ),
                            child: _gunlukKart(
                              gunData['toplamHarcirah'],
                              "Harcırah",
                              Colors.blue[800]!,
                              false,
                            ),
                          )
                        : _bosGunBtn(gunKey, false),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bosGunBtn(String k, bool w) => InkWell(
    onTap: () => _guncellemePaneli(k, w, 0.0, 0.0),
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: w
              ? Colors.orange.withOpacity(0.2)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Icon(
        w ? Icons.drive_eta : Icons.bed,
        size: 16,
        color: Colors.grey[300],
      ),
    ),
  );

  Widget _gunlukKart(double m, String a, Color r, bool l) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border(
        left: l ? BorderSide(color: r, width: 4) : BorderSide.none,
        right: !l ? BorderSide(color: r, width: 4) : BorderSide.none,
      ),
    ),
    child: Column(
      crossAxisAlignment: l ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          "€${m.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: r),
        ),
        Text(a, style: const TextStyle(fontSize: 9, color: Colors.black54)),
      ],
    ),
  );
}

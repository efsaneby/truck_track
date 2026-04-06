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
  Map<String, Map<String, dynamic>> gunlukOzetlerMap = {};
  List<DateTime> ayinTumGunleri = [];
  DateTime _seciliAy = DateTime.now();

  Timer? _workTimer;
  Timer? _stayTimer;
  double _anlikWorkKazanc = 0.0;
  double _anlikStayKazanc = 0.0;
  int _workSaniye = 0;
  int _staySaniye = 0;
  double aylikToplamEuro = 0.0;
  double aylikToplamSaat = 0.0;

  @override
  void initState() {
    super.initState();
    listeyiGuncelle();
  }

  // --- GELİŞMİŞ ÇOKLU GÜN GÜNCELLEME PANELİ ---
  void _guncellemePaneli(
    String gunKey,
    bool isWork,
    double mevcutMiktar,
    double mevcutSaat,
  ) {
    DateTime baslangicTarihi = DateTime.parse(gunKey);
    DateTime bitisTarihi = DateTime.parse(gunKey);
    TimeOfDay baslangicSaat = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay bitisSaat = const TimeOfDay(hour: 17, minute: 0);
    int molaDakika = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setPanelState) {
          int gunFarki = bitisTarihi.difference(baslangicTarihi).inDays;
          bool isCokluGun = gunFarki > 0;

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
                  isCokluGun ? "Çoklu Gün Girişi" : "$gunKey Düzenle",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text("Başlangıç"),
                  subtitle: Text(
                    "${DateFormat('dd/MM').format(baslangicTarihi)} - ${baslangicSaat.format(context)}",
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: baslangicSaat,
                    );
                    if (time != null) setPanelState(() => baslangicSaat = time);
                  },
                ),
                ListTile(
                  title: const Text("Bitiş"),
                  subtitle: Text(
                    "${DateFormat('dd/MM').format(bitisTarihi)} - ${bitisSaat.format(context)}",
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: bitisTarihi,
                      firstDate: baslangicTarihi,
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: bitisSaat,
                      );
                      if (time != null) {
                        setPanelState(() {
                          bitisTarihi = date;
                          bitisSaat = time;
                        });
                      }
                    }
                  },
                ),
                if (isWork)
                  Slider(
                    value: molaDakika.toDouble(),
                    min: 0,
                    max: 120,
                    divisions: 8,
                    label: "$molaDakika dk Mola",
                    onChanged: (v) =>
                        setPanelState(() => molaDakika = v.toInt()),
                  ),
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
                          "TÜM GÜNLERİ KAYDET",
                          style: TextStyle(color: Colors.white),
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

  Future<void> _cokluGunKaydet(
    DateTime basTarih,
    DateTime bitTarih,
    TimeOfDay basSaat,
    TimeOfDay bitSaat,
    bool isWork,
    int mola,
  ) async {
    final db = await DbHelper.instance.database;
    DateTime tempDate = basTarih;
    int toplamGun = bitTarih.difference(basTarih).inDays;

    while (tempDate.isBefore(bitTarih) || tempDate.isAtSameMomentAs(bitTarih)) {
      String currentKey = DateFormat('yyyy-MM-dd').format(tempDate);
      double gunlukKazanc = 0;
      double gunlukSaat = 0;

      if (isWork) {
        if (toplamGun == 0) {
          double h =
              bitSaat.hour +
              (bitSaat.minute / 60.0) -
              (basSaat.hour + (basSaat.minute / 60.0));
          gunlukSaat = h - (mola / 60.0);
        } else if (tempDate == basTarih) {
          gunlukSaat = 24.0 - (basSaat.hour + (basSaat.minute / 60.0));
        } else if (tempDate == bitTarih) {
          gunlukSaat = (bitSaat.hour + (bitSaat.minute / 60.0));
        } else {
          gunlukSaat = 24.0;
        }
        gunlukKazanc = gunlukSaat * 13.0;
      } else {
        if (toplamGun == 0) {
          gunlukKazanc = CalculatorService.tekGunlukHarcirahHesapla(
            basSaat.hour,
            bitSaat.hour,
          );
          gunlukSaat =
              bitSaat.hour +
              (bitSaat.minute / 60.0) -
              (basSaat.hour + (basSaat.minute / 60.0));
        } else {
          if (tempDate == basTarih) {
            gunlukKazanc = 32.58;
            gunlukSaat = 24.0 - (basSaat.hour + (basSaat.minute / 60.0));
          } else if (tempDate == bitTarih) {
            gunlukKazanc = 14.94;
            gunlukSaat = bitSaat.hour + (bitSaat.minute / 60.0);
          } else {
            gunlukKazanc = 54.44;
            gunlukSaat = 24.0;
          }
        }
      }

      int tip = isWork ? 0 : 1;
      List<Map<String, dynamic>> mevcut = await db.query(
        'mesailer',
        where: "tarih LIKE ? AND konaklamaGun = ?",
        whereArgs: ['$currentKey%', tip],
      );

      Map<String, dynamic> row = {
        'tarih': "$currentKey 12:00:00",
        'kazanc': double.parse(gunlukKazanc.toStringAsFixed(2)),
        'toplamSaat': double.parse(gunlukSaat.toStringAsFixed(2)),
        'konaklamaGun': tip,
        'geceSaati': 0.0,
      };

      if (mevcut.isEmpty) {
        await db.insert('mesailer', row);
      } else {
        await db.update(
          'mesailer',
          row,
          where: "id = ?",
          whereArgs: [mevcut.first['id']],
        );
      }
      tempDate = tempDate.add(const Duration(days: 1));
    }
  }

  void _gunuSilOnay(String gunKey, bool isWork) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${isWork ? 'Direksiyon' : 'Konaklama'} Sil"),
        content: const Text("Bu işlem geri alınamaz. Emin misiniz?"),
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
              if (mounted) Navigator.pop(context);
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
    double euroSayaci = 0.0;
    double saatSayaci = 0.0;
    Map<String, Map<String, dynamic>> geciciGruplama = {};
    String seciliAyKey = DateFormat('yyyy-MM').format(_seciliAy);

    for (var kayit in veriler) {
      String kayitTarih = kayit['tarih']?.toString() ?? "";
      if (kayitTarih.startsWith(seciliAyKey)) {
        double kazanc = (kayit['kazanc'] ?? 0.0).toDouble();
        double tSaat = (kayit['toplamSaat'] ?? 0.0).toDouble();

        euroSayaci += kazanc;
        saatSayaci += tSaat;

        String gunKey = kayitTarih.substring(0, 10);

        // --- HATA BURADAYDI: EĞER GÜN YOKSA ÖNCE OLUŞTURUYORUZ ---
        if (!geciciGruplama.containsKey(gunKey)) {
          geciciGruplama[gunKey] = {
            'tarih': gunKey,
            'toplamMaas': 0.0,
            'toplamHarcirah': 0.0,
            'toplamSaat': 0.0,
            'hasHarcirah': false,
            'hasMaas': false,
          };
        }

        if (kayit['konaklamaGun'] == 0) {
          geciciGruplama[gunKey]!['toplamMaas'] =
              (geciciGruplama[gunKey]!['toplamMaas'] ?? 0.0) + kazanc;
          geciciGruplama[gunKey]!['toplamSaat'] =
              (geciciGruplama[gunKey]!['toplamSaat'] ?? 0.0) + tSaat;
          geciciGruplama[gunKey]!['hasMaas'] = true;
        } else {
          geciciGruplama[gunKey]!['toplamHarcirah'] =
              (geciciGruplama[gunKey]!['toplamHarcirah'] ?? 0.0) + kazanc;
          geciciGruplama[gunKey]!['hasHarcirah'] = true;
        }
      }
    }
    int sonGun = DateTime(_seciliAy.year, _seciliAy.month + 1, 0).day;
    List<DateTime> geciciGunler = List.generate(
      sonGun,
      (i) => DateTime(_seciliAy.year, _seciliAy.month, i + 1),
    );

    setState(() {
      gunlukOzetlerMap = geciciGruplama;
      ayinTumGunleri = geciciGunler.reversed.toList();
      aylikToplamEuro = euroSayaci;
      aylikToplamSaat = saatSayaci;
    });
  }

  void _ayDegistir(int offset) {
    setState(
      () => _seciliAy = DateTime(_seciliAy.year, _seciliAy.month + offset, 1),
    );
    listeyiGuncelle();
  }

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
            aktifMi: isWorkActive,
            renk: Colors.orange,
            onTap: _toggleWork,
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

  Widget _buildKayitListesi() {
    return ListView.builder(
      itemCount: ayinTumGunleri.length,
      itemBuilder: (context, index) {
        final DateTime tarihDT = ayinTumGunleri[index];
        final String gunKey = DateFormat('yyyy-MM-dd').format(tarihDT);
        final gunData = gunlukOzetlerMap[gunKey];
        bool isWeekend =
            tarihDT.weekday == DateTime.saturday ||
            tarihDT.weekday == DateTime.sunday;
        String gunAdi = DateFormat('EEEE').format(tarihDT).substring(0, 3);

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 15, bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isWeekend ? Colors.red[700] : Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${tarihDT.day} $gunAdi",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: gunData != null && gunData['hasMaas']
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
                              "${gunData['toplamSaat'].toStringAsFixed(1)} Saat",
                              Colors.orange,
                              true,
                            ),
                          )
                        : _bosGunButonu(gunKey, true),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: gunData != null && gunData['hasHarcirah']
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
                              "Net Harcırah",
                              Colors.blue[800]!,
                              false,
                            ),
                          )
                        : _bosGunButonu(gunKey, false),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
        height: 85,
        decoration: BoxDecoration(
          color: aktifMi ? Colors.green : renk,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              aktifMi ? "KAYDET VE BİTİR" : baslik,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "€${deger.toStringAsFixed(4)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyNavigasyon() {
    return Padding(
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
  }

  Widget _bosGunButonu(String gunKey, bool isWork) {
    return InkWell(
      onTap: () => _guncellemePaneli(gunKey, isWork, 0.0, 0.0),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isWork
                ? Colors.orange.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3),
          ),
        ),
        child: Icon(
          isWork ? Icons.drive_eta_rounded : Icons.bed_rounded,
          size: 18,
          color: isWork ? Colors.orange[200] : Colors.blue[200],
        ),
      ),
    );
  }

  Widget _gunlukKart(double miktar, String altMetin, Color renk, bool isLeft) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: isLeft ? BorderSide(color: renk, width: 4) : BorderSide.none,
          right: !isLeft ? BorderSide(color: renk, width: 4) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: isLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            "€${miktar.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          Text(
            altMetin,
            style: const TextStyle(fontSize: 9, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void _toggleWork() {
    setState(() {
      isWorkActive = !isWorkActive;
      if (isWorkActive) {
        _workSaniye = 0;
        _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _workSaniye++;
          setState(
            () =>
                _anlikWorkKazanc += CalculatorService.anlikSaniyelikKazancGetir(
                  isWork: true,
                  gecenSaniye: _workSaniye,
                ),
          );
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
            if (_staySaniye <= 14400) {
              _anlikStayKazanc = 0.0;
            } else {
              _anlikStayKazanc += 40.0 / 86400.0;
            }
          });
        });
      } else {
        _stayTimer?.cancel();
        _kaydetVeSifirla(false);
      }
    });
  }

  Future<void> _kaydetVeSifirla(bool isWork) async {
    final db = await DbHelper.instance.database;
    String bugunKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int tip = isWork ? 0 : 1;

    List<Map<String, dynamic>> mevcutKayitlar = await db.query(
      'mesailer',
      where: "tarih LIKE ? AND konaklamaGun = ?",
      whereArgs: ['$bugunKey%', tip],
    );

    double toplamGecenSaat = (isWork ? _workSaniye : _staySaniye) / 3600;
    double sonKazanc = isWork
        ? _anlikWorkKazanc
        : (_staySaniye > 14400 ? _anlikStayKazanc : 0.0);

    if (mevcutKayitlar.isNotEmpty) {
      double eskiSaat = (mevcutKayitlar.first['toplamSaat'] ?? 0.0).toDouble();
      double eskiKazanc = (mevcutKayitlar.first['kazanc'] ?? 0.0).toDouble();

      await db.update(
        'mesailer',
        {
          'toplamSaat': double.parse(
            (eskiSaat + toplamGecenSaat).toStringAsFixed(2),
          ),
          'kazanc': double.parse((eskiKazanc + sonKazanc).toStringAsFixed(2)),
          'tarih': DateTime.now().toString(),
        },
        where: "id = ?",
        whereArgs: [mevcutKayitlar.first['id']],
      );
    } else {
      await DbHelper.instance.mesaiKaydet({
        'tarih': DateTime.now().toString(),
        'toplamSaat': double.parse(toplamGecenSaat.toStringAsFixed(2)),
        'geceSaati': 0.0,
        'konaklamaGun': tip,
        'kazanc': double.parse(sonKazanc.toStringAsFixed(2)),
      });
    }

    setState(() {
      if (isWork) {
        _anlikWorkKazanc = 0.0;
        _workSaniye = 0;
      } else {
        _anlikStayKazanc = 0.0; // Buradaki hatalı ismi düzelttim
        _staySaniye = 0;
      }
    });
    listeyiGuncelle();
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'dart:developer' as debug;

import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

List panColors = [];
List ralColors = [];

List<String> paletteLabels = <String>[
  "Dominant",
  "Light Vibrant",
  "Vibrant",
  "Dark Vibrant",
  "Light Muted",
  "Muted",
  "Dark Muted"
];

//Palette visual switch
bool palette = false;

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  // Request Permission
  await Gal.requestAccess();

  //Load color tables
  Future<List<dynamic>> getColors(String file) async {
    String data = await rootBundle.loadString("assets/$file.json");

    //print(data.length);
    return jsonDecode(data);
  }

  //Load color tables
  panColors = await getColors('pantone');
  ralColors = await getColors('ral');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SplashScreen());
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds: 5),
        () => Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const PaintScanner())));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Image.asset('assets/splash.png'),
            Image.asset('assets/title.png'),
            const Text(
              'V. 1.0\r\n\u00a9 2024 Ariel.international ltd',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// This widget is the root of the application,called by SplashScreen
class PaintScanner extends StatelessWidget {
  const PaintScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'save',
      title: 'Paint Scanner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const SafeArea(child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? image;
  bool _image = false;

  Future<void> gallery(source) async {
    final ImagePicker picker = ImagePicker();
    image = (await picker.pickImage(
      source: source,
    ));
    _image = (image != null);
    palette = false;
    setState(() {});
  }

  void delState() {
    image = null;
    _image = false;
    palette = false;
    setState(() {});
  }

  Future<void> saveState() async {
    if (image == null) return;

    // Save to album
    await Gal.putImage(image!.path, album: 'Paint Scanner');
    showSaveSnack();
    palette = false;
    setState(() {});
  }

  void showSaveSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved in "Paint Scanner" album'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: AdMob(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: FrontPage(
                  image: image,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_album),
                            label: const Text('Load Photo'),
                            onPressed: () {
                              gallery(ImageSource.gallery);
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Take Photo'),
                            onPressed: () {
                              gallery(ImageSource.camera);
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Photo'),
                            onPressed: _image ? saveState : null,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Photo'),
                            onPressed: _image ? delState : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class FrontPage extends StatefulWidget {
  const FrontPage({
    super.key,
    required this.image,
  });

  final XFile? image;

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  void showPalette() {
    setState(() {
      palette = !palette;
    });
    const SnackBar(content: Text('palette'));
  }

  void resetPalette() {
    setState(() {
      palette = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            child: Builder(builder: (context) {
              if (widget.image == null) {
                return const Image(image: AssetImage('assets/no_photo.png'));
              } else {
                return Center(child: Image.file(File(widget.image!.path)));
              }
            }),
          ),
          Opacity(
            opacity: palette ? 0.5 : 0.0,
            child: const ModalBarrier(dismissible: false, color: Colors.black),
          ),
          Positioned(
            child: Visibility(
              visible: palette,
              child: Center(
                child: Container(
                  width: 300,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(
                          5.0,
                          5.0,
                        ),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(0.0, 0.0),
                        blurRadius: 0.0,
                        spreadRadius: 0.0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Palette(
                      image: widget.image,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.image == null
          ? null
          : FloatingActionButton(
              onPressed: () {
                showPalette();
              },
              child: const Icon(Icons.palette),
            ),
    );
  }
}

//Palette generator

class Palette extends StatefulWidget {
  const Palette({super.key, required this.image});

  final XFile? image;

  @override
  PaletteState createState() => PaletteState();
}

class PaletteState extends State<Palette> {
  final List<Widget> swatches = <Widget>[];
  PaletteGenerator? paletteGenerator;

  @override
  void initState() {
    super.initState();
    _updatePaletteGenerator();
  }

  Future<void> _updatePaletteGenerator() async {
    if (widget.image != null) {
      paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(File(widget.image!.path)),
        maximumColorCount: paletteLabels.length - 1,
      );
      setState(() {});
    }
  }

  int panLine = 0; //Pantone Line number
  int ralLine = 0; //RAL Line number
  int line = 0;

  String name = '';
  var r = 0;
  var g = 0;
  var b = 0;

  int sum = 0;
  int diff = 0;
  int dev = 0;
  int mindev = 0;

  //Compare colors
  bool checkColor() {
    dev = max(r, max(g, b)); //maximum deviation
    sum = r + g + b;

    debug.log('$line $name $r $g $b s=$sum d=$diff v=$dev m=$mindev');

    return (sum < diff) && (dev <= mindev);
  }

  //Check Pantone color
  String checkPantone(PaletteColor color) {
    var it = panColors.iterator;
    line = 0;
    diff = 1024; //start from the top!!
    mindev = 256; //also start from the top

    while (it.moveNext()) {
      name = it.current[0];
      r = (it.current[2] - color.color.red).abs();
      g = (it.current[3] - color.color.green).abs();
      b = (it.current[4] - color.color.blue).abs();

      if (checkColor()) {
        panLine = line;
        diff = sum;
        mindev = dev;
      }
      line++;
    }
    return '0xff${panColors[panLine][1]}';
  }

  //Check RAL color
  String checkRal(PaletteColor color) {
    var it = ralColors.iterator;
    line = 0;
    diff = 1024; //start from the top!!
    mindev = 256; //also start from the top

    while (it.moveNext()) {
      r = (it.current[3] - color.color.red).abs();
      g = (it.current[4] - color.color.green).abs();
      b = (it.current[5] - color.color.blue).abs();

      if (checkColor()) {
        ralLine = line;
        diff = sum;
        mindev = dev;
      }
      line++;
    }
    return '0xff${ralColors[ralLine][2]}';
  }

  @override
  Widget build(BuildContext context) {
    if (paletteGenerator == null || paletteGenerator!.colors.isEmpty) {
      return const Center(child: Text('Loading...'));
    } else {
      swatches.clear();
      int colNo = 0;

      for (final PaletteColor color in paletteGenerator!.paletteColors) {
        String pan = checkPantone(color);
        String ral = checkRal(color);

        swatches.add(
          PaletteSwatch(
            label: paletteLabels[colNo],
            color: color.color,
            tcolor: color.titleTextColor,
            plabel: panColors[panLine][0],
            pcolor: Color(int.parse(pan)),
            rnum: ralColors[ralLine][0],
            rlabel: ralColors[ralLine][1],
            rcolor: Color(int.parse(ral)),
          ),
        );
        colNo++;
      }

      return CarouselSlider(
        options: CarouselOptions(height: 400.0),
        items: swatches,
      );
    }
  }
}

@immutable
class PaletteSwatch extends StatelessWidget {
  /// Creates a PaletteSwatch.

  const PaletteSwatch({
    super.key,
    this.label,
    this.color,
    this.tcolor,
    this.pcolor,
    this.plabel,
    this.rnum,
    this.rlabel,
    this.rcolor,
  });

  final Color? color;
  final Color? tcolor;
  final Color? pcolor;
  final String? plabel;
  final String? label;
  final int? rnum;
  final String? rlabel;
  final Color? rcolor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            label!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          'RGB: #${color.toString().substring(10, 16)}',
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: color,
            height: 50.0,
          ),
        ),
        Text(
          'Pantone: $plabel',
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: pcolor,
            height: 50.0,
          ),
        ),
        Text(
          'RAL: $rlabel',
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: rcolor,
            height: 50.0,
            child: Center(
                child: Text(
              rnum.toString(),
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                foreground: Paint()..color = tcolor!,
              ),
            )),
          ),
        ),
      ],
    );
  }
}

//AdMob banner

class AdMob extends StatefulWidget {
  const AdMob({super.key});

  @override
  AdMobState createState() => AdMobState();
}

class AdMobState extends State<AdMob> {
  BannerAd? _bannerAd;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Builder(builder: (context) {
          if (_bannerAd != null) {
            return SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            );
          } else {
            return const SizedBox();
          }
        }),
      ),
    );
  }

  /// Loads and shows a banner ad.
  ///
  /// Dimensions of the ad are determined by the AdSize class.
  void _loadAd() async {
    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

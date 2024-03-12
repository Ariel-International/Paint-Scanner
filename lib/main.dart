import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'dart:math';
import 'dart:convert';
import 'dart:developer' as debug;
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

//Debug flag
bool db = true;
SharedPreferences? prefs;

void loadPrefs() {
  if (prefs!.getString('appID') == null) {
    counter = 10;
    prefs!.setInt('counter', counter);

    //Create appID
    final random = Random();
    const availableChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    appID = List.generate(
            8, (index) => availableChars[random.nextInt(availableChars.length)])
        .join();
    prefs!.setString('appID', appID);
  } else {
    appID = prefs!.getString('appID')!;
    counter = prefs!.getInt('counter')!;
  }

  //Check code
  if (prefs!.getString('noAds') != null) {
    noAds = prefs!.getString('noAds')!;
    adBlock = (noAds ==
        sha256.convert(utf8.encode(appID)).toString().substring(0, 8));
  }

  if (db) {
    debug.log('appID = $appID $noAds $adBlock');
    debug.log(sha256.convert(utf8.encode(appID)).toString().substring(0, 8));
    debug.log(
        sha256.convert(utf8.encode('1000$appID')).toString().substring(0, 8));
  }
}

Image? splashImg = Image.asset('assets/splash.png');
Image? titleImg = Image.asset('assets/title.png');

//Palette visual switch
bool palette = false;

//Credit counter
int counter = 0;
bool credit = false;

//Ads code
String noAds = '';
bool adBlock = false;

//app id
String appID = '';

//Price list
double p1 = 1.99;
double p2 = 4.99;

Future<void> main() async {
  // Ensure that plugin services are initialized
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

  //Load preferences
  prefs = await SharedPreferences.getInstance();
  loadPrefs();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> cacheImg(String asset) async {
      //Load images
      await precacheImage(AssetImage(asset), context);
    }

    cacheImg('assets/splash.png');
    cacheImg('assets/title.png');

    return const MaterialApp(home: SplashScreen());
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? splashTimer;

  void startTimer(int t) {
    splashTimer = Timer(
      const Duration(seconds: 5),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaintScanner()),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    startTimer(5);
  }

  final _focusNode = FocusNode();
  bool visible = false;
  late String code;

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  //Add credit from webpage
  void webCredit() {
    visible = true;
    splashTimer!.cancel();
    _focusNode.requestFocus();
    _launchUrl('https://ariel.international/ps?id=$appID');
    setState(() {});
  }

  //Insert code
  void inputText(String text) {
    _focusNode.unfocus();
    visible = false;
    if (text == sha256.convert(utf8.encode(appID)).toString().substring(0, 8)) {
      noAds = text;
      prefs!.setString('noAds', noAds);
      adBlock = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.amber,
          content: Text('adBlock activated'),
        ),
      );
    }
    if (text ==
        sha256.convert(utf8.encode('1000$appID')).toString().substring(0, 8)) {
      counter += 1000;
      prefs!.setInt('counter', counter);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.amber,
          content: Text('Credit updated'),
        ),
      );
    }
    if (text == '00000000') {
      prefs!.clear();
      loadPrefs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.amber,
          content: Text('Factory reset'),
        ),
      );
    }
    setState(() {});
    startTimer(5);
  }

  @override
  Widget build(BuildContext context) {
    _focusNode.unfocus();
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.yellowAccent.shade100,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: titleImg!,
          ),
        ),
        body: Stack(children: [
          Center(child: splashImg!),
          Opacity(
            opacity: visible ? 0.5 : 0.0,
            child: const ModalBarrier(dismissible: false, color: Colors.black),
          ),
          Visibility(
            visible: visible,
            child: TextField(
              keyboardType: TextInputType.visiblePassword,
              focusNode: _focusNode,
              onSubmitted: (value) => inputText(value),
              decoration: const InputDecoration(
                label: Text('Insert code'),
                isDense: true,
                fillColor: Colors.white,
                filled: true,
                //contentPadding: EdgeInsets.all(6.0),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ]),
        bottomNavigationBar: BottomAppBar(
          padding: EdgeInsets.zero,
          color: Colors.yellowAccent.shade100,
          surfaceTintColor: Colors.yellowAccent.shade100,
          height: 150.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Text(
                  'V. 1.0\r\n\u00a9 2024 Ariel.international ltd',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              GestureDetector(
                onTap: webCredit,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        'CREDITS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  void loadPhoto() {
    gallery(ImageSource.gallery);
  }

  void takePhoto() {
    gallery(ImageSource.camera);
  }

  Future<void> gallery(source) async {
    final ImagePicker picker = ImagePicker();
    if ((counter > 0) || adBlock) {
      XFile? newImage = (await picker.pickImage(
        source: source,
      ));
      if (newImage == null) return;
      XFile? oldImage = image;
      image = newImage;
      _image = (image != null);
      palette = false;
      if (image != oldImage && !adBlock) {
        counter--;
        prefs!.setInt('counter', counter);
      }
    } else {
      credit = true;
    }
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
      appBar: adBlock
          ? null
          : const PreferredSize(
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
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(color: Colors.black12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Text(
                      adBlock ? 'CREDIT: ∞' : 'CREDIT: $counter',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
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
                            onPressed: credit ? null : loadPhoto,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Take Photo'),
                            onPressed: credit ? null : takePhoto,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Photo'),
                            onPressed: _image && !credit ? saveState : null,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete Photo'),
                            onPressed: _image && !credit ? delState : null,
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
  RewardedAd? _rewardedAd;

  final String _adRewardedId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void showPalette() {
    setState(() {
      palette = !palette;
    });
  }

  void resetPalette() {
    setState(() {
      palette = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned(
          right: 0.0,
          left: 0.0,
          top: 0.0,
          bottom: 0.0,
          child: Builder(builder: (context) {
            if (widget.image == null) {
              //return const Image(image: AssetImage('assets/no_photo.png'));
              return Container(
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(color: Colors.lime.shade100),
                child: Column(
                  children: [
                    titleImg!,
                    const Text(
                      'NO PHOTO LOADED',
                      textScaler: TextScaler.linear(1.5),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey.shade300),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'To utilize Paint Scanner:\r\n1. Load or take a photo\r\n2. Press the palette button',
                                textScaler: TextScaler.linear(1.5),
                              ),
                              SizedBox(height: 10.0),
                              Text(
                                'The app shows the most similar color in RAL and Pantone range. The result is influenced by light, picture quality and available colors in each palette.\r\nImages are saved in Paint Scanner album.',
                                maxLines: 7,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                softWrap: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
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
        Visibility(
          visible: credit,
          child: Container(
            decoration: BoxDecoration(color: Colors.yellowAccent.shade100),
            child: Center(
              child: Column(
                children: [
                  const Image(image: AssetImage('assets/title.png')),
                  const SizedBox(height: 25.0),
                  const Text(
                    'CREDIT EXPIRED',
                    textScaler: TextScaler.linear(2.0),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const Text('You have no credit left'),
                  const SizedBox(height: 25.0),
                  const Text(
                    'Watch a short video \r\n to earn 10 credits',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 25.0),
                  ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(Colors.blue.shade900),
                      foregroundColor:
                          const MaterialStatePropertyAll(Colors.yellow),
                      padding: const MaterialStatePropertyAll(
                          EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 20.0)),
                    ),
                    onPressed: () {
                      _rewardedAd?.show(onUserEarnedReward:
                          (AdWithoutView ad, RewardItem rewardItem) {
                        // ignore: avoid_print
                        if (db) {
                          debug.log('Reward amount: ${rewardItem.amount}');
                        }
                        setState(() => counter += rewardItem.amount.toInt());
                        prefs!.setInt('counter', counter);
                        _loadRewardedAd();
                        if (counter > 0) credit = false;
                      });
                    },
                    icon: const Icon(Icons.video_label),
                    label: const Text(
                      'watch video',
                      textScaler: TextScaler.linear(2.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
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

  void _loadRewardedAd() {
    RewardedAd.load(
        adUnitId: _adRewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
              // Called when the ad showed the full screen content.
              onAdShowedFullScreenContent: (ad) {},
              // Called when an impression occurs on the ad.
              onAdImpression: (ad) {},
              // Called when the ad failed to show full screen content.
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
              },
              // Called when the ad dismissed full screen content.
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                //setState(() => _showWatchVideoButton = true);
              },
              // Called when a click is recorded for an ad.
              onAdClicked: (ad) {});

          // Keep a reference to the ad so you can show it later.
          _rewardedAd = ad;
        }, onAdFailedToLoad: (LoadAdError error) {
          // ignore: avoid_print
          print('RewardedAd failed to load: $error');
        }));
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
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
  int colNo = 0;
  //double _progress = 0.0;
  Duration oneSec = const Duration(seconds: 1);
  Timer? t;

  @override
  void initState() {
    super.initState();
    _updatePaletteGenerator();
  }

  Future<void> _updatePaletteGenerator() async {
    if (widget.image != null) {
      await Future.delayed(const Duration(seconds: 3));
      paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(File(widget.image!.path)),
        maximumColorCount: paletteLabels.length - 1,
      );
      int panLine = 0; //Pantone Line number
      int ralLine = 0; //RAL Line number
      int line = 0;

      var h = 0.0; //diff H
      var s = 0.0; //diff S
      var l = 0.0; //diff L

      var hsbSum = 0.0;
      var hsbDiff = 0.0;
      var hsbDev = 0.0;
      var hsbMinDev = 0.0;

      //HSB color
      List<double> hsb = [0, 0, 0];

      void rgb2hsb(PaletteColor color) {
        double r1 = color.color.red / 255;
        double g1 = color.color.green / 255;
        double b1 = color.color.blue / 255;
        double cMax = max(r1, max(g1, b1));
        double cMin = min(r1, min(g1, b1));
        double delta = cMax - cMin;

        if (delta == 0) {
          hsb[0] = 0;
          hsb[1] = 0;
        } else {
          if (cMax == r1) {
            hsb[0] = 60 * (((g1 - b1) / delta) % 6);
          }
          if (cMax == g1) {
            hsb[0] = 60 * (((b1 - r1) / delta) + 2);
          }
          if (cMax == b1) {
            hsb[0] = 60 * (((r1 - g1) / delta) + 4);
          }
          hsb[1] = delta / cMax * 100;
        }
        hsb[2] = cMax * 100;

        if (db) {
          debug.log('$r1 $g1 $b1 mx=$cMax mn=$cMin d=$delta hsb=$hsb');
        }
      }

      bool checkHsb() {
        hsbDev = max(h, max(s, l)); //maximum deviation
        hsbSum = h + s + l;

/*        if (db) {
          debug.log(
              '$line $name $h $s $l s=$hsbSum d=$hsbDiff v=$hsbDev m=$hsbMinDev');
        }
*/
        return /*(h <= hMin) && */ (hsbSum <= hsbDiff) && (hsbDev <= hsbMinDev);
      }

      //Check Pantone color
      String checkPantone(PaletteColor color) {
        var it = panColors.iterator;
        line = 0;
        //diff = 1024; //start from the top!!
        //mindev = 256; //also start from the top

        hsbDiff = 1024;
        hsbMinDev = 256;

        while (it.moveNext()) {
          //name = it.current[0];

          //rgb diff
          //r = (it.current[2] - color.color.red).abs();
          //g = (it.current[3] - color.color.green).abs();
          //b = (it.current[4] - color.color.blue).abs();

          //hsb diff
          h = (hsb[0] - double.parse(it.current[5].replaceAll(',', '.'))).abs();
          s = (hsb[1] - double.parse(it.current[6].replaceAll(',', '.'))).abs();
          l = (hsb[2] - double.parse(it.current[7].replaceAll(',', '.'))).abs();

          if (checkHsb()) {
            panLine = line;
            hsbDiff = hsbSum;
            hsbMinDev = hsbDev;
          }
/*
          if (checkColor()) {
            panLine = line;
            diff = sum;
            mindev = dev;
          }
*/
          line++;
        }
        return '0xff${panColors[panLine][1]}';
      }

      //Check RAL color
      String checkRal(PaletteColor color) {
        var it = ralColors.iterator;
        line = 0;
        //diff = 1024; //start from the top!!
        //mindev = 256; //also start from the top

        hsbDiff = 1024;
        hsbMinDev = 256;

        while (it.moveNext()) {
          //rgb diff
          //r = (it.current[3] - color.color.red).abs();
          //g = (it.current[4] - color.color.green).abs();
          //b = (it.current[5] - color.color.blue).abs();

          //hsb diff
          h = (hsb[0] - double.parse(it.current[6].replaceAll(',', '.'))).abs();
          s = (hsb[1] - double.parse(it.current[7].replaceAll(',', '.'))).abs();
          l = (hsb[2] - double.parse(it.current[8].replaceAll(',', '.'))).abs();

          if (checkHsb()) {
            ralLine = line;
            hsbDiff = hsbSum;
            hsbMinDev = hsbDev;
          }
/*
          if (checkColor()) {
            ralLine = line;
            diff = sum;
            mindev = dev;
          }
*/
          line++;
        }
        return '0xff${ralColors[ralLine][2]}';
      }

      swatches.clear();

      for (final PaletteColor color in paletteGenerator!.paletteColors) {
        rgb2hsb(color);

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
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (paletteGenerator == null || paletteGenerator!.colors.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Processing ...'),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircularProgressIndicator(
              strokeCap: StrokeCap.round,
              strokeWidth: 8.0,
              backgroundColor: Colors.blue.shade100,
              //value: _progress,
            ),
          ),
        ],
      );
    } else {
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

  final String _adBannerId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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
  void _loadBannerAd() async {
    BannerAd(
      adUnitId: _adBannerId,
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

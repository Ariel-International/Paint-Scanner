import 'dart:async';
import 'dart:io';

import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  // Request Permission
  await Gal.requestAccess();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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

  Future<void> gallery(source) async {
    final ImagePicker picker = ImagePicker();
    image = (await picker.pickImage(
      source: source,
    ))!;
    setState(() {});
  }

  void delState() {
    image = null;
    setState(() {});
  }

  Future<void> saveState() async {
    if (image == null) return;
    File file = File(image!.path);

    // Save to album
    await Gal.putImage(image!.path, album: 'Paint Scanner');
  }

/*
  _saveLocalImage() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    
    ui.Image image = await boundary.toImage();
    ByteData? byteData =
        await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      final result =
          await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
      print(result);
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(120.0),
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
                          IconButton(
                            icon: const Icon(Icons.photo_album),
                            tooltip: 'Load Photo',
                            onPressed: () {
                              gallery(ImageSource.gallery);
                            },
                          ),
                          const Text('Load\nPhoto'),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera),
                            tooltip: 'Take Photo',
                            onPressed: () {
                              gallery(ImageSource.camera);
                            },
                          ),
                          const Text('Take\nPhoto'),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.save),
                            tooltip: 'Save Photo',
                            onPressed: () {
                              saveState();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Saved in "Paint Scanner" album'),
                                ),
                              );
                            },
                          ),
                          const Text('Save\nPhoto'),
                        ],
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete Photo',
                            onPressed: () {
                              delState();
                            },
                          ),
                          const Text('Delete\nPhoto'),
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Builder(builder: (context) {
            if (widget.image == null) {
              return Image.asset('assets/no_photo.png');
            } else {
              return Image.file(File(widget.image!.path));
            }
          }),
        ),
        Container(
          color: Colors.blue,
          child: const SizedBox(
            height: 100,
            child: Center(child: Text('palette')),
          ),
        ),
      ],
    );
  }
}

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

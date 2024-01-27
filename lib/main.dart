import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _image = '';
  XFile? image;

  final _globalKey = GlobalKey();

  Future<void> gallery(source) async {
    final ImagePicker picker = ImagePicker();
    image = (await picker.pickImage(
      source: source,
    ))!;
    upState(image);
  }

  void upState(XFile? img) {
    _image = img!.path;
    setState(() {});
  }

  void delState() {
    _image = '';
    setState(() {});
  }

  Future<void> saveState() async {
    if (image == null) return;
    final String path = await getApplicationDocumentsDirectory().toString();
    final String fileName = _image;
    image!.saveTo('$path/$fileName');
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: FrontPage(
                  image: _image,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      /*
                      Column(children: [
                        IconButton(
                          icon: const Icon(Icons.palette),
                          tooltip: 'View Photo',
                          onPressed: () {},
                        ),
                        const Text('View Photo'),
                      ]),
                      */
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

  final String image;

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Image.asset('assets/no_photo.png'),
        ),
        Container(
          color: Colors.amber,
          child: const SizedBox(
            height: 100,
            child: Center(child: Text('palette')),
          ),
        ),
      ],
    );
  }
}

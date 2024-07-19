import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

import '../main.dart';

// Crea una instancia de Logger
final logger = Logger();

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key}); 
  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? controller;
  bool _isCameraInitialized = false;

  // Para cambiar la calidad de la vista de la cámara
  final resolutionPresets = ResolutionPreset.values;
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  // Variables para el zoom
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      logger.e('Error occurred while taking picture: $e');
      return null;
    }
  }

  Future<void> uploadFile(File file) async {
  try {
    // Nombre del archivo en el storage
    String fileName = basename(file.path);
    // Referencia al storage
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child('uploads/$fileName');
    // Subir el archivo
    await ref.putFile(file);
    logger.i('File uploaded: $fileName');
  } catch (e) {
    logger.e('Failed to upload file: $e');
  }
}

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    // Para cambiar la calidad de la vista de la cámara
    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
      
      // Obtener niveles de zoom
      _maxAvailableZoom = await cameraController.getMaxZoomLevel();
      _minAvailableZoom = await cameraController.getMinZoomLevel();
      _currentZoomLevel = _minAvailableZoom;  // Inicializar al nivel mínimo de zoom
      
    } on CameraException catch (e) {
      logger.e('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  // Administrar los cambios del ciclo de vida anulando el método WidgetsBindingObserver didChangeAppLifecycleState
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void initState() {
    // Evitar que obstruya la vista de la cámara agregando lo siguiente al método
    // // Hide the status bar
    // SystemChrome.setEnabledSystemUIOverlays([]);

    onNewCameraSelected(cameras[0]);
    super.initState();
  }

  // Liberar la memoria en el método cuando la cámara no esté activa
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1 / controller!.value.aspectRatio,
                  child: controller!.buildPreview(),
                ),
                Positioned(
                  top: 30,
                  right: 30,
                  child: DropdownButton<ResolutionPreset>(
                    dropdownColor: Colors.black87,
                    underline: Container(),
                    value: currentResolutionPreset,
                    items: [
                      for (ResolutionPreset preset in resolutionPresets)
                        DropdownMenuItem(
                          value: preset,
                          child: Text(
                            preset.toString().split('.')[1].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                    ],
                    onChanged: (value) {
                      setState(() {
                        currentResolutionPreset = value!;
                        _isCameraInitialized = false;
                      });
                      onNewCameraSelected(controller!.description);
                    },
                    hint: const Text("Select item"),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _currentZoomLevel,
                              min: _minAvailableZoom,
                              max: _maxAvailableZoom,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                              onChanged: (value) async {
                                setState(() {
                                  _currentZoomLevel = value;
                                });
                                await controller!.setZoomLevel(value);
                              },
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${_currentZoomLevel.toStringAsFixed(1)}x',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () async {
                          XFile? rawImage = await takePicture();
                          if (rawImage != null) {
                            File imageFile = File(rawImage.path);

                            int currentUnix = DateTime.now().millisecondsSinceEpoch;
                            final directory = await getApplicationDocumentsDirectory();
                            String fileFormat = imageFile.path.split('.').last;

                            await imageFile.copy(
                              '${directory.path}/$currentUnix.$fileFormat',
                            );

                            // Subir archivo al almacenamiento de Firebase
                            await uploadFile(imageFile);
                          }
                        },
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.circle, color: Colors.white38, size: 80),
                            Icon(Icons.circle, color: Colors.white, size: 65),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

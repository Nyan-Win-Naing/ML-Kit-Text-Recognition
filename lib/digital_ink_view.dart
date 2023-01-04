import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class DigitalInkView extends StatefulWidget {
  @override
  State<DigitalInkView> createState() => _DigitalInkViewState();
}

class _DigitalInkViewState extends State<DigitalInkView> {
  final DigitalInkRecognizerModelManager _modelManager =
      DigitalInkRecognizerModelManager();
  final String _language = 'my';
  late final DigitalInkRecognizer _digitalInkRecognizer =
      DigitalInkRecognizer(languageCode: _language);
  final Ink _ink = Ink();
  List<StrokePoint> _points = [];
  String _recognizedText = '';

  @override
  void dispose() {
    _digitalInkRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Burmese Text Recognition")),
      body: Column(
        children: [
          GestureDetector(
            onPanStart: (DragStartDetails details) {
              _ink.strokes.add(Stroke());
            },
            onPanUpdate: (DragUpdateDetails details) {
              setState(() {
                final RenderObject? object = context.findRenderObject();
                final localPosition = (object as RenderBox?)
                    ?.globalToLocal(details.localPosition);
                if (localPosition != null) {
                  _points = List.from(_points)
                    ..add(StrokePoint(
                      x: localPosition.dx,
                      y: localPosition.dy,
                      t: DateTime.now().millisecondsSinceEpoch,
                    ));
                }
                if (_ink.strokes.isNotEmpty) {
                  _ink.strokes.last.points = _points.toList();
                }
              });
            },
            onPanEnd: (DragEndDetails details) {
              _points.clear();
              setState(() {});
            },
            child: CustomPaint(
              painter: Signature(ink: _ink),
              size: const Size(double.infinity, 300),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _recogniseText,
                  child: const Text('Read Text'),
                ),
                ElevatedButton(
                  onPressed: _clearPad,
                  child: const Text('Clear Pad'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _isModelDownloaded,
                  // onPressed: () {},
                  child: const Text('Check Model'),
                ),
                ElevatedButton(
                  onPressed: _downloadModel,
                  // onPressed: () {},
                  child: const Text('Download'),
                ),
                ElevatedButton(
                  // onPressed: _deleteModel,
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_recognizedText.isNotEmpty)
            Column(
              children: [
                const Text(
                  "Posible Burmese Words",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _recognizedText,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  void _clearPad() {
    setState(() {
      _ink.strokes.clear();
      _points.clear();
      _recognizedText = '';
    });
  }

  Future<void> _isModelDownloaded() async {
    _modelManager
        .isModelDownloaded(_language)
        .then((value) {})
        .catchError((error) {
      debugPrint(error.toString());
    });
  }

  Future<void> _downloadModel() async {
    _modelManager.downloadModel(_language).then((value) {
      print("Download Successfully............");
    }).catchError((error) {
      debugPrint(error.toString());
    });
  }

  Future<void> _recogniseText() async {
    showDialog(
        context: context,
        builder: (context) => const AlertDialog(
              title: Text('Recognizing'),
            ),
        barrierDismissible: true);
    try {
      var candidates = await _digitalInkRecognizer.recognize(_ink);
      candidates = candidates.getRange(0, 4).toList();
      _recognizedText = '';
      for (final candidate in candidates) {
        _recognizedText += '\n${candidate.text}';
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
    Navigator.pop(context);
  }
}

class Signature extends CustomPainter {
  Ink ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => true;
}

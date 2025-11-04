import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ViewPage extends StatefulWidget {
  final String userEmail;
  const ViewPage({super.key, required this.userEmail});

  @override
  _ViewPageState createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  List<FileSystemEntity> userAudios = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;
  PlayerState _playerState = PlayerState.stopped;

  // speech-to-text setup
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _loadUserAudios();
    _initSpeech();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          _currentlyPlayingPath = null;
        }
      });
    });
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize();
  }

  Future<void> _loadUserAudios() async {
    final dir = await getApplicationDocumentsDirectory();
    final allFiles = dir.listSync();

    setState(() {
      userAudios = allFiles.where((file) {
        final name = file.path.split('/').last;
        return name.startsWith(widget.userEmail);
      }).toList();
    });
  }

  Future<void> _togglePlayPause(String path) async {
    if (_currentlyPlayingPath == path && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() {
        _currentlyPlayingPath = path;
      });
    }
  }

  Future<void> _deleteAudio(FileSystemEntity file) async {
    try {
      await File(file.path).delete();
      _loadUserAudios();
    } catch (e) {
      debugPrint("Error deleting file: $e");
    }
  }

  bool _isPlaying(String path) {
    return _currentlyPlayingPath == path && _playerState == PlayerState.playing;
  }

  Future<void> _transcribeAudio(FileSystemEntity file) async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Speech recognition not available")),
      );
      return;
    }

    setState(() => _recognizedText = '');

    // Play the audio while listening (simple hack method)
    await _speech.listen(
      onResult: (val) {
        setState(() {
          _recognizedText = val.recognizedWords;
        });
      },
    );

    await _audioPlayer.play(DeviceFileSource(file.path));

    await Future.delayed(const Duration(seconds: 5)); // wait short time
    await _speech.stop();
    await _audioPlayer.stop();

    if (_recognizedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No text detected")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Transcribed Text"),
        content: SingleChildScrollView(
          child: Text(_recognizedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Audios'),
        centerTitle: true,
      ),
      body: userAudios.isEmpty
          ? const Center(
        child: Text(
          'No recordings found!',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: userAudios.length,
        itemBuilder: (context, index) {
          final file = userAudios[index];
          final fileName = file.path.split('/').last;
          final isPlaying = _isPlaying(file.path);

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.blue),
              title: Text(fileName, overflow: TextOverflow.ellipsis),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color:
                      isPlaying ? Colors.orange : Colors.green,
                    ),
                    onPressed: () => _togglePlayPause(file.path),
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_snippet,
                        color: Colors.purple),
                    onPressed: () => _transcribeAudio(file),
                  ),
                  IconButton(
                    icon:
                    const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAudio(file),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

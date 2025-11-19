import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;

class ViewPage extends StatefulWidget {
  final String userEmail;
  const ViewPage({super.key, required this.userEmail});

  @override
  State<ViewPage> createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
  List<FileSystemEntity> userAudios = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _loadUserAudios();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _playerState = state;
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          _currentlyPlayingPath = null;
        }
      });
    });
  }

  Future<void> _loadUserAudios() async {
    final dir = await getApplicationDocumentsDirectory();
    final allFiles = dir.listSync();

    if (!mounted) return;
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

      if (!mounted) return;
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

  // 🎙 Upload audio to backend for Whisper transcription
  Future<void> _transcribeAudio(FileSystemEntity file) async {
    // ✅ FIXED — Using your correct IP address (en1)
    final uri = Uri.parse('http://10.45.13.172:8000/transcribe');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: p.basename(file.path),
    ));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading audio for transcription...")),
    );

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(respStr);
        final text = jsonResp['text'] ?? '';

        if (text.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No text detected from backend")),
          );
        } else {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text("Transcribed Text"),
                content: SingleChildScrollView(child: Text(text)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Close"),
                  ),
                ],
              );
            },
          );
        }
      } else {
        debugPrint('Transcription failed: $respStr');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Transcription failed (${response.statusCode})")),
        );
      }
    } catch (e) {
      debugPrint('Error during transcription: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during transcription: $e")),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      color: isPlaying ? Colors.orange : Colors.green,
                    ),
                    onPressed: () => _togglePlayPause(file.path),
                  ),
                  IconButton(
                    icon: const Icon(Icons.text_snippet, color: Colors.purple),
                    onPressed: () => _transcribeAudio(file),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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

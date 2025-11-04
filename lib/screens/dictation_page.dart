import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class DictationPage extends StatefulWidget {
  final String userEmail;
  const DictationPage({super.key, required this.userEmail});

  @override
  State<DictationPage> createState() => _DictationPageState();
}

class _DictationPageState extends State<DictationPage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;
  List<FileSystemEntity> _userRecordings = [];

  final String _sampleText =
      'The quick brown fox jumps over the lazy dog. Please read this aloud clearly to record your voice.';

  @override
  void initState() {
    super.initState();
    _loadUserRecordings();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  /// Convert email into safe folder name
  String _safeEmail(String email) {
    return email.replaceAll(RegExp(r'[^\w]'), '_');
  }

  /// Load recordings only for logged-in user
  Future<void> _loadUserRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final userFolder =
    Directory('${directory.path}/${_safeEmail(widget.userEmail)}');

    if (await userFolder.exists()) {
      final files = userFolder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .toList();

      files.sort((a, b) =>
          b.statSync().modified.compareTo(a.statSync().modified)); // newest first

      setState(() => _userRecordings = files);
    } else {
      setState(() => _userRecordings = []);
    }
  }

  /// Start or stop recording
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // 🔹 Stop recording
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);

      if (path != null) {
        final directory = await getApplicationDocumentsDirectory();

        // 🔹 Create user folder
        final userFolder =
        Directory('${directory.path}/${_safeEmail(widget.userEmail)}');

        if (!(await userFolder.exists())) {
          await userFolder.create(recursive: true);
        }

        // 🔹 Save inside that folder
        final newFile = File(
          '${userFolder.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        await File(path).copy(newFile.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: ${newFile.path.split('/').last}')),
        );

        _loadUserRecordings(); // Refresh list
      }
    } else {
      // 🔹 Start recording
      final hasPermission = await _recorder.hasPermission();
      if (hasPermission) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/temp_record.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        if (!mounted) return;
        setState(() => _isRecording = true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
    }
  }

  /// Play audio
  Future<void> _playRecording(String filePath) async {
    await _player.stop();
    await _player.play(DeviceFileSource(filePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dictation Practice')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Read the following aloud:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Text(
                _sampleText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                _isRecording ? 'Stop Recording' : 'Start Reading',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: _toggleRecording,
            ),
            const SizedBox(height: 30),
            const Divider(thickness: 1),
            Text(
              'Your Recordings:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _userRecordings.isEmpty
                  ? const Center(child: Text('No recordings yet.'))
                  : ListView.builder(
                itemCount: _userRecordings.length,
                itemBuilder: (context, index) {
                  final file = _userRecordings[index];
                  final name = file.path.split('/').last;
                  return ListTile(
                    leading:
                    const Icon(Icons.play_arrow, color: Colors.blue),
                    title: Text(name),
                    onTap: () => _playRecording(file.path),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

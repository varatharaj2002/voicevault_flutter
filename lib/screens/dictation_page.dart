import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _isLoading = false;

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

  String _safeEmail(String email) => email.replaceAll(RegExp(r'[^\w]'), '_');

  Future<void> _loadUserRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final userFolder = Directory('${directory.path}/${_safeEmail(widget.userEmail)}');

    if (await userFolder.exists()) {
      final files = userFolder
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .toList();

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      setState(() => _userRecordings = files);
    } else {
      setState(() => _userRecordings = []);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      if (!mounted) return;
      setState(() => _isRecording = false);

      if (path != null) {
        final directory = await getApplicationDocumentsDirectory();
        final userFolder = Directory('${directory.path}/${_safeEmail(widget.userEmail)}');

        if (!(await userFolder.exists())) await userFolder.create(recursive: true);

        final newFile = File(
            '${userFolder.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
        await File(path).copy(newFile.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: ${newFile.path.split('/').last}')),
        );

        _loadUserRecordings();
      }
    } else {
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

  Future<void> _playRecording(String filePath) async {
    await _player.stop();
    await _player.play(DeviceFileSource(filePath));
  }

  /// 🧠 Transcribe using OpenAI Whisper API
  Future<String?> _transcribeAudio(File audioFile) async {
    const apiKey = "YOUR_OPENAI_API_KEY"; // 🔑 Add your OpenAI key here
    final url = Uri.parse("https://api.openai.com/v1/audio/transcriptions");

    try {
      final request = http.MultipartRequest("POST", url)
        ..headers['Authorization'] = "Bearer $apiKey"
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path))
        ..fields['model'] = 'whisper-1';

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        return data["text"];
      } else {
        debugPrint("Transcription failed: ${responseData.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error during transcription: $e");
      return null;
    }
  }

  Future<void> _showTranscription(File file) async {
    setState(() => _isLoading = true);
    final text = await _transcribeAudio(file);
    setState(() => _isLoading = false);

    if (text == null || text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No text detected.")));
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Transcribed Text"),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dictation Practice')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text('Read the following aloud:',
                    style: Theme.of(context).textTheme.titleMedium),
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
                Text('Your Recordings:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Expanded(
                  child: _userRecordings.isEmpty
                      ? const Center(child: Text('No recordings yet.'))
                      : ListView.builder(
                    itemCount: _userRecordings.length,
                    itemBuilder: (context, index) {
                      final file = _userRecordings[index];
                      final name = file.path.split('/').last;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.audiotrack,
                              color: Colors.blue),
                          title: Text(name),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow,
                                    color: Colors.green),
                                onPressed: () =>
                                    _playRecording(file.path),
                              ),
                              IconButton(
                                icon: const Icon(Icons.text_snippet,
                                    color: Colors.purple),
                                onPressed: () =>
                                    _showTranscription(File(file.path)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

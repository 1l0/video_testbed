import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:statescope/statescope.dart';
import 'package:chewie/chewie.dart';
import 'package:logging/logging.dart';

import 'state.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(
    StateScope(
      creator: () {
        return VideoData();
      },
      child: const VideoApp(),
    ),
  );
}

class VideoApp extends StatefulWidget {
  const VideoApp({super.key});

  @override
  VideoAppState createState() => VideoAppState();
}

class VideoAppState extends State<VideoApp> {
  @override
  Widget build(BuildContext context) {
    final vd = context.watch<VideoData>();
    return MaterialApp(
      title: 'Nostr HLS Demo',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: vd.data != null
              ? HLSVideo(data: vd.data!)
              : Text(vd.fetchState.message),
        ),
      ),
    );
  }
}

class HLSVideo extends StatefulWidget {
  const HLSVideo({required this.data, super.key});

  final String data;

  @override
  State<HLSVideo> createState() => _HLSVideoState();
}

class _HLSVideoState extends State<HLSVideo> {
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.networkUrl(
            Uri.parse(widget.data),
            formatHint: VideoFormat.hls,
          )
          ..initialize().then((_) {
            setState(() {});
          });
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      aspectRatio: _videoController.value.aspectRatio,
    );
  }

  @override
  void dispose() {
    _chewieController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _videoController.value.isInitialized
        ? Chewie(controller: _chewieController)
        : CircularProgressIndicator();
  }
}

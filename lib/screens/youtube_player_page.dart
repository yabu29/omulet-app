import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/subtitle_model.dart';
import '../services/firestore_service.dart';

/// YouTube動画プレイヤーページ
class YouTubePlayerPage extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic>? videoData;

  const YouTubePlayerPage({
    super.key,
    required this.videoId,
    this.videoData,
  });

  @override
  State<YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<YouTubePlayerPage> {
  late YoutubePlayerController _controller;
  bool _isPaused = false;
  String _currentSubtitle = '';
  Duration _currentPosition = Duration.zero;

  List<SubtitleItem> _subtitles = [];
  bool _isLoadingSubtitles = true;
  String _userLanguage = 'en'; // デフォルトは英語、後でユーザー設定から取得

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        hideControls: false,
        controlsVisibleAtStart: false,
        enableCaption: true,
        captionLanguage: 'en',
      ),
    );
    _controller.addListener(_onPlayerStateChange);
    _loadSubtitlesFromFirestore();
    _registerVideoToFirestore();
  }

  // Firestoreに動画を登録
  Future<void> _registerVideoToFirestore() async {
    if (widget.videoData == null) return;

    try {
      await _firestoreService.registerVideo(
        videoId: widget.videoId,
        title: widget.videoData!['title'] as String? ?? '',
        channelTitle: widget.videoData!['channelTitle'] as String? ?? '',
        description: widget.videoData!['description'] as String?,
        thumbnailUrl: widget.videoData!['thumbnailUrl'] as String?,
        durationSeconds: widget.videoData!['durationSeconds'] as int? ?? 0,
        language: 'en',
        nativeLanguage: 'ja',
      );
    } catch (e) {
      print('Error registering video to Firestore: $e');
      // エラーが発生しても動画再生は続行
    }
  }

  // Firestoreから字幕データを取得
  Future<void> _loadSubtitlesFromFirestore() async {
    try {
      final subtitles = await _firestoreService.getSubtitles(
        videoId: widget.videoId,
        language: _userLanguage,
      );

      setState(() {
        _subtitles = subtitles;
        _isLoadingSubtitles = false;
      });
    } catch (e) {
      print('Error loading subtitles: $e');
      setState(() {
        _isLoadingSubtitles = false;
      });
    }
  }

  void _updateSubtitle() {
    if (_subtitles.isEmpty) return;

    final position = _controller.value.position;
    final seconds = position.inSeconds;

    SubtitleItem? currentSubtitle;

    for (final subtitle in _subtitles) {
      final startSeconds = subtitle.startMs ~/ 1000;
      final endSeconds = subtitle.endMs ~/ 1000;
      if (seconds >= startSeconds && seconds <= endSeconds) {
        currentSubtitle = subtitle;
        break;
      }
    }

    final newSubtitle = currentSubtitle?.text ?? '';
    if (newSubtitle != _currentSubtitle) {
      setState(() {
        _currentSubtitle = newSubtitle;
        _currentPosition = position;
      });
    }
  }

  void _onPlayerStateChange() {
    final playerState = _controller.value.playerState;
    final isPlaying = _controller.value.isPlaying;

    _updateSubtitle();

    if (playerState == PlayerState.paused && isPlaying == false) {
      if (!_isPaused) {
        setState(() {
          _isPaused = true;
        });
      }
    } else if (playerState == PlayerState.playing) {
      setState(() {
        _isPaused = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: YoutubePlayerBuilder(
          onExitFullScreen: () {
            // フルスクリーン終了時の処理
          },
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.blueAccent,
            progressColors: const ProgressBarColors(
              playedColor: Colors.blueAccent,
              handleColor: Colors.blueAccent,
            ),
            topActions: [
              // 戻るボタンを追加
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
            bottomActions: [
              // 左端：時間表示
              CurrentPosition(),
              const SizedBox(width: 10),
              // ProgressBarは削除（showVideoProgressIndicatorの青いバーを使う）
              RemainingDuration(),
              // スペースを追加して右端にボタンを配置
              const Spacer(),
              // 右端：ボタン
              // 3秒戻るボタン
              GestureDetector(
                onTap: () {
                  final currentPosition = _controller.value.position;
                  final newPosition = currentPosition - const Duration(seconds: 3);
                  if (newPosition.isNegative) {
                    _controller.seekTo(Duration.zero);
                  } else {
                    _controller.seekTo(newPosition);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // 3秒進むボタン
              GestureDetector(
                onTap: () async {
                  final currentPosition = _controller.value.position;
                  final metadata = await _controller.metadata;
                  final duration = metadata.duration;
                  final newPosition = currentPosition + const Duration(seconds: 3);
                  if (newPosition > duration) {
                    _controller.seekTo(duration);
                  } else {
                    _controller.seekTo(newPosition);
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PlaybackSpeedButton(),
              const SizedBox(width: 10),
              FullScreenButton(),
            ],
          ),
          builder: (context, player) {
            return Column(
              children: [
                player,
                if (_isLoadingSubtitles)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    color: Colors.grey[850],
                    child: const Text(
                      'Loading subtitles...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (_currentSubtitle.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    color: Colors.grey[850],
                    child: Text(
                      _currentSubtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

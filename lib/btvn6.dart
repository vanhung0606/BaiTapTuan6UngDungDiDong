import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MusicApp());
}

class Song {
  final String title;
  final String artist;
  final String asset;

  const Song({
    required this.title,
    required this.artist,
    required this.asset,
  });
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Player',
      theme: ThemeData.dark(),
      home: const MusicHomeScreen(),
    );
  }
}

class MusicHomeScreen extends StatefulWidget {
  const MusicHomeScreen({super.key});

  @override
  State<MusicHomeScreen> createState() => _MusicHomeScreenState();
}

class _MusicHomeScreenState extends State<MusicHomeScreen> {
  final AudioPlayer _player = AudioPlayer();

  final List<Song> _songs = const [
    Song(
      title: 'Muộn rồi mà sao còn',
      artist: 'Sơn Tùng M-TP',
      asset: 'audios/septung.mp3',
    ),
    Song(
      title: 'Em',
      artist: 'Phương Thảo',
      asset: 'audios/em.mp4',
    ),
  ];

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isFavorite = false;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _player.onPlayerComplete.listen((_) {
      _nextSong();
    });
  }

  Song get _currentSong => _songs[_currentIndex];

  Future<void> _playSong(int index) async {
    setState(() {
      _currentIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = true;
    });

    await _player.stop();

    await _player.play(
      AssetSource(_songs[index].asset),
    );
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();

      setState(() {
        _isPlaying = false;
      });
    } else {
      if (_position > Duration.zero) {
        await _player.resume();
      } else {
        await _player.play(
          AssetSource(_currentSong.asset),
        );
      }

      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _previousSong() async {
    int newIndex = _currentIndex - 1;

    if (newIndex < 0) {
      newIndex = _songs.length - 1;
    }

    await _playSong(newIndex);
  }

  Future<void> _nextSong() async {
    int newIndex = (_currentIndex + 1) % _songs.length;

    await _playSong(newIndex);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),

                const Text(
                  'ĐANG PHÁT',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 25),

                // ĐĨA NHẠC
                Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF444444),
                        Color(0xFF151515),
                        Colors.black,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 95,
                      height: 95,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF252525),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  _currentSong.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _currentSong.artist,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                // THANH THỜI LƯỢNG
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      Slider(
                        value: progress,
                        onChanged: _duration.inMilliseconds == 0
                            ? null
                            : (value) {
                                final newPosition = Duration(
                                  milliseconds:
                                      (_duration.inMilliseconds * value)
                                          .round(),
                                );

                                _player.seek(newPosition);
                              },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position)),
                          Text(_formatDuration(_duration)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // NÚT ĐIỀU KHIỂN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 26,
                      onPressed: _previousSong,
                      icon: const Icon(Icons.skip_previous),
                    ),

                    IconButton(
                      iconSize: 26,
                      onPressed: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                      icon: Icon(
                        _isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Container(
                      width: 65,
                      height: 65,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: IconButton(
                        iconSize: 34,
                        color: Colors.black,
                        onPressed: _togglePlay,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    IconButton(
                      iconSize: 26,
                      onPressed: _nextSong,
                      icon: const Icon(Icons.skip_next),
                    ),

                    IconButton(
                      iconSize: 24,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã chọn chia sẻ bài hát',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // NÚT MỞ DANH SÁCH
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF202020),
                      isScrollControlled: true,
                      builder: (context) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.55,
                          minChildSize: 0.3,
                          maxChildSize: 0.85,
                          expand: false,
                          builder: (context, scrollController) {
                            return Column(
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 10),
                                  width: 45,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                const Text(
                                  'Danh sách bài hát',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemCount: _songs.length,
                                    itemBuilder: (context, index) {
                                      final song = _songs[index];

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.grey.shade800,
                                          child: const Icon(
                                            Icons.music_note,
                                          ),
                                        ),
                                        title: Text(song.title),
                                        subtitle:
                                            Text(song.artist),
                                        trailing:
                                            _currentIndex == index
                                                ? const Icon(
                                                    Icons.equalizer,
                                                    color: Colors.green,
                                                  )
                                                : null,
                                        onTap: () {
                                          Navigator.pop(context);
                                          _playSong(index);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.keyboard_arrow_up),
                        Text(
                          'Danh sách bài hát',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
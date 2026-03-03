import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_tab/utils/colors.dart';

/// Reusable video player widget that supports YouTube URLs using URL Launcher (Bypasses embed restrictions)
class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;
  final bool autoPlay;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
  }) : super(key: key);

  Future<void> _launchVideo(BuildContext context) async {
    final Uri url = Uri.parse(videoUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch video URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching video: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_fill,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _launchVideo(context),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Watch on YouTube'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Video opens in external app because of\nYouTube embedding restrictions',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

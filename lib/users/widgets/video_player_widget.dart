import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_tab/utils/colors.dart';

/// Reusable video player widget that bypasses YouTube embedding restrictions using url_launcher
class VideoPlayerWidget extends StatelessWidget {
  final String? videoUrl;
  final bool autoPlay;

  // We keep this to avoid breaking existing signatures if they pass unused variables,
  // but ideally refactoring the call sites is better. We add optional named params.
  const VideoPlayerWidget({
    Key? key,
    this.videoUrl,
    this.autoPlay = false,
    dynamic controller,
    int? startAt,
    int? endAt,
  }) : super(key: key);

  Future<void> _launchVideo(BuildContext context) async {
    if (videoUrl == null || videoUrl!.isEmpty) return;
    
    final Uri url = Uri.parse(videoUrl!);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
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
    if (videoUrl == null || videoUrl!.isEmpty) {
      return Container(
        width: double.infinity,
        color: Colors.black,
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Text(
              'No video available',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }

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
                color: AppColors.primary, // Using primary color which exists in colors.dart
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;

  const UserDetailsPage({super.key, required this.userId});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  VideoPlayerController? _videoController;
  WebViewController? _webViewController;
  bool isEmbeddedVideo = false;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String? _parseVideoType(String url) {
    Uri uri = Uri.parse(url);
    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      return 'youtube';
    } else if (uri.host.contains('vimeo.com')) {
      return 'vimeo';
    } else if (url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.webm') ||
        url.toLowerCase().endsWith('.mov')) {
      return 'direct';
    }
    return null;
  }

  String? _getVideoId(String url, String type) {
    Uri uri = Uri.parse(url);
    switch (type) {
      case 'youtube':
        if (uri.host.contains('youtube.com')) {
          return uri.queryParameters['v'];
        } else {
          return uri.pathSegments.last;
        }
      case 'vimeo':
        return uri.pathSegments.last;
      case 'direct':
        return url;
      default:
        return null;
    }
  }

  String _getEmbedUrl(String videoId, String type) {
    switch (type) {
      case 'youtube':
        return 'https://www.youtube.com/embed/$videoId';
      case 'vimeo':
        return 'https://player.vimeo.com/video/$videoId';
      default:
        return '';
    }
  }

  Widget _buildVideoPlayer(String videoUrl) {
    final videoType = _parseVideoType(videoUrl);
    if (videoType == null) {
      return const Text('Unsupported video format');
    }

    if (videoType == 'direct') {
      return FutureBuilder(
        future: () async {
          _videoController = VideoPlayerController.network(videoUrl);
          await _videoController!.initialize();
          return true;
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Text('Error loading video');
          }
          return AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_videoController!),
                IconButton(
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 50.0,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      final videoId = _getVideoId(videoUrl, videoType);
      if (videoId == null) return const Text('Invalid video URL');

      final embedUrl = _getEmbedUrl(videoId, videoType);
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(embedUrl));

      return SizedBox(
        height: 250,
        child: WebViewWidget(controller: _webViewController!),
      );
    }
  }

  Future<void> _acceptCompany(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'accepted': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company accepted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept company: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final String name = data['fullName'] ?? 'No name';
          final String email = data['email'] ?? 'No email';
          final String role = data['role'] ?? 'N/A';
          final String phone = data['phone'] ?? 'No phone';
          final String address = data['address'] ?? 'No address';
          final bool accepted = data['accepted'] ?? true;
          final String profilePicture = data['profilePicture'] ??
              'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png';

           final String? taxNumber = data['taxNumber'];
          final String? promotionalVideo = data['promotionalVideo'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(profilePicture),
                  ),
                ),
                const SizedBox(height: 20),
                Text(name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildDetailRow("Email", email),
                _buildDetailRow("Phone", phone),
                _buildDetailRow("Address", address),
                _buildDetailRow("Role", role),
                _buildDetailRow("Accepted", accepted ? "Yes" : "No",
                    color: accepted ? Colors.green : Colors.red),
                if (role == 'Company') ...[
                  if (taxNumber != null && taxNumber.isNotEmpty)
                    _buildDetailRow("Tax Number", taxNumber),
                  if (promotionalVideo != null &&
                      promotionalVideo.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Promotional Video",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildVideoPlayer(promotionalVideo),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Video URL: $promotionalVideo',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 30),
                if (role == 'Company' && !accepted)
                  ElevatedButton.icon(
                    onPressed: () => _acceptCompany(context),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept Company'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color color = Colors.black87}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

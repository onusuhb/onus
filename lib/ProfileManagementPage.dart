import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfileManagementPage extends StatefulWidget {
  const ProfileManagementPage({super.key});

  @override
  _ProfileManagementPageState createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfileManagementPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  bool isCompany = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController taxNumberController = TextEditingController();
  final TextEditingController videoLinkController = TextEditingController();

  File? _selectedImage;
  File? _selectedVideo;
  String? _uploadedImageUrl;
  String? _uploadedVideoUrl;
  String profilePicture = 'assets/profile_placeholder.png';
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;

  bool _isLoading = false;
  static const double MAX_VIDEO_SIZE_MB = 100;

  WebViewController? _webViewController;
  bool isEmbeddedVideo = false;
  String? videoType;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          isCompany = data['role'] == 'Company';
          nameController.text = data['fullName'] ?? '';
          emailController.text = data['email'] ?? _currentUser!.email!;
          phoneController.text = data['phone'] ?? '';
          addressController.text = data['address'] ?? '';
          profilePicture =
              data['profilePicture'] ?? 'assets/profile_placeholder.png';
          if (isCompany) {
            taxNumberController.text = data['taxNumber'] ?? '';
            _uploadedVideoUrl = data['promotionalVideo'];
            if (_uploadedVideoUrl != null) {
              _initializeVideoPlayer(_uploadedVideoUrl!);
            }
          }
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) {
    _videoController = VideoPlayerController.network(videoUrl);
    return _videoController!.initialize().then((_) {
      setState(() {});
    });
  }

  String? _parseVideoId(String url) {
    Uri uri = Uri.parse(url);

     if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      videoType = 'youtube';
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else {
        return uri.pathSegments.last;
      }
    }

     else if (uri.host.contains('vimeo.com')) {
      videoType = 'vimeo';
      return uri.pathSegments.last;
    }

     else if (url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.webm') ||
        url.toLowerCase().endsWith('.mov')) {
      videoType = 'direct';
      return url;
    }

    return null;
  }

  String _getEmbedUrl(String videoId) {
    switch (videoType) {
      case 'youtube':
        return 'https://www.youtube.com/embed/$videoId';
      case 'vimeo':
        return 'https://player.vimeo.com/video/$videoId';
      case 'direct':
        return videoId;
      default:
        return '';
    }
  }

  Future<void> _pickVideo() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Promotional Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickVideoFromDevice();
                },
                icon: const Icon(Icons.file_upload, color: Colors.white),
                label: const Text('Upload from Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showVideoLinkDialog();
                },
                icon: const Icon(Icons.link, color: Colors.white),
                label: const Text('Add Video Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickVideoFromDevice() async {
    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final videoFile = File(pickedFile.path);

      final videoSize = await videoFile.length();
      final videoSizeMB = videoSize / (1024 * 1024);

      if (videoSizeMB > MAX_VIDEO_SIZE_MB) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Video size must be less than ${MAX_VIDEO_SIZE_MB.toStringAsFixed(0)}MB'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _selectedVideo = videoFile;
        _isVideoLoading = true;
      });

      if (_videoController != null) {
        await _videoController!.dispose();
      }

      _videoController = VideoPlayerController.file(_selectedVideo!);
      await _videoController!.initialize();
      setState(() {
        _isVideoLoading = false;
      });
    }
  }

  void _showVideoLinkDialog() {
    videoLinkController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Video Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: videoLinkController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  hintText: 'YouTube, Vimeo, or direct video link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _handleVideoLink(value);
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Supported services:\n• YouTube\n• Vimeo\n• Direct video links (MP4, WebM, MOV)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (videoLinkController.text.isNotEmpty) {
                  _handleVideoLink(videoLinkController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleVideoLink(String videoLink) async {
    if (videoLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a video URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

     if (!videoLink.startsWith('http://') && !videoLink.startsWith('https://')) {
      videoLink = 'https://$videoLink';
    }

    try {
      final uri = Uri.parse(videoLink);
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw const FormatException('Invalid URL format');
      }

      final videoId = _parseVideoId(videoLink);
      if (videoId == null) {
        throw const FormatException('Unsupported video URL');
      }

      setState(() {
        _isVideoLoading = true;
      });

      if (_videoController != null) {
        await _videoController!.dispose();
        _videoController = null;
      }

      if (videoType == 'direct') {
         _videoController = VideoPlayerController.network(videoId);
        await _videoController!.initialize();
        await _videoController!.play();
        await _videoController!.pause();
        isEmbeddedVideo = false;
      } else {
         final embedUrl = _getEmbedUrl(videoId);
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(embedUrl));
        isEmbeddedVideo = true;
      }

      setState(() {
        _uploadedVideoUrl = videoLink;
        _selectedVideo = null;
        _isVideoLoading = false;
      });
    } catch (e) {
      setState(() {
        _isVideoLoading = false;
        _videoController = null;
        _webViewController = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is FormatException
              ? e.message
              : 'Invalid video link. Please check the URL and try again.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const String cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dbd9sw3fh/image/upload";
    const String uploadPreset = "onusfiles";

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl));
    request.fields["upload_preset"] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath("file", imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(await response.stream.bytesToString());
      return responseData["secure_url"];
    }
    return null;
  }

  Future<String?> _uploadVideoToCloudinary(File videoFile) async {
    const String cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dbd9sw3fh/video/upload";
    const String uploadPreset = "onusfiles";

     final videoSize = await videoFile.length();
    final videoSizeMB = videoSize / (1024 * 1024);  

    if (videoSizeMB > MAX_VIDEO_SIZE_MB) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Video size must be less than ${MAX_VIDEO_SIZE_MB.toStringAsFixed(0)}MB'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl));
    request.fields["upload_preset"] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath("file", videoFile.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        return responseData["secure_url"];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      String? newImageUrl = _uploadedImageUrl;
      String? newVideoUrl = _uploadedVideoUrl;

      if (_selectedImage != null) {
        newImageUrl = await _uploadImageToCloudinary(_selectedImage!);
      }

      if (isCompany && _selectedVideo != null) {
        newVideoUrl = await _uploadVideoToCloudinary(_selectedVideo!);
      }

      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(nameController.text.trim());

        if (passwordController.text.isNotEmpty) {
          await _auth.currentUser!.updatePassword(passwordController.text);
        }
      }

      Map<String, dynamic> updateData = {
        'fullName': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'profilePicture': newImageUrl ?? profilePicture,
      };

      if (isCompany) {
        updateData['taxNumber'] = taxNumberController.text.trim();
        if (newVideoUrl != null) {
          updateData['promotionalVideo'] = newVideoUrl;
        }
      }

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _fetchUserProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profile'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : NetworkImage(profilePicture),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.teal,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            _buildInputField("Full Name", nameController),
            const SizedBox(height: 16.0),
            _buildInputField("Email", emailController),
            const SizedBox(height: 16.0),
            _buildInputField("Phone", phoneController,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16.0),
            _buildInputField("Address", addressController),
            const SizedBox(height: 16.0),
            if (isCompany) ...[
              _buildInputField("Tax Number", taxNumberController),
              const SizedBox(height: 16.0),
              const Text(
                "Promotional Video",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Maximum video size: 100MB",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8.0),
              if (_isVideoLoading)
                const Center(child: CircularProgressIndicator())
              else if (_videoController != null &&
                  _videoController!.value.isInitialized)
                AspectRatio(
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
                )
              else if (isEmbeddedVideo && _webViewController != null)
                SizedBox(
                  height: 250,
                  child: WebViewWidget(
                    controller: _webViewController!,
                  ),
                ),
              const SizedBox(height: 8.0),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library, color: Colors.white),
                  label: const Text(
                    'Add Promotional Video',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              if (_uploadedVideoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Current video: $_uploadedVideoUrl',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 16.0),
            ],
            _buildInputField(
                "Password (Leave blank to keep current)", passwordController,
                obscureText: true),
            const SizedBox(height: 32.0),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'Update Profile',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

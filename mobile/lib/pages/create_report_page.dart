import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  static const String cloudName = 'jfd32524';
  static const String uploadPreset = 'SiagaBanjir_Upload';

  final formKey = GlobalKey<FormState>();
  final locationController = TextEditingController();
  final heightController = TextEditingController();
  final descriptionController = TextEditingController();

  final ImagePicker imagePicker = ImagePicker();

  LatLng? selectedLocation;
  XFile? selectedPhoto;
  Uint8List? selectedPhotoBytes;

  String severity = 'medium';
  bool loading = false;
  bool gettingLocation = false;
  String? errorMessage;

  @override
  void dispose() {
    locationController.dispose();
    heightController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Mengambil lokasi GPS pengguna.
  Future<void> getCurrentLocation() async {
    setState(() {
      gettingLocation = true;
      errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Aktifkan GPS perangkat terlebih dahulu.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi belum diberikan.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);

        locationController.text =
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal mengambil lokasi: $e';
      });
    } finally {
      if (mounted) {
        setState(() => gettingLocation = false);
      }
    }
  }

  // Memilih foto dari kamera atau galeri.
  Future<void> pickPhoto(ImageSource source) async {
    try {
      final photo = await imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1400,
      );

      if (photo == null) return;

      final bytes = await photo.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedPhoto = photo;
        selectedPhotoBytes = bytes;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal memilih foto: $e';
      });
    }
  }

  // Mengunggah foto ke Cloudinary.
  Future<String?> uploadPhoto() async {
    if (selectedPhotoBytes == null || selectedPhoto == null) {
      return null;
    }

    final originalName = selectedPhoto!.name;
    final dotIndex = originalName.lastIndexOf('.');

    final extension = dotIndex >= 0
        ? originalName.substring(dotIndex + 1).toLowerCase()
        : 'jpg';

    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    if (!allowedExtensions.contains(extension)) {
      throw Exception(
        'Format foto tidak didukung. Gunakan JPG, JPEG, PNG, atau WebP.',
      );
    }

    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        selectedPhotoBytes!,
        filename: originalName,
        contentType: http.MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload Cloudinary gagal: ${response.body}');
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    final photoUrl = responseData['secure_url'] as String?;

    if (photoUrl == null || photoUrl.isEmpty) {
      throw Exception('URL foto dari Cloudinary tidak ditemukan.');
    }

    return photoUrl;
  }

  // Menyimpan laporan ke Firestore.
  Future<void> submitReport() async {
    if (loading) return;

    if (!formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        errorMessage = 'Silakan login kembali sebelum mengirim laporan.';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final heightText = heightController.text.trim();
      final waterHeight = heightText.isEmpty ? 0 : num.parse(heightText);

      final reportRef = FirebaseFirestore.instance.collection('reports').doc();

      // Foto diunggah ke Cloudinary.
      if (selectedPhotoBytes == null || selectedPhoto == null) {
        throw Exception('Foto belum terbaca saat proses pengiriman.');
      }

      final photoUrl = await uploadPhoto();

      if (photoUrl == null || photoUrl.isEmpty) {
        throw Exception('Cloudinary tidak menghasilkan URL foto.');
      }

      // Dokumen laporan disimpan ke Firestore.
      await reportRef.set({
        'userId': user.uid,
        'userEmail': user.email,
        'location': locationController.text.trim(),
        'latitude': selectedLocation?.latitude,
        'longitude': selectedLocation?.longitude,
        'waterHeightCm': waterHeight,
        'severity': severity,
        'description': descriptionController.text.trim(),
        'photoUrl': photoUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A879),
              size: 48,
            ),
            title: const Text('Laporan terkirim'),
            content: const Text(
              'Laporan berhasil disimpan dan menunggu verifikasi. '
              'Laporan masyarakat ini belum menjadi peringatan resmi.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Gagal mengirim laporan. Periksa koneksi, '
            'Cloudinary, dan Firestore Rules.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporkan Banjir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Ceritakan kondisi di sekitarmu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berikan informasi sesuai kondisi yang kamu amati.',
              style: TextStyle(color: Colors.blueGrey, height: 1.5),
            ),

            const SizedBox(height: 24),
            const Text('Lokasi kejadian'),
            const SizedBox(height: 8),

            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                hintText: 'Alamat atau koordinat lokasi',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lokasi wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: loading || gettingLocation ? null : getCurrentLocation,
              icon: gettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                gettingLocation
                    ? 'Mengambil lokasi...'
                    : 'Gunakan Lokasi GPS Saya',
              ),
            ),

            if (selectedLocation != null) ...[
              const SizedBox(height: 8),
              Text(
                'Koordinat: '
                '${selectedLocation!.latitude.toStringAsFixed(6)}, '
                '${selectedLocation!.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),
            const Text('Foto kondisi banjir'),
            const SizedBox(height: 8),

            if (selectedPhotoBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  selectedPhotoBytes!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 44,
                    color: Colors.blueGrey,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () => pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () => pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),

            if (selectedPhotoBytes != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: loading
                    ? null
                    : () {
                        setState(() {
                          selectedPhoto = null;
                          selectedPhotoBytes = null;
                        });
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus foto'),
              ),
            ],

            const SizedBox(height: 24),
            const Text('Perkiraan tinggi air (cm)'),
            const SizedBox(height: 8),

            TextFormField(
              controller: heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Contoh: 30 (opsional)',
                prefixIcon: Icon(Icons.water_drop_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return null;
                }

                final height = num.tryParse(value.trim());

                if (height == null || height < 0) {
                  return 'Masukkan tinggi air yang valid';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),
            const Text('Kondisi banjir'),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: severity,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Rendah')),
                DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                DropdownMenuItem(value: 'high', child: Text('Tinggi')),
              ],
              onChanged: loading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => severity = value);
                      }
                    },
            ),

            const SizedBox(height: 24),
            const Text('Keterangan'),
            const SizedBox(height: 8),

            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ceritakan kondisi di lokasi...',
                border: OutlineInputBorder(),
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            const SizedBox(height: 26),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: loading ? null : submitReport,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  loading ? 'Mengunggah dan mengirim...' : 'Kirim Laporan',
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Laporan masyarakat menunggu verifikasi dan bukan '
              'pengganti peringatan resmi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}

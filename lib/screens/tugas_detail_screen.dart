import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../services/kelas_service.dart';

class TugasDetailScreen extends StatefulWidget {
  final Activity activity;
  final int idSiswa;

  const TugasDetailScreen({
    super.key,
    required this.activity,
    required this.idSiswa,
  });

  @override
  State<TugasDetailScreen> createState() => _TugasDetailScreenState();
}

class _TugasDetailScreenState extends State<TugasDetailScreen> {
  final KelasService _kelasService = KelasService();

  PlatformFile? _pickedFile;
  bool _isUploading = false;
  Map<String, dynamic>? _submissionData;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _submissionData = widget.activity.tugas;
    _fetchSubmission();
  }

  Future<void> _fetchSubmission() async {
    try {
      final response = await Supabase.instance.client
          .from('pengumpulan_tugas')
          .select()
          .eq('id_tugas', widget.activity.idActivity)
          .eq('id_siswa', widget.idSiswa)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _submissionData = response;
          _isLoadingData = false;
        });
      }
    } on PostgrestException catch (e) {
      debugPrint("Supabase error: ${e.message}");
      if (mounted) setState(() => _isLoadingData = false);
    } catch (e) {
      debugPrint("Error fetching submission: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  String _formatDate(String dateString) {
    try {
      final dt = DateTime.parse(dateString).toLocal();
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  // Fungsi hitung durasi telat
  String _calculateLateTime(DateTime? submittedAt, DateTime? deadline) {
    if (submittedAt == null || deadline == null) return "";

    if (submittedAt.isAfter(deadline)) {
      final duration = submittedAt.difference(deadline);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return "Anda telat mengirim $hours jam $minutes menit";
    } else {
      return "Tepat waktu";
    }
  }

  Future<void> openOrDownloadFile({
    required String url,
    required String filename,
  }) async {
    final uri = Uri.parse(url);
    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka file: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tugas = _submissionData;
    final hasSubmission =
        tugas != null &&
        (tugas['file_url'] != null && tugas['file_url'].toString().isNotEmpty);
    final submittedFileUrl = hasSubmission
        ? tugas['file_url'].toString()
        : null;
    final nilai = hasSubmission ? tugas['nilai'] : null;
    final feedback = hasSubmission ? tugas['feedback'] : null;
    final uploadTime = hasSubmission
        ? (tugas['updated_at'] ?? tugas['created_at'])?.toString()
        : null;
    final fileSoal = (widget.activity.tugas != null)
        ? (widget.activity.tugas!['file_path'] ??
                  widget.activity.tugas!['file_tugas'])
              ?.toString()
        : null;

    // Hitung status telat jika ada submission
    DateTime? submittedAt = hasSubmission
        ? DateTime.tryParse(tugas['created_at'] ?? tugas['updated_at'] ?? "")
        : null;
    DateTime? deadline = widget.activity.deadline;

    String lateStatus = "";
    Color lateColor = Colors.grey;
    if (hasSubmission && deadline != null && submittedAt != null) {
      lateStatus = _calculateLateTime(submittedAt, deadline);
      if (lateStatus.startsWith("Anda telat")) {
        lateColor = Colors.red[800]!;
      } else {
        lateColor = Colors.green[800]!;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.judul),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSubmission,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.activity.deskripsi,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (widget.activity.deadline != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.red[800]),
                      const SizedBox(width: 8),
                      Text(
                        'Deadline: ${widget.activity.deadline!.toLocal()}',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (fileSoal != null && fileSoal.isNotEmpty) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.description),
                  label: const Text('Lihat Soal'),
                  onPressed: () =>
                      openOrDownloadFile(url: fileSoal, filename: 'Soal'),
                ),
                const SizedBox(height: 20),
              ],
              const Divider(thickness: 1),
              const SizedBox(height: 20),
              if (_isLoadingData && _submissionData == null)
                const Center(child: CircularProgressIndicator())
              else if (hasSubmission)
                _buildSubmittedView(
                  submittedFileUrl!,
                  uploadTime,
                  nilai,
                  feedback,
                  lateStatus,
                  lateColor,
                )
              else
                _buildUploadForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kirim Tugas Kamu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Silakan upload file jawaban (PDF/DOC/DOCX).',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.centerLeft,
                ),
                icon: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.attach_file),
                ),
                label: Text(
                  _pickedFile?.name ?? 'Pilih file...',
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _isUploading ? null : _pickFile,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
              onPressed: (_pickedFile == null || _isUploading)
                  ? null
                  : _handleUpload,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kirim'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmittedView(
    String fileUrl,
    String? time,
    dynamic nilai,
    dynamic feedback,
    String lateStatus,
    Color lateColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Status Pengumpulan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tugas Berhasil Dikirim",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fileUrl.split('/').last,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (time != null)
                          Text(
                            "Waktu: ${_formatDate(time)}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        if (lateStatus.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            lateStatus,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: lateColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Ganti File"),
                    onPressed: _pickAndReupload,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text("Lihat File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                    onPressed: () => openOrDownloadFile(
                      url: fileUrl,
                      filename: 'Tugas Saya',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (nilai != null || feedback != null)
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "NILAI",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nilai?.toString() ?? "-",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Feedback Guru:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(feedback?.toString() ?? "Belum ada feedback."),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'csv'],
        withData: true,
      );
      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal pilih file: $e")));
    }
  }

  Future<void> _pickAndReupload() async {
    await _pickFile();
    if (_pickedFile != null) {
      await _handleUpload();
    }
  }

  Future<void> _handleUpload() async {
    if (_pickedFile?.bytes == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = _pickedFile!.bytes!;
      final filename = _pickedFile!.name;
      final sanitizedFilename = filename.replaceAll(RegExp(r'[^\w\.-]+'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      final ownerFolder = authUserId ?? widget.idSiswa.toString();
      final storagePath =
          'private/$ownerFolder/submissions/${widget.activity.idActivity}/${timestamp}_$sanitizedFilename';

      final uploadResult = await _kelasService.uploadFileBytes(
        bucket: 'tugas',
        path: storagePath,
        bytes: bytes,
        filename: sanitizedFilename,
      );
      if (uploadResult['ok'] != true) throw uploadResult['message'];

      final publicUrl = await _kelasService.getFileUrlOrSigned(
        bucket: 'tugas',
        path: storagePath,
      );
      final submitResult = await _kelasService.submitTugasRecord(
        idActivity: widget.activity.idActivity,
        filePath: publicUrl ?? storagePath,
        idSiswa: widget.idSiswa,
      );

      if (submitResult['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tugas berhasil dikirim!')),
        );
        setState(() {
          _pickedFile = null;
          _isUploading = false;
        });
        await _fetchSubmission();
      } else {
        throw submitResult['message'];
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal Upload: $e')));
      setState(() {
        _isUploading = false;
      });
    }
  }
}

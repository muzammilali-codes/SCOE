import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_selector/file_selector.dart';

class UploadMarksScreen extends StatefulWidget {
  const UploadMarksScreen({super.key});

  @override
  State<UploadMarksScreen> createState() => _UploadMarksScreenState();
}

class _UploadMarksScreenState extends State<UploadMarksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _markController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _chapterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markController.addListener(() => setState(() {}));
    _fetchSubjectsForBranch();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _markController.dispose();
    _totalMarksController.dispose();
    _linkController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  // States
  String _selectedSem = '1';
  String _selectedSubject = '';
  String _selectedYear = '2025';
  String _selectedMonth = '01';
  String _teacherBranch = '';

  final List<Map<String, String>> _students = [];
  final List<String> _driveLinks = [];

  final List<String> _semOptions = ['1', '2', '3', '4','5','6','7','8'];
  List<String> _subjectOptions = [];
  final List<String> _yearOptions = ['2025', '2026', '2027', '2028'];
  final List<String> _monthOptions = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));

  // Colors
  final Color PrimaryColor = const Color(0xFF006400);
  final Color PrimaryLight = const Color(0xFF4CAF50);
  final Color PrimaryDark = const Color(0xFF1B5E20);
  final Color SecondaryColor = const Color(0xFF2196F3);
  final Color BackgroundColor = const Color(0xFFF8F9FA);
  final Color SurfaceColor = const Color(0xFFFFFFFF);
  final Color ErrorColor = const Color(0xFFB00020);
  final Color OnPrimary = const Color(0xFFFFFFFF);
  final Color OnSurface = const Color(0xFF212121);

  // Fetch subjects for the teacher's branch
  Future<void> _fetchSubjectsForBranch() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final teacherDoc = await _firestore.collection('users').doc(user.uid).get();
      final branch = teacherDoc.data()?['branch'] ?? '';

      if (branch.isEmpty) {
        _showSnackBar('No branch found for this teacher', isError: true);
        return;
      }

      _teacherBranch = branch;

      final branchDoc = await _firestore.collection('branch').doc(branch).get();
      final subjects = branchDoc.data()?['subjects'] ?? [];

      setState(() {
        _subjectOptions = List<String>.from(subjects);
        if (_subjectOptions.isNotEmpty) _selectedSubject = _subjectOptions.first;
      });
    } catch (e) {
      _showSnackBar('Error loading subjects: $e', isError: true);
    }
  }

  double _calculatePercentage(String mark) {
    final m = double.tryParse(mark) ?? 0;
    final t = double.tryParse(_totalMarksController.text) ?? 1;
    return t == 0 ? 0 : (m / t) * 100;
  }

  void _addStudent() {
    final chapter = _chapterController.text.trim();
    final totalMarks = _totalMarksController.text.trim();
    final name = _nameController.text.trim();
    final mark = _markController.text.trim();

    if (chapter.isEmpty || totalMarks.isEmpty) {
      _showSnackBar('Enter chapter and total marks first', isError: true);
      return;
    }
    if (name.isEmpty || mark.isEmpty) {
      _showSnackBar('Enter student name and mark', isError: true);
      return;
    }

    final percent = _calculatePercentage(mark).toStringAsFixed(2);
    _students.add({'name': name, 'mark': mark, 'percent': percent});
    _nameController.clear();
    _markController.clear();
    setState(() {});
  }

  Future<void> _pickFile() async {
    try {
      final typeGroup = XTypeGroup(label: 'any', extensions: ['*']);
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null && mounted) {
        _showSnackBar('Upload your file in Drive and copy the link manually');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error picking file: $e', isError: true);
    }
  }

  Future<void> _openDrive() async {
    final Uri webUri = Uri.parse('https://drive.google.com/drive/my-drive');
    try {
      final bool launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (!launched) _showSnackBar('Could not open Google Drive.', isError: true);
    } catch (e) {
      _showSnackBar('Error opening Drive: $e', isError: true);
    }
  }

  Future<void> _uploadMarks() async {
    if (_students.isEmpty) {
      _showSnackBar('Add at least one student', isError: true);
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar('User not authenticated', isError: true);
      return;
    }

    _showLoadingDialog();

    try {
      final uploaderName = user.displayName ?? user.email ?? 'Unknown';

      final snapshot = await _firestore
          .collection('marks')
          .where('class', isEqualTo: _selectedSem)
          .where('subject', isEqualTo: _selectedSubject)
          .where('month', isEqualTo: _selectedMonth)
          .get();

      final existingTests = snapshot.docs
          .map((e) => e['test'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList();

      final nextTestNumber = (existingTests
          .map((e) => int.tryParse(e.replaceAll('Test', '')) ?? 0)
          .fold<int>(0, (prev, e) => e > prev ? e : prev)) +
          1;

      final testName = 'Test$nextTestNumber';
      final batch = _firestore.batch();

      for (final student in _students) {
        for (final link in _driveLinks.isEmpty ? ['https://paper-black.vercel.app/'] : _driveLinks) {
          final fileId = link.contains('/d/') ? link.split('/d/')[1].split('/')[0] : '';
          final previewUrl = fileId.isNotEmpty
              ? 'https://drive.google.com/file/d/$fileId/view?usp=drivesdk'
              : link;

          final docRef = _firestore.collection('marks').doc();
          batch.set(docRef, {
            'name': student['name'],
            'link': previewUrl,
            'mark': student['mark'],
            'class': _selectedSem,
            'subject': _selectedSubject,
            'branch': _teacherBranch,
            'year': _selectedYear,
            'month': _selectedMonth,
            'test': testName,
            'chapter': _chapterController.text.trim(),
            'total': _totalMarksController.text.trim(),
            'percent': student['percent'],
            'uploadedBy': uploaderName,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog();
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Upload failed: $e', isError: true);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: SurfaceColor,
        content: Row(
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(PrimaryColor)),
            const SizedBox(width: 16),
            Text('Uploading marks...', style: TextStyle(color: OnSurface)),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _driveLinks.clear();
    _chapterController.clear();
    _totalMarksController.clear();
    _nameController.clear();
    _markController.clear();
    _linkController.clear();
    _formKey.currentState?.reset();
    _students.clear();
    setState(() {});
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? ErrorColor : PrimaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SurfaceColor,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: PrimaryColor),
            const SizedBox(width: 8),
            Text('Success', style: TextStyle(color: OnSurface, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('${_students.length} marks uploaded successfully!', style: TextStyle(color: OnSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: PrimaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFormField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    bool isExpanded = true,
  }) {
    return Container(
      width: isExpanded ? double.infinity : null,
      child: DropdownButtonFormField(
        value: value.isNotEmpty ? value : null,
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(item, style: TextStyle(color: OnSurface)),
        ))
            .toList(),
        onChanged: (val) => onChanged(val.toString()),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: BackgroundColor,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required IconData prefixIcon,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: PrimaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: BackgroundColor,
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildElevatedButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: OnPrimary),
      label: Text(text, style: TextStyle(color: OnPrimary)),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? PrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: SurfaceColor,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PrimaryDark)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        title: Text('Upload Marks', style: TextStyle(color: OnPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: PrimaryDark,
        elevation: 4,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: _subjectOptions.isEmpty
            ? Center(child: CircularProgressIndicator(color: PrimaryColor))
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Test Details Section
                _buildSection('Test Details', [
                  Row(
                    children: [
                      Expanded(child: _buildTextFormField(label: 'Chapter *', prefixIcon: Icons.book, controller: _chapterController)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextFormField(label: 'Total Marks *', prefixIcon: Icons.score, controller: _totalMarksController, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFormField(
                          label: 'Sem',
                          value: _selectedSem,
                          items: _semOptions,
                          onChanged: (val) => setState(() => _selectedSem = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownFormField(
                          label: 'Subject',
                          value: _selectedSubject,
                          items: _subjectOptions,
                          onChanged: (val) => setState(() => _selectedSubject = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFormField(
                          label: 'Year',
                          value: _selectedYear,
                          items: _yearOptions,
                          onChanged: (val) => setState(() => _selectedYear = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownFormField(
                          label: 'Month',
                          value: _selectedMonth,
                          items: _monthOptions,
                          onChanged: (val) => setState(() => _selectedMonth = val),
                        ),
                      ),
                    ],
                  ),
                ]),

                // File Management Section
                _buildSection('File Management', [
                  Row(
                    children: [
                      Expanded(child: _buildElevatedButton(text: 'Upload File', icon: Icons.cloud_upload, onPressed: _pickFile)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildElevatedButton(text: 'Open Drive', icon: Icons.folder_open, onPressed: _openDrive)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _linkController,
                          decoration: InputDecoration(
                            labelText: 'Drive Link',
                            prefixIcon: Icon(Icons.link, color: PrimaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: BackgroundColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: PrimaryColor, borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                          icon: Icon(Icons.add, color: OnPrimary),
                          onPressed: () {
                            if (_linkController.text.isNotEmpty) {
                              _driveLinks.add(_linkController.text.trim());
                              _linkController.clear();
                              setState(() {});
                              _showSnackBar('Drive link added successfully');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_driveLinks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Added links: ${_driveLinks.length}', style: TextStyle(color: PrimaryDark)),
                    ),
                ]),

                // Student Marks Section
                _buildSection('Student Marks', [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Student Name *",
                      prefixIcon: Icon(Icons.person, color: PrimaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: BackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _markController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Marks *",
                            prefixIcon: Icon(Icons.score, color: PrimaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: BackgroundColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: PrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PrimaryColor.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Percentage", style: TextStyle(color: PrimaryColor, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text("${_calculatePercentage(_markController.text).toStringAsFixed(1)}%",
                                    style: TextStyle(color: PrimaryDark, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.add, color: OnPrimary),
                      label: Text('Add Student', style: TextStyle(color: OnPrimary)),
                      style: ElevatedButton.styleFrom(backgroundColor: PrimaryColor),
                      onPressed: _addStudent,
                    ),
                  ),
                  if (_students.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return ListTile(
                          title: Text(student['name'] ?? ''),
                          subtitle: Text("Marks: ${student['mark']}, Percent: ${student['percent']}%"),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: ErrorColor),
                            onPressed: () => setState(() => _students.removeAt(index)),
                          ),
                        );
                      },
                    ),
                ]),

                const SizedBox(height: 20),
                _buildElevatedButton(
                  text: 'Upload All Marks (${_students.length})',
                  icon: Icons.cloud_upload,
                  onPressed: _uploadMarks,
                  backgroundColor: PrimaryColor,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

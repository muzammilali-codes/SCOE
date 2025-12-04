// marklist_screen.dart
import 'dart:io' show File, Directory, Platform, exit;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_file/open_file.dart';

class StudentMarks {
  final String name;
  final String marks;
  final String link;
  final String id;
  final String studentClass;
  final String subject;
  final String year;
  final String month;
  final String chapter;
  final String total;
  final String percentage;

  StudentMarks({
    required this.name,
    required this.marks,
    required this.link,
    required this.id,
    required this.studentClass,
    required this.subject,
    required this.year,
    required this.month,
    required this.chapter,
    required this.total,
    required this.percentage,
  });

  factory StudentMarks.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentMarks(
      name: (data['name'] ?? '') as String,
      marks: (data['mark'] ?? '') as String,
      link: (data['link'] ?? '') as String,
      id: doc.id,
      studentClass: (data['class'] ?? '') as String,
      subject: (data['subject'] ?? '') as String,
      year: (data['year'] ?? '') as String,
      month: (data['month'] ?? '') as String,
      chapter: (data['chapter'] ?? '') as String,
      total: (data['total'] ?? '') as String,
      percentage: (data['percent'] ?? '') as String,
    );
  }

  StudentMarks copyWith({
    String? name,
    String? marks,
    String? link,
    String? total,
    String? percentage,
  }) {
    return StudentMarks(
      name: name ?? this.name,
      marks: marks ?? this.marks,
      link: link ?? this.link,
      id: id,
      studentClass: studentClass,
      subject: subject,
      year: year,
      month: month,
      chapter: chapter,
      total: total ?? this.total,
      percentage: percentage ?? this.percentage,
    );
  }
}

class MarkListScreen extends StatefulWidget {
  const MarkListScreen({Key? key}) : super(key: key);

  @override
  State<MarkListScreen> createState() => _MarkListScreenState();
}

class _MarkListScreenState extends State<MarkListScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<StudentMarks> marksList = [];
  bool isLoading = true;
  String? _teacherBranch;

  // Filters
  String? selectedClass;
  String? selectedSubject;
  String? selectedYear;
  String? selectedMonth;

  // Edit states
  StudentMarks? editingStudent;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController marksCtrl = TextEditingController();
  final TextEditingController linkCtrl = TextEditingController();
  final TextEditingController totalCtrl = TextEditingController();
  final TextEditingController percentCtrl = TextEditingController();

  Color primaryGreen = const Color(0xFF006400);
  Color lightGreen = const Color(0xFFE8F5E8);
  Color darkGreen = const Color(0xFF004D00);

  @override
  void initState() {
    super.initState();
    _loadTeacherBranchAndMarks();
  }

  Future<void> _loadTeacherBranchAndMarks() async {
    setState(() => isLoading = true);
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      _teacherBranch = userDoc.data()?['branch'] ?? '';

      await _fetchMarks();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching branch: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchMarks() async {
    if (_teacherBranch == null) return;
    setState(() => isLoading = true);
    try {
      final snapshot = await firestore
          .collection('marks')
          .where('branch', isEqualTo: _teacherBranch)
          .get();
      final temp = snapshot.docs.map((d) => StudentMarks.fromDoc(d)).toList();
      setState(() {
        marksList = temp;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching marks: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<StudentMarks> get _filteredMarks {
    return marksList.where((m) {
      final matchesClass = selectedClass == null || m.studentClass == selectedClass;
      final matchesSubject = selectedSubject == null || m.subject == selectedSubject;
      final matchesYear = selectedYear == null || m.year == selectedYear;
      final matchesMonth = selectedMonth == null || m.month == selectedMonth;
      return matchesClass && matchesSubject && matchesYear && matchesMonth;
    }).toList();
  }

  Future<void> _deleteStudent(StudentMarks s) async {
    try {
      await firestore.collection('marks').doc(s.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully'), backgroundColor: Colors.red)
      );
      setState(() {
        marksList = List.from(marksList)..removeWhere((m) => m.id == s.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _saveEditedStudent() async {
    if (editingStudent == null) return;
    final updated = {
      'name': nameCtrl.text.trim(),
      'mark': marksCtrl.text.trim(),
      'link': linkCtrl.text.trim(),
      'total': totalCtrl.text.trim(),
      'percent': percentCtrl.text.trim(),
      'secretKey': 'admin123',
      'branch': _teacherBranch,
    };
    await firestore.collection('marks').doc(editingStudent!.id).set(updated);
    setState(() {
      marksList = marksList.map((m) {
        if (m.id == editingStudent!.id) {
          return m.copyWith(
            name: updated['name'] as String,
            marks: updated['mark'] as String,
            link: updated['link'] as String,
            total: updated['total'] as String,
            percentage: updated['percent'] as String,
          );
        }
        return m;
      }).toList();
      editingStudent = null;
    });
  }

  // ---------------- URL OPEN ----------------
  void openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link'))
      );
    }
  }

  // ---------------- FILE PATH / OPEN ----------------
  Future<String> _getSavePath(String fileName) async {
    if (kIsWeb) {
      throw Exception('File export not supported on web');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dir = Directory.current;
      return '${dir.path}/$fileName';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/$fileName';
    }
  }

  Future<void> _openFile(File file) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved at: ${file.path}'), backgroundColor: Colors.green)
      );
    } else {
      await OpenFile.open(file.path);
    }
  }

  // ---------------- EXPORT EXCEL ----------------
  Future<void> createMarksExcel(List<StudentMarks> marks, String instituteName) async {
    if (marks.isEmpty) return;
    final excel = Excel.createExcel();
    final sheet = excel['Marks'];
    sheet.appendRow(['Name','Sem','Subject','Year','Month','Chapter','Marks','Total','Percentage','Link']);
    for (var m in marks) {
      sheet.appendRow([m.name,m.studentClass,m.subject,m.year,m.month,m.chapter,m.marks,m.total,m.percentage,m.link]);
    }

    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '$instituteName-Filtered-Marks-$timestamp.xlsx';
      final path = await _getSavePath(fileName);
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final file = File(path);
        await file.writeAsBytes(fileBytes);
        await _openFile(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating Excel: $e'), backgroundColor: Colors.red));
    }
  }

  // ---------------- EXPORT PDF ----------------
  Future<void> createMarksPDF(List<StudentMarks> marks, String instituteName) async {
    if (marks.isEmpty) return;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('$instituteName - Student Marks', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Name','Class','Subject','Year','Month','Marks','Total','Percentage'],
                  ...marks.map((m) => [m.name,m.studentClass,m.subject,m.year,m.month,m.marks,m.total,'${m.percentage}%']),
                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '$instituteName-Marks-Report-$timestamp.pdf';
      final path = await _getSavePath(fileName);
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      await _openFile(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating PDF: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportFiles() async => await createMarksExcel(_filteredMarks, 'Technical Institute');
  Future<void> _exportPDF() async => await createMarksPDF(_filteredMarks, 'Technical Institute');

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMarks;
    return Scaffold(
      backgroundColor: lightGreen,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchMarks,
              color: primaryGreen,
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  _buildFilters(),
                  const SizedBox(height: 10),
                  if (isLoading)
                    Center(child: CircularProgressIndicator(color: primaryGreen))
                  else if (filtered.isEmpty)
                    Center(child: Text('No marks found', style: TextStyle(color: primaryGreen, fontSize: 18)))
                  else
                    Column(
                      children: [
                        ...filtered.map((s) => ModernStudentMarksCard(
                          student: s,
                          onEditClick: () {
                            editingStudent = s;
                            nameCtrl.text = s.name;
                            marksCtrl.text = s.marks;
                            linkCtrl.text = s.link;
                            totalCtrl.text = s.total;
                            percentCtrl.text = s.percentage;
                            _showEditDialog();
                          },
                          onDeleteClick: () async => await _deleteStudent(s),
                          onLinkClick: () => openLink(s.link),
                        )),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: ElevatedButton.icon(
                              onPressed: _exportFiles,
                              icon: const Icon(Icons.download),
                              label: const Text('Excel'),
                              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton.icon(
                              onPressed: _exportPDF,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('PDF'),
                              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                            )),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [darkGreen, primaryGreen]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Icon(Icons.assessment, size: 32, color: Colors.white)),
            const SizedBox(width: 16),
    /*        ElevatedButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  if (Platform.isWindows) {
                    exit(0); // closes app on Windows
                  }
                }
              },
              child: const Text("Go Back"),
            ),*/
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Marks Management', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('View and manage student marks', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
            ]))
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(_teacherBranch ?? 'Loading branch...', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditTextField(nameCtrl, 'Student Name', Icons.person),
              _buildEditTextField(marksCtrl, 'Marks', Icons.score, TextInputType.number),
              _buildEditTextField(totalCtrl, 'Total Marks', Icons.summarize, TextInputType.number),
              _buildEditTextField(percentCtrl, 'Percentage', Icons.percent, TextInputType.number),
              _buildEditTextField(linkCtrl, 'Paper Link', Icons.link),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () { Navigator.of(ctx).pop(); editingStudent = null; }, child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: () async { Navigator.of(ctx).pop(); await _saveEditedStudent(); }, child: const Text('Save Changes'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType]) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildFilters() {
    final classOptions = ['1','2','3','4','5','6','7','8'];
    final subjectOptions = marksList
        .where((m) => m.studentClass == selectedClass || selectedClass == null)
        .map((m) => m.subject)
        .toSet()
        .toList();
    final months = [
      'January','February','March','April','May','June','July','August',
      'September','October','November','December'
    ];
    final years = ['2024','2025','2026'];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: const [Icon(Icons.filter_alt), SizedBox(width: 8), Text('FILTER MARKS')]),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [null, ...classOptions].map((e) => DropdownMenuItem(value: e, child: Text(e ?? 'All'))).toList(),
                  onChanged: (v) => setState(() => selectedClass = v),
                )),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: [null, ...subjectOptions].map((e) => DropdownMenuItem(value: e, child: Text(e ?? 'All'))).toList(),
                  onChanged: (v) => setState(() => selectedSubject = v),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: [null, ...months].map((e) => DropdownMenuItem(value: e, child: Text(e ?? 'All'))).toList(),
                  onChanged: (v) => setState(() => selectedMonth = v),
                )),
                const SizedBox(width: 12),
                Expanded(child: DropdownButtonFormField<String>(
                  value: selectedYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: [null, ...years].map((e) => DropdownMenuItem(value: e, child: Text(e ?? 'All'))).toList(),
                  onChanged: (v) => setState(() => selectedYear = v),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- MODERN CARD ----------------
class ModernStudentMarksCard extends StatelessWidget {
  final StudentMarks student;
  final VoidCallback onEditClick;
  final VoidCallback onDeleteClick;
  final VoidCallback onLinkClick;

  const ModernStudentMarksCard({
    Key? key,
    required this.student,
    required this.onEditClick,
    required this.onDeleteClick,
    required this.onLinkClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Marks: ${student.marks}/${student.total} (${student.percentage}%)'),
            Text('Class: ${student.studentClass}, Subject: ${student.subject}'),
            Text('Month/Year: ${student.month}/${student.year}, Chapter: ${student.chapter}'),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(icon: const Icon(Icons.link, color: Colors.blue), onPressed: onLinkClick),
            IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: onEditClick),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDeleteClick),
          ],
        ),
      ),
    );
  }
}

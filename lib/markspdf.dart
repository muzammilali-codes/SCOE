import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:SCOE/mark.dart';

Future<void> createMarksExcel(List<StudentMarks> marks, String instituteName) async {
  if (marks.isEmpty) return;

  // Create Excel
  final excel = Excel.createExcel();
  final sheet = excel['Marks'];

  // Add header row
  sheet.appendRow([
    'Name', 'Class', 'Subject', 'Year', 'Month', 'Chapter', 'Marks', 'Total', 'Percentage', 'Link'
  ]);

  // Add data rows
  for (var m in marks) {
    sheet.appendRow([
      m.name,
      m.studentClass,
      m.subject,
      m.year,
      m.month,
      m.chapter,
      m.marks,
      m.total,
      m.percentage,
      m.link
    ]);
  }

  try {
    // Get Documents directory
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$instituteName-Filtered-Marks.xlsx';

    // Save file
    final fileBytes = excel.encode();
    final file = File(path);
    await file.writeAsBytes(fileBytes!);

    // Open automatically
    await OpenFile.open(file.path);
  } catch (e) {
    print('Error creating Excel: $e');
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cross_file/cross_file.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LaporanScreen extends StatefulWidget {
  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  String _filter = 'mingguan';
  DateTime _now = DateTime.now();
  bool _loading = false;

  Query<Map<String, dynamic>> _getQuery() {
    DateTime start;
    if (_filter == 'mingguan') {
      start = _now.subtract(Duration(days: _now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else if (_filter == 'bulanan') {
      start = DateTime(_now.year, _now.month, 1);
    } else {
      start = DateTime(_now.year, 1, 1);
    }
    final user = FirebaseAuth.instance.currentUser;
    return FirebaseFirestore.instance
        .collection('history')
        .where('userId', isEqualTo: user?.uid)
        .where('tanggalSelesai', isGreaterThanOrEqualTo: start)
        .orderBy('tanggalSelesai', descending: true);
  }

  Future<void> _exportPDF(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    setState(() => _loading = true);
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Laporan Tugas', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: [
                  'Mata Kuliah',
                  'Deskripsi',
                  'Tanggal Tugas',
                  'Deadline',
                  'Tanggal Selesai'
                ],
                data: docs.map((doc) {
                  final data = doc.data();
                  String tanggalTugas = '-';
                  String deadline = '-';
                  String tanggalSelesai = '-';
                  if (data['tanggalTugas'] != null) {
                    final t = (data['tanggalTugas'] is Timestamp)
                        ? (data['tanggalTugas'] as Timestamp).toDate()
                        : (data['tanggalTugas'] as DateTime);
                    tanggalTugas = DateFormat('EEEE, dd MMMM yyyy', 'id').format(t);
                  }
                  if (data['deadline'] != null) {
                    final d = (data['deadline'] is Timestamp)
                        ? (data['deadline'] as Timestamp).toDate()
                        : (data['deadline'] as DateTime);
                    deadline = DateFormat('EEEE, dd MMMM yyyy', 'id').format(d);
                  }
                  if (data['tanggalSelesai'] != null) {
                    final s = (data['tanggalSelesai'] is Timestamp)
                        ? (data['tanggalSelesai'] as Timestamp).toDate()
                        : (data['tanggalSelesai'] as DateTime);
                    tanggalSelesai = DateFormat('EEEE, dd MMMM yyyy', 'id').format(s);
                  }
                  return [
                    data['nama'] ?? '',
                    data['deskripsi'] ?? '',
                    tanggalTugas,
                    deadline,
                    tanggalSelesai,
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/laporan_tugas.pdf');
    await file.writeAsBytes(await pdf.save());
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Laporan PDF berhasil diekspor: ${file.path}'),
        backgroundColor: const Color(0xFF43cea2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    await Share.shareXFiles([XFile(file.path)], text: 'Laporan Tugas PDF');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with controls
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.assessment_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Laporan Tugas',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.2),
              const SizedBox(height: 24),
              // Controls row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  // Filter dropdown
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double dropdownWidth = constraints.maxWidth < 400 ? constraints.maxWidth : 400;
                      return Container(
                        width: dropdownWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list_outlined,
                              size: 18,
                              color: const Color(0xFF43cea2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Filter:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: DropdownButton<String>(
                                value: _filter,
                                isExpanded: true,
                                underline: const SizedBox(),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF43cea2),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'mingguan',
                                    child: Row(
                                      children: [
                                        Icon(Icons.view_week_outlined, size: 16, color: Colors.blue[600]),
                                        const SizedBox(width: 8),
                                        const Text('Mingguan'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'bulanan',
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_month_outlined, size: 16, color: Colors.green[600]),
                                        const SizedBox(width: 8),
                                        const Text('Bulanan'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'tahunan',
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 16, color: Colors.orange[600]),
                                        const SizedBox(width: 8),
                                        const Text('Tahunan'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _filter = val!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                  // Export button
                  Container(
                    constraints: const BoxConstraints(minWidth: 350),
                    decoration: BoxDecoration(
                      gradient: _loading 
                          ? LinearGradient(
                              colors: [Colors.grey[400]!, Colors.grey[500]!],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _loading 
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF43cea2).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton.icon(
                      icon: _loading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      label: Text(
                        _loading ? 'Mengekspor...' : 'Ekspor PDF',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _loading
                          ? null
                          : () async {
                              final query = await _getQuery().get();
                              await _exportPDF(query.docs
                                  .cast<QueryDocumentSnapshot<Map<String, dynamic>>>());
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.2),
                ],
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data laporan',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF43cea2)),
                  ),
                );
              }
              
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assessment_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 24),
                      Text(
                        'Belum ada data laporan',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Laporan akan muncul setelah Anda menyelesaikan tugas',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: [
                  // Statistics header
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF43cea2).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Tugas Selesai',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${docs.length} Tugas',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _filter.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),
                  
                  // Task list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final data = docs[i].data();
                        String tanggalTugas = '-';
                        String deadline = '-';
                        String tanggalSelesai = '-';
                        
                        if (data['tanggalTugas'] != null) {
                          final t = (data['tanggalTugas'] is Timestamp)
                              ? (data['tanggalTugas'] as Timestamp).toDate()
                              : (data['tanggalTugas'] as DateTime);
                          tanggalTugas = DateFormat('EEEE, dd MMMM yyyy', 'id').format(t);
                        }
                        if (data['deadline'] != null) {
                          final d = (data['deadline'] is Timestamp)
                              ? (data['deadline'] as Timestamp).toDate()
                              : (data['deadline'] as DateTime);
                          deadline = DateFormat('EEEE, dd MMMM yyyy', 'id').format(d);
                        }
                        if (data['tanggalSelesai'] != null) {
                          final s = (data['tanggalSelesai'] is Timestamp)
                              ? (data['tanggalSelesai'] as Timestamp).toDate()
                              : (data['tanggalSelesai'] as DateTime);
                          tanggalSelesai = DateFormat('EEEE, dd MMMM yyyy', 'id').format(s);
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF185a9d).withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF43cea2).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Column(
                              children: [
                                // Report indicator bar
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.purple[400]!, Colors.purple[600]!],
                                    ),
                                  ),
                                ),
                                
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with report badge
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.purple[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.description_outlined,
                                              color: Colors.purple[600],
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 12, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple[50],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    'LAPORAN',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      color: Colors.purple[700],
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  data['nama'] ?? '',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF1E293B),
                                                    letterSpacing: -0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Description section
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.description_outlined,
                                                  size: 16,
                                                  color: const Color(0xFF43cea2),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Deskripsi Tugas',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: const Color(0xFF43cea2),
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              data['deskripsi'] ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: const Color(0xFF64748B),
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Date information grid
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildDateInfoCard(
                                                  title: 'Tanggal Tugas',
                                                  date: tanggalTugas,
                                                  icon: Icons.event_outlined,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildDateInfoCard(
                                                  title: 'Deadline',
                                                  date: deadline,
                                                  icon: Icons.schedule_outlined,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          _buildDateInfoCard(
                                            title: 'Diselesaikan',
                                            date: tanggalSelesai,
                                            icon: Icons.check_circle_outlined,
                                            color: Colors.green,
                                            isFullWidth: true,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: (i * 100 + 800).ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.1, curve: Curves.easeOutCubic)
                            .scale(begin: const Offset(0.95, 0.95));
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper widget untuk date info cards
  Widget _buildDateInfoCard({
    required String title,
    required String date,
    required IconData icon,
    required MaterialColor color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: color[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

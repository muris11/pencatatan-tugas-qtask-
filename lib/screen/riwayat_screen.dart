import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RiwayatScreen extends StatefulWidget {
  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  String _filter = 'mingguan';
  DateTime _now = DateTime.now();

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
        .orderBy('tanggalSelesai', descending: true)
        .limit(10);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with filter
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
                      Icons.history_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Riwayat Tugas',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.2),
              
              const SizedBox(height: 20),
              
              // Filter dropdown with modern design
              Container(
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
                    Expanded(
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
                          setState(() => _filter = val!);
                        },
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
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
                        'Gagal memuat riwayat',
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
                      Icon(Icons.history_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 24),
                      Text(
                        'Belum ada riwayat tugas',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tugas yang sudah selesai akan muncul di sini',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return NotificationListener<ScrollNotification>(
                onNotification: (scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      docs.length >= 10) {
                    // Lazy loading placeholder
                  }
                  return false;
                },
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
                      margin: const EdgeInsets.only(bottom: 20),
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
                            // Success indicator bar
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green[400]!, Colors.green[600]!],
                                ),
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with completion badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green[600],
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
                                                color: Colors.green[50],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'SELESAI',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  color: Colors.green[700],
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
                    ).animate(delay: (i * 100).ms)
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutCubic)
                        .scale(begin: const Offset(0.95, 0.95));
                  },
                ),
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
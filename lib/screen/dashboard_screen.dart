import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../auth/login_screen.dart';
import 'profile_screen.dart';
import 'riwayat_screen.dart';
import 'laporan_screen.dart';
import '../utils/task_provider.dart';

final dashboardIndexProvider = StateProvider<int>((ref) => 0);

class DashboardScreen extends ConsumerWidget {
  final void Function(bool)? onThemeToggle;
  final bool isDarkMode;
  const DashboardScreen({Key? key, this.onThemeToggle, this.isDarkMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _selectedIndex = ref.watch(dashboardIndexProvider);
    final user = FirebaseAuth.instance.currentUser;

    final pages = [
      _dashboardHome(context, ref, user),
      RiwayatScreen(),
      LaporanScreen(),
      ProfileScreen(
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "QTask",
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2),
                   
                  ],
                ),
              ),

              // Body Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: pages[_selectedIndex],
                ).animate().fadeIn(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF185a9d).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          left: 20,
                          right: 20,
                          top: 28,
                        ),
                        child: const AddTaskForm(),
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Tambah Tugas',
              ),
            )
          : null,

      // Bottom Nav modern
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          onTap: (index) =>
              ref.read(dashboardIndexProvider.notifier).state = index,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insert_chart), label: 'Laporan'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

/// ----------------------
/// Dashboard Home Section
/// ----------------------
Widget _dashboardHome(
  BuildContext context, WidgetRef ref, User? user) {
  final taskStream = FirebaseFirestore.instance
      .collection('tasks')
      .where('isDone', isEqualTo: false)
      .where('userId', isEqualTo: user?.uid)
      .orderBy('createdAt', descending: true)
      .limit(10)
      .snapshots();

  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: taskStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
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
              Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 24),
              Text(
                'Belum ada tugas aktif',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap tombol + untuk menambah tugas baru',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                ),
                borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                Icons.list_alt_outlined,
                color: Colors.white,
                size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'List Tugas',
                style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
                ),
              ),
              ],
            ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();

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
                        // Header with gradient accent
                        Container(
                          height: 4,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                            ),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row with checkbox and menu
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: false,
                                      activeColor: const Color(0xFF43cea2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (val) async {
                                        if (val == true) {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('history')
                                                .add({
                                              ...data,
                                              'isDone': true,
                                              'tanggalSelesai': DateTime.now(),
                                              'userId': user?.uid,
                                            });

                                            await FirebaseFirestore.instance
                                                .collection('tasks')
                                                .doc(doc.id)
                                                .delete();

                                            if (context.mounted) {
                                              _showAlert(context, "Berhasil",
                                                  "Tugas dipindahkan ke riwayat");
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              _showAlert(context, "Gagal",
                                                  "Gagal memindahkan tugas: $e");
                                            }
                                          }
                                        }
                                      },
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
                                            color: const Color(0xFF43cea2).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Mata Kuliah',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: const Color(0xFF43cea2),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
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
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.grey[600],
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 8,
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          _showEditDialog(context, doc.id, data);
                                        } else if (value == 'hapus') {
                                          await FirebaseFirestore.instance
                                              .collection('tasks')
                                              .doc(doc.id)
                                              .delete();
                                          if (context.mounted) {
                                            _showAlert(context, "Berhasil", "Tugas berhasil dihapus");
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18, color: Colors.blue[600]),
                                              const SizedBox(width: 12),
                                              const Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'hapus',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 18, color: Colors.red[600]),
                                              const SizedBox(width: 12),
                                              const Text('Hapus'),
                                            ],
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
                              
                              // Date information row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.blue[100]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_outlined,
                                                size: 16,
                                                color: Colors.blue[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tanggal Tugas',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: Colors.blue[600],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            data['tanggalTugas'] != null 
                                                ? DateFormat('EEEE, dd MMMM yyyy', 'id').format((data['tanggalTugas'] as Timestamp).toDate())
                                                : '-',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.orange[100]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_outlined,
                                                size: 16,
                                                color: Colors.orange[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Deadline',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: Colors.orange[600],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            data['deadline'] != null 
                                                ? DateFormat('EEEE, dd MMMM yyyy', 'id').format((data['deadline'] as Timestamp).toDate())
                                                : '-',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

/// ----------------------
/// Edit Task Dialog
/// ----------------------
void _showEditDialog(
    BuildContext context, String docId, Map<String, dynamic> data) {
  final namaController = TextEditingController(text: data['nama']);
  final deskripsiController = TextEditingController(text: data['deskripsi']);
  DateTime? tanggalTugas = (data['tanggalTugas'] as Timestamp?)?.toDate();
  DateTime? deadline = (data['deadline'] as Timestamp?)?.toDate();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 16,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFF43cea2).withOpacity(0.02),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Edit Tugas',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernTextField(
                          controller: namaController,
                          label: 'Nama Mata Kuliah',
                          icon: Icons.school_outlined,
                          hint: 'Masukkan nama mata kuliah',
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildModernTextField(
                          controller: deskripsiController,
                          label: 'Deskripsi Tugas',
                          icon: Icons.description_outlined,
                          hint: 'Masukkan deskripsi tugas',
                          maxLines: 3,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateCard(
                                title: 'Tanggal Tugas',
                                date: tanggalTugas,
                                icon: Icons.event_outlined,
                                color: Colors.blue,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: tanggalTugas ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF43cea2),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => tanggalTugas = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateCard(
                                title: 'Deadline',
                                date: deadline,
                                icon: Icons.schedule_outlined,
                                color: Colors.orange,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: deadline ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF43cea2),
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => deadline = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(color: Color(0xFF43cea2)),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF43cea2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('tasks')
                                  .doc(docId)
                                  .update({
                                'nama': namaController.text,
                                'deskripsi': deskripsiController.text,
                                'tanggalTugas': tanggalTugas,
                                'deadline': deadline,
                              });
                              Navigator.pop(context);
                              if (context.mounted) {
                                _showAlert(context, "Berhasil", "Tugas berhasil diperbarui");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF43cea2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Simpan',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate()
              .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 200.ms);
        },
      );
    },
  );
}

/// ----------------------
/// Add Task Form
/// ----------------------
class AddTaskForm extends ConsumerStatefulWidget {
  const AddTaskForm({Key? key}) : super(key: key);

  @override
  ConsumerState<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends ConsumerState<AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  DateTime? _tanggalTugas;
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    Icons.add_task_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Tambah Tugas Baru',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ).animate().fadeIn().slideX(begin: -0.2),
            
            const SizedBox(height: 32),

            _buildModernTextField(
              controller: _namaController,
              label: 'Nama Mata Kuliah',
              icon: Icons.school_outlined,
              hint: 'Contoh: Algoritma dan Struktur Data',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Wajib diisi' : null,
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 24),

            _buildModernTextField(
              controller: _deskripsiController,
              label: 'Deskripsi Tugas',
              icon: Icons.description_outlined,
              hint: 'Jelaskan detail tugas yang harus dikerjakan',
              maxLines: 4,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Wajib diisi' : null,
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 28),

            Text(
              'Jadwal Tugas',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ).animate(delay: 600.ms).fadeIn(),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDateCard(
                    title: 'Tanggal Tugas',
                    date: _tanggalTugas,
                    icon: Icons.event_outlined,
                    color: Colors.blue,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF43cea2),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _tanggalTugas = picked);
                      }
                    },
                  ).animate(delay: 800.ms).fadeIn().slideX(begin: -0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateCard(
                    title: 'Deadline',
                    date: _deadline,
                    icon: Icons.schedule_outlined,
                    color: Colors.orange,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF43cea2),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _deadline = picked);
                      }
                    },
                  ).animate(delay: 1000.ms).fadeIn().slideX(begin: 0.2),
                ),
              ],
            ),

            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
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
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_formKey.currentState!.validate() &&
                      _tanggalTugas != null &&
                      _deadline != null) {
                    setState(() => _isLoading = true);
                    
                    final user = FirebaseAuth.instance.currentUser;
                    final result = await ref.read(taskProvider.notifier).addTask(
                          nama: _namaController.text,
                          deskripsi: _deskripsiController.text,
                          tanggalTugas: _tanggalTugas!,
                          deadline: _deadline!,
                          userId: user?.uid,
                        );
                        
                    setState(() => _isLoading = false);
                    
                    if (result == null) {
                      if (context.mounted) {
                        Navigator.pop(context); // tutup modal lebih dulu
                        _showAlert(context, "Berhasil", "Tugas berhasil ditambahkan");
                      }
                    } else {
                      if (context.mounted) {
                        _showAlert(context, "Gagal", "Gagal menambah tugas: $result");
                      }
                    }
                  } else {
                    if (context.mounted) {
                      _showAlert(context, "Validasi", "Semua field wajib diisi");
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.save_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Simpan Tugas',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate(delay: 1200.ms)
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// ----------------------
/// Modern TextField Widget
/// ----------------------
Widget _buildModernTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required String hint,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF43cea2),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF43cea2), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red[400]!),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    ],
  );
}

/// ----------------------
/// Date Card Widget
/// ----------------------
Widget _buildDateCard({
  required String title,
  required DateTime? date,
  required IconData icon,
  required MaterialColor color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: date != null ? color[200]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: date != null ? color[600] : Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: date != null ? color[600] : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date != null
                ? DateFormat('EEEE, dd MMMM yyyy', 'id').format(date)
                : 'Pilih tanggal',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: date != null ? const Color(0xFF1E293B) : Colors.grey[500],
            ),
          ),
          if (date == null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Wajib diisi',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[700],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// ----------------------
/// Alert Helper
/// ----------------------
void _showAlert(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF43cea2).withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                title == "Berhasil" ? Icons.check_circle_outline : Icons.info_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "OK",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms)
        .fadeIn(duration: 200.ms),
  );
}
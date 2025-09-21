import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

final taskProvider = StateNotifierProvider<TaskNotifier, List<Map<String, dynamic>>>((ref) => TaskNotifier());

class TaskNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  Future<String?> completeTask(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('history').add({
        ...data,
        'isDone': true,
        'tanggalSelesai': DateTime.now(),
        'userId': user?.uid,
      });
      // Hapus dari tasks
      if (data['id'] != null) {
        await FirebaseFirestore.instance.collection('tasks').doc(data['id']).delete();
      }
      // Refresh state jika perlu
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  TaskNotifier() : super([]);

  Future<String?> addTask({
    required String nama,
    required String deskripsi,
    required DateTime tanggalTugas,
    required DateTime deadline,
    required String? userId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'nama': nama,
        'deskripsi': deskripsi,
        'tanggalTugas': tanggalTugas,
        'deadline': deadline,
        'createdAt': DateTime.now(),
        'isDone': false,
        'userId': userId,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ...existing code for fetching, updating, pagination, etc...
}

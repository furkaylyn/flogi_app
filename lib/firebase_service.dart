import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı durumu
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Giriş yapma
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Kayıt olma
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    print('Firebase kayıt başlıyor: $email');
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    print('Firebase kayıt tamamlandı: ${userCredential.user?.email}');
    return userCredential;
  }

  // Çıkış yapma
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Gelir/Gider işlemleri
  Future<void> addGelirGider(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gelir_gider')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getGelirGider() async {
    final user = currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gelir_gider')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }
    return [];
  }

  Future<void> updateGelirGider(String id, Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gelir_gider')
          .doc(id)
          .update(data);
    }
  }

  Future<void> deleteGelirGider(String id) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gelir_gider')
          .doc(id)
          .delete();
    }
  }

  // Müşteri işlemleri
  Future<void> addMusteri(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('musteriler')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getMusteriler() async {
    final user = currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('musteriler')
          .orderBy('ad')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }
    return [];
  }

  Future<void> updateMusteri(String id, Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('musteriler')
          .doc(id)
          .update(data);
    }
  }

  Future<void> deleteMusteri(String id) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('musteriler')
          .doc(id)
          .delete();
    }
  }

  // Fatura işlemleri
  Future<void> addFatura(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('faturalar')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getFaturalar() async {
    final user = currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('faturalar')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }
    return [];
  }

  Future<void> updateFatura(String id, Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('faturalar')
          .doc(id)
          .update(data);
    }
  }

  Future<void> deleteFatura(String id) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('faturalar')
          .doc(id)
          .delete();
    }
  }

  // Ürün/Hizmet işlemleri
  Future<void> addUrunHizmet(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('urun_hizmet')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getUrunHizmet() async {
    final user = currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('urun_hizmet')
          .orderBy('ad')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }
    return [];
  }

  Future<void> updateUrunHizmet(String id, Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('urun_hizmet')
          .doc(id)
          .update(data);
    }
  }

  Future<void> deleteUrunHizmet(String id) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('urun_hizmet')
          .doc(id)
          .delete();
    }
  }

  // Kasa/Banka işlemleri
  Future<void> addKasaBanka(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('kasa_banka')
          .add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getKasaBanka() async {
    final user = currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('kasa_banka')
          .orderBy('hesap_adi')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    }
    return [];
  }

  Future<void> updateKasaBanka(String id, Map<String, dynamic> data) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('kasa_banka')
          .doc(id)
          .update(data);
    }
  }

  Future<void> deleteKasaBanka(String id) async {
    final user = currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('kasa_banka')
          .doc(id)
          .delete();
    }
  }

  // Raporlama için özel sorgular
  Future<double> getGelirToplami() async {
    final user = currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gelir_gider')
          .where('tur', isEqualTo: 'Gelir')
          .get();
      
      double toplam = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        toplam += (data['miktar'] ?? 0).toDouble();
      }
      return toplam;
    }
    return 0.0;
  }

  Future<double> getGiderToplami() async {
    final user = currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('gelir_gider')
          .where('tur', isEqualTo: 'Gider')
          .get();
      
      double toplam = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        toplam += (data['miktar'] ?? 0).toDouble();
      }
      return toplam;
    }
    return 0.0;
  }
} 
import 'dart:io';

import 'package:fluency/features/collection/domain/entities/collection.dart';
import 'package:fluency/features/collection/domain/entities/term.dart';

abstract class CollectionRepository {
  /// Lấy tất cả collections
  Future<List<Collection>> getCollections();

  /// Lấy một collection theo ID
  Future<Collection?> getCollection(String id);

  /// Tạo collection mới
  Future<Collection> createCollection(String name, String? description);

  /// Cập nhật collection
  Future<void> updateCollection(Collection collection);

  /// Xóa collection
  Future<void> deleteCollection(String id);

  /// Thêm term vào collection
  Future<void> addTermToCollection(String collectionId, Term term);

  /// Xóa term khỏi collection
  Future<void> removeTermFromCollection(String collectionId, String termId);

  /// Cập nhật mastery status của term
  Future<void> updateTermMastery(
    String collectionId,
    String termId,
    bool isMastered,
  );

  /// Import collection từ file (CSV, Excel, etc.)
  Future<Collection> importCollection(File file);

  /// Export collection ra file
  Future<File> exportCollection(String collectionId);

  /// Kiểm tra xem term đã có trong collection chưa
  Future<bool> isTermInCollection(String collectionId, String term);
}

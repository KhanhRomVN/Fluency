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

  /// Cập nhật tiến độ của term (0.0 đến 1.0)
  Future<void> updateTermProgress(
    String collectionId,
    String termId,
    double progress,
  );

  /// Import collection từ file (CSV, Excel, etc.)
  Future<Collection> importCollection(File file);

  /// Export collection ra file
  Future<File> exportCollection(String collectionId);

  /// Kiểm tra xem term đã có trong collection chưa
  Future<bool> isTermInCollection(String collectionId, String term);

  /// Kiểm tra xem term đã có trong bất kỳ collection nào chưa
  Future<bool> isTermInAnyCollection(String term);
}

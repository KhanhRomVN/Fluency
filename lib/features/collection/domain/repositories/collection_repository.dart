import '../entities/collection_item.dart';

abstract class CollectionRepository {
  Future<List<CollectionItem>> getItems();
  Future<void> saveItem(CollectionItem item);
  Future<void> deleteItem(String id);
  Future<CollectionItem?> fetchWord(String word);
}

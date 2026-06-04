import '../../models/pandit_model.dart';

abstract class PanditRepository {
  Future<List<PanditModel>> getActivePandits();
}

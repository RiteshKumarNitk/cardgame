import 'package:flutter_bloc/flutter_bloc.dart';

import 'ads_service.dart';

/// Whether ads are removed, live across the whole app — state is just
/// that one bool.
class AdsCubit extends Cubit<bool> {
  AdsCubit(this._service) : super(_service.adsRemoved);

  final AdsService _service;

  Future<void> purchaseRemoveAds() async {
    if (state) return;
    await _service.removeAds();
    emit(true);
  }
}

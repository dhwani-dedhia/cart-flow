import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'network_info.dart';

enum NetworkStatus { checking, online, offline }

class NetworkState extends Equatable {
  final NetworkStatus status;

  const NetworkState({this.status = NetworkStatus.checking});

  bool get isOnline => status == NetworkStatus.online;
  bool get isOffline => status == NetworkStatus.offline;

  NetworkState copyWith({NetworkStatus? status}) {
    return NetworkState(status: status ?? this.status);
  }

  @override
  List<Object?> get props => [status];
}

class NetworkCubit extends Cubit<NetworkState> {
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _subscription;

  NetworkCubit({required NetworkInfo networkInfo})
      : _networkInfo = networkInfo,
        super(const NetworkState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final connected = await _networkInfo.isConnected;
    emit(NetworkState(
      status: connected ? NetworkStatus.online : NetworkStatus.offline,
    ));

    _subscription = _networkInfo.onConnectivityChanged.listen((connected) {
      emit(NetworkState(
        status: connected ? NetworkStatus.online : NetworkStatus.offline,
      ));
    });
  }

  Future<void> checkConnectivity() async {
    final connected = await _networkInfo.isConnected;
    emit(state.copyWith(
      status: connected ? NetworkStatus.online : NetworkStatus.offline,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

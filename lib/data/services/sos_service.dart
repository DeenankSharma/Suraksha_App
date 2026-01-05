import 'package:flutter_setup/bloc/home_bloc.dart';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  HomeBloc? _homeBloc;
  void setHomeBloc(HomeBloc homeBloc) {
    _homeBloc = homeBloc;
  }

  void triggerSOS() {
    if (_homeBloc != null) {
      print('SOS Service: Triggering emergency SOS');
      _homeBloc!.add(HelpButtonClickedEvent());
    } else {
      print('SOS Service: HomeBloc not set, cannot trigger SOS');
    }
  }
}


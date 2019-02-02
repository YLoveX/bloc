import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import './weather.dart';

abstract class WeatherEvent extends Equatable {
  WeatherEvent([List props = const []]) : super(props);
}

class FetchWeather extends WeatherEvent {
  final String location;

  FetchWeather(this.location) : super([location]);
}

class RefreshWeather extends WeatherEvent {
  final int locationId;

  RefreshWeather(this.locationId) : super([locationId]);
}

abstract class WeatherState extends Equatable {
  WeatherState([List props = const []]) : super(props);
}

class WeatherEmpty extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final Weather weather;

  WeatherLoaded(this.weather) : super([weather]);
}

class WeatherError extends WeatherState {}

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final http.Client httpClient;

  WeatherBloc({this.httpClient});

  @override
  void onTransition(Transition<WeatherEvent, WeatherState> transition) {
    print(transition);
  }

  @override
  WeatherState get initialState => WeatherEmpty();

  @override
  Stream<WeatherState> mapEventToState(
    WeatherState currentState,
    WeatherEvent event,
  ) async* {
    if (event is FetchWeather) {
      yield WeatherLoading();
      try {
        final int locationId = await _getLocationId(event.location);
        final Weather weather = await _fetchWeather(locationId);
        yield WeatherLoaded(weather);
      } catch (_) {
        yield WeatherError();
      }
    }

    if (event is RefreshWeather) {
      yield WeatherLoading();
      try {
        final Weather weather = await _fetchWeather(event.locationId);
        yield WeatherLoaded(weather);
      } catch (_) {
        yield currentState;
      }
    }
  }

  Future<int> _getLocationId(String location) async {
    final locationUrl =
        'https://www.metaweather.com/api/location/search/?query=$location';
    final locationResponse = await this.httpClient.get(locationUrl);
    if (locationResponse.statusCode != 200) {
      throw Exception('non-200 response');
    }

    final locationJson = jsonDecode(locationResponse.body) as List;
    return (locationJson.first)['woeid'];
  }

  Future<Weather> _fetchWeather(int locationId) async {
    final weatherUrl = 'https://www.metaweather.com/api/location/$locationId';
    final weatherResponse = await this.httpClient.get(weatherUrl);

    if (weatherResponse.statusCode != 200) {
      throw Exception('non-200 response');
    }

    final weatherJson = jsonDecode(weatherResponse.body);
    return Weather.fromJson(weatherJson);
  }
}

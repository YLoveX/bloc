import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_weather/weather_bloc.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: WeatherPage(
        httpClient: http.Client(),
      ),
    );
  }
}

class WeatherPage extends StatefulWidget {
  final http.Client httpClient;

  WeatherPage({Key key, this.httpClient}) : super(key: key);

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  WeatherBloc _weatherBloc;

  @override
  void initState() {
    super.initState();
    _weatherBloc = WeatherBloc(httpClient: widget.httpClient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final location = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CitySelection(),
                ),
              );
              _weatherBloc.dispatch(FetchWeather(location));
            },
          )
        ],
      ),
      body: BlocBuilder(
        bloc: _weatherBloc,
        builder: (BuildContext context, WeatherState state) {
          if (state is WeatherEmpty) {
            return Center(child: Text('Please Select a Location'));
          }
          if (state is WeatherLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state is WeatherLoaded) {
            final weather = state.weather;
            return RefreshIndicator(
              onRefresh: () {
                _weatherBloc.dispatch(RefreshWeather(state.weather.locationId));
              },
              child: ListView(
                children: <Widget>[
                  Text('${weather.condition}'),
                  Text('${weather.temp}'),
                  Text('${weather.created}'),
                ],
              ),
            );
          }
          if (state is WeatherError) {
            return Text('Something went wrong!');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _weatherBloc.dispose();
    super.dispose();
  }
}

class CitySelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('City'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Chicago'),
            onTap: () => Navigator.pop(context, 'Chicago'),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'support/currency.dart';
import 'support/strings.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exchanger',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExchangeForm(title: 'Exchanger'),
    );
  }
}

class ExchangeForm extends StatefulWidget {
  ExchangeForm({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ExchangeFormState createState() => _ExchangeFormState();
}
enum LoadState { Loading, Loaded, Error }

class _ExchangeFormState extends State<ExchangeForm> {
    var amountController = TextEditingController();
    var style = TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0), fontSize: 25.0);
    var fieldMargin = 8.0;
    String _selectedCurrency;
    List<String> _currencies;
    Currency _mainCurrency;
    var _result = "0.0";
    LoadState loadState = LoadState.Loading; // Initial load state of the app...

    Future<Response> fetchCurrencies(){
      return get('http://data.fixer.io/api/latest?access_key=${Strings.apiKey}');
    }

    Future<Currency> getCurrencies() async {
      final response = await fetchCurrencies();

      if(response.statusCode == 200){
        var c = Currency.fromJson(json.decode(response.body));

        if(c.success){
          loadState = LoadState.Loaded;
          return c;
        } else {
          loadState = LoadState.Error;
          return null;
        }
      } else {
        loadState = LoadState.Error;
        return null;
      }
    }

    @override
    void initState() {
      super.initState();

      getCurrencies().then((result) {
        _mainCurrency = result;

        setState(() {
          if(loadState == LoadState.Loaded && _mainCurrency != null){
            _currencies = _mainCurrency.rates.keys.toList();
            _selectedCurrency = _currencies[0];
          }
        });
      });
    }

    @override
    Widget build(BuildContext context) {
      switch (loadState) {
        case LoadState.Loading:
          return loadingDialog();  
        case LoadState.Error:
          return errorScreen();  
        default:
          return mainUi();
      }
    }

    Widget mainUi() {
      return Scaffold(
        appBar: AppBar(
          title:Text("Exchanger"),
          backgroundColor: Colors.blueAccent,
        ),
        body:Container(
          padding: EdgeInsets.all(15.0),
          child:Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: fieldMargin, bottom: fieldMargin),
                child: Row(children: <Widget>[
                  Expanded(
                    child: TextField(
                    controller: amountController,
                    onChanged: (String text) => onAmountChanged(text),
                    decoration: InputDecoration(
                      labelText: "Amount",
                      hintText: "e.g, 123.45",
                      labelStyle: style,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))
                      ),
                    keyboardType: TextInputType.number,
                    ),
                  ),
                Container(width: fieldMargin * 2),
                Expanded(
                  child: DropdownButton<String>(
                  items: _currencies.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Container(child: Text(value), width: 150.0),
                    );
                  }).toList(),
                  value: _selectedCurrency,
                  hint: Text("Convert to"),
                  onChanged: (String value) => onCurrencyChanged(value)),
                ),
              ]),),
              Padding(
                padding: EdgeInsets.only(top: fieldMargin + 40, bottom: fieldMargin),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Center(child: Text(_result, textScaleFactor: 3)))
                  ],
                )
              ,)
            ],
          )
        )
      );
    }

    Widget loadingDialog() {
      return Scaffold(
          body: Dialog(child:
          Padding(child: 
            Row(children: <Widget>[
                Padding(child: CircularProgressIndicator(), padding: EdgeInsets.all(fieldMargin * 2)),
                Padding(child: Text("Loading currencies..."), padding: EdgeInsets.all(fieldMargin * 2))
              ],
              mainAxisSize: MainAxisSize.min)
            , padding: EdgeInsets.only(top: fieldMargin, bottom: fieldMargin)) 
          ),
        );
    }

    Widget errorScreen() {
      return Scaffold(
        body: Center(child: 
          Padding(child: 
            Row(children: <Widget>[
                Padding(child: Icon(Icons.error_outline), padding: EdgeInsets.only(left: fieldMargin, right: fieldMargin / 2)),
                Container(child: Text("Something went wrong, please try again."), padding: EdgeInsets.only(right: fieldMargin, left: fieldMargin / 2))
              ],
              mainAxisSize: MainAxisSize.min)
            , padding: EdgeInsets.only(top: fieldMargin, bottom: fieldMargin)) 
        ,));
    }

    onCurrencyChanged(String value) => setState(() {
      _selectedCurrency = value;
      _result = convert(_selectedCurrency);
    });

    onAmountChanged(String text) => setState(() => _result = convert(_selectedCurrency));
       
    String convert(String selectedCurrency){
      var v = _mainCurrency.rates[selectedCurrency];
      var amt = double.parse(amountController.text == "" ? "0" : amountController.text);

      return selectedCurrency + (v * amt).toStringAsFixed(2);
    }
  }


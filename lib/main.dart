import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'support/currency.dart';
import 'support/strings.dart';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

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
    LoadState _loadState = LoadState.Loading; // Initial load state of the app...
    Color _resultBackgroundColor, _resultContrastColor;

    Future<Response> fetchCurrencies(){
      return get('http://data.fixer.io/api/latest?access_key=${Strings.apiKey}');
    }

    Future<Currency> getCurrencies() async {
      final response = await fetchCurrencies();

      if(response.statusCode == 200){
        var c = Currency.fromJson(json.decode(response.body));

        if(c.success){
          _loadState = LoadState.Loaded;
          return c;
        } else {
          _loadState = LoadState.Error;
          return null;
        }
      } else {
        _loadState = LoadState.Error;
        return null;
      }
    }

    @override
    void initState() {
      super.initState();
      loadCurrencies();
    }

    void loadCurrencies() {
      setState(() => _loadState = LoadState.Loading);

      getCurrencies().then((result) {        
        _mainCurrency = result;
      
        setState(() {
          if(_loadState == LoadState.Loaded && _mainCurrency != null){
            randomizeResultColor();
            _currencies = _mainCurrency.rates.keys.toList();
            _selectedCurrency = _currencies[0];
          }
        });
      });
    }

    void randomizeResultColor() {
      var rgb = getRandomColor();
      _resultBackgroundColor = Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
      _resultContrastColor = getContrastColor(rgb[0], rgb[1], rgb[2]);
    }

    @override
    Widget build(BuildContext context) {
      switch (_loadState) {
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
              Flexible(flex: 1,
              child: Padding(
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
                  child: Container(
                    padding: EdgeInsets.only(left: 5.0, top: 4.0, right: 1.0, bottom: 4.0),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1.0, style: BorderStyle.solid), borderRadius: BorderRadius.all(Radius.circular((5.0)))
                      )
                    ),
                    child: DropdownButtonHideUnderline(
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
                  ))
                ),
              ]),)),
              Flexible(flex: 6,
                child: AnimatedContainer(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    color: _resultBackgroundColor,
                  ),
                  duration: Duration(milliseconds: 500),
                  child: Padding(
                  padding: EdgeInsets.only(top: fieldMargin + 40, bottom: fieldMargin),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(child: Center(child: 
                        Text(
                            _result, 
                            textScaleFactor: 3,
                            style: TextStyle(color: _resultContrastColor)
                          )
                        ))
                    ],
                  )
                ),
              )),
              Flexible(
                child: Container(),
                flex: 1
                )
            ],
          )
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.refresh),
          onPressed: () => loadCurrencies(),
        ),
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
      randomizeResultColor();
      _selectedCurrency = value;
      _result = convert(_selectedCurrency);
    });

    onAmountChanged(String text) => setState(() => _result = convert(_selectedCurrency));
       
    String convert(String selectedCurrency){
      var v = _mainCurrency.rates[selectedCurrency];
      var amt = double.parse(amountController.text == "" ? "0" : amountController.text);
      final frmt = NumberFormat("#,###.##");

      return selectedCurrency + "\$" + frmt.format((v * amt));
    }

    List<int> getRandomColor(){
      var rnd = Random();
      return [rnd.nextInt(256), rnd.nextInt(256), rnd.nextInt(256)];
    }

    // Based on the W3C's standard formula for calculating perceived brightness...
    // More info: https://www.w3.org/TR/AERT/#color-contrast
    Color getContrastColor(int r, int g, int b){
      var i = (r * .299) + (g * .587) + (b * .114);
      return i > 186 ? Colors.black : Colors.white;
    }
  }


class Currency{
  final bool success;
  final int timestamp;
  final String base;
  final String date;
  final Map<String, dynamic> rates;

  Currency({this.success, this.timestamp, this.base, this.date, this.rates});

  factory Currency.fromJson(Map<String, dynamic> json){
    return Currency(
      success: json["success"],
      timestamp: json["timestamp"],
      base: json["base"],
      date: json["date"],
      rates: json["rates"]
    );
  }
}
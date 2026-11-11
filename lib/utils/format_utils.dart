import 'package:intl/intl.dart';
import 'package:primo_secreto_app/models/exchange_model.dart';

String formatBudget(BudgetModel budget) {
  final amount = double.tryParse(budget.amount) ?? 0;
  return NumberFormat.currency(
    locale: "es_PE",
    name: budget.currency,
  ).format(amount);
}

String formatEventDate(String date) {
  return DateFormat.yMMMMd("es").format(DateTime.parse(date.substring(0, 10)));
}

String toApiDate(DateTime date) => DateFormat("yyyy-MM-dd").format(date);

List<ExchangeModel> sortByEventDate(List<ExchangeModel> exchanges) {
  final sorted = [...exchanges];
  sorted.sort((a, b) {
    if (a.eventDate != b.eventDate) {
      if (a.eventDate == null) return 1;
      if (b.eventDate == null) return -1;
      return a.eventDate!.compareTo(b.eventDate!);
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  });
  return sorted;
}

String pluralize(int count, String singular, String plural) =>
    count == 1 ? "1 $singular" : "$count $plural";

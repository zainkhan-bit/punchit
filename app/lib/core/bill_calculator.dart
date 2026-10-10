import '../models/models.dart';

class BillBreakdown {
  final double subtotal;
  final double discount;
  final double serviceCharge;
  final double taxPercent;
  final double tax;
  final double total;

  const BillBreakdown({
    required this.subtotal,
    required this.discount,
    required this.serviceCharge,
    required this.taxPercent,
    required this.tax,
    required this.total,
  });
}

/// Bill ka hisaab ek hi jagah. Backend mein bhi bilkul yahi formula lagana,
/// taake app aur printed bill ka total kabhi alag na ho.
///
///   afterDiscount = subtotal - discount
///   serviceCharge = afterDiscount x service% (takeaway pe 0 agar setting ON)
///   tax           = afterDiscount x payment method ka tax%
///   total         = afterDiscount + serviceCharge + tax
class BillCalculator {
  static BillBreakdown calculate({
    required double subtotal,
    double discount = 0,
    required PaymentMethod method,
    required AppSettings settings,
    required bool isDineIn,
  }) {
    final d = discount.clamp(0, subtotal).toDouble();
    final afterDiscount = subtotal - d;

    final applyService = isDineIn || !settings.serviceChargeDineInOnly;
    final service = applyService
        ? (afterDiscount * settings.serviceChargePercent / 100).roundToDouble()
        : 0.0;

    final tax = (afterDiscount * method.taxPercent / 100).roundToDouble();

    return BillBreakdown(
      subtotal: subtotal,
      discount: d,
      serviceCharge: service,
      taxPercent: method.taxPercent,
      tax: tax,
      total: afterDiscount + service + tax,
    );
  }
}

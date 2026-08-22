import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// Generates a GST-style invoice PDF for a paid order and opens the native
/// share/save sheet (WS-B3).
///
/// The PDF body is intentionally English-only: it is a financial document and
/// the bundled PDF fonts don't cover Devanagari. UI strings around the button
/// stay localized as usual.
class InvoicePdfService {
  /// Test-mode demo orders (`demo_<millis>` ids) store integer RUPEES while
  /// live server orders store PAISE — normalize everything to paise.
  int _toPaise(OrderModel order, int value) =>
      order.id.startsWith('demo_') ? value * 100 : value;

  /// Default PDF fonts have no ₹ glyph, so amounts are prefixed "Rs.".
  String _inr(int paise) => 'Rs. ${(paise / 100).toStringAsFixed(2)}';

  Future<void> shareInvoice(OrderModel order, {required String appName}) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final issuedOn = order.paidAt ?? order.createdAt;
    final invoiceRef = order.invoiceNumber ?? order.id;

    final subtotal = _toPaise(order, order.itemsSubtotal);
    final platformFee = _toPaise(order, order.platformFee);
    final gst = _toPaise(order, order.gstAmount);
    final total = _toPaise(order, order.totalAmount);

    pw.Widget totalRow(String label, String value, {bool bold = false}) {
      final style = pw.TextStyle(
        fontSize: bold ? 12 : 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: style),
            pw.Text(value, style: style),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        appName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Digital Embroidery Designs',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Invoice No: $invoiceRef',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Date: ${dateFormat.format(issuedOn)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 12),
              // Buyer
              pw.Text(
                'Billed To',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              if (order.buyerName.isNotEmpty)
                pw.Text(
                  order.buyerName,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              if (order.buyerEmail.isNotEmpty)
                pw.Text(
                  order.buyerEmail,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              pw.SizedBox(height: 20),
              // Items table
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Design', 'Format', 'Price'],
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                cellAlignments: {3: pw.Alignment.centerRight},
                data: [
                  for (var i = 0; i < order.items.length; i++)
                    [
                      '${i + 1}',
                      order.items[i].title,
                      order.items[i].fileFormat,
                      _inr(_toPaise(order, order.items[i].price)),
                    ],
                ],
              ),
              pw.SizedBox(height: 16),
              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      totalRow('Subtotal', _inr(subtotal)),
                      totalRow(
                        'Platform Fee (${order.platformFeePercent}%)',
                        _inr(platformFee),
                      ),
                      totalRow('GST (${order.gstPercent}%)', _inr(gst)),
                      pw.Divider(color: PdfColors.grey400),
                      totalRow('Total', _inr(total), bold: true),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              if ((order.razorpayPaymentId ?? '').isNotEmpty)
                pw.Text(
                  'Payment ID: ${order.razorpayPaymentId}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 6),
              pw.Text(
                'Digital goods — delivered as downloadable design files in '
                'the $appName app. This is a computer-generated invoice and '
                'does not require a signature.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    final safeRef = invoiceRef.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'invoice_$safeRef.pdf',
    );
  }
}

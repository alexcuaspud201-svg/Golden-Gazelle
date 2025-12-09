import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'nfc_session_controller.dart';

class NfcPdfGenerator {
  
  static Future<String> generateAndSavePdf(MockUserModel user, bool isPremium) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Dr. AI - Historial Médico', style: pw.TextStyle(font: fontBold, fontSize: 24)),
                    if (isPremium)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.amber),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Text('PREMIUM', style: pw.TextStyle(font: fontBold, color: PdfColors.amber)),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('ID Paciente: ${user.userCode}', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _buildInfoRow('Nombre', user.name, font, fontBold),
              _buildInfoRow('Edad', '${user.age} años', font, fontBold),
              _buildInfoRow('Tipo de Sangre', user.bloodType, font, fontBold),
              pw.SizedBox(height: 20),
              pw.Text('Alergias:', style: pw.TextStyle(font: fontBold, fontSize: 16)),
              ...user.allergies.map((a) => pw.Bullet(text: a, style: pw.TextStyle(font: font))),
              pw.SizedBox(height: 20),
              pw.Text('Padecimientos:', style: pw.TextStyle(font: fontBold, fontSize: 16)),
              ...user.conditions.map((c) => pw.Bullet(text: c, style: pw.TextStyle(font: font))),
              
              pw.Spacer(),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: "https://dr-ai.app/medical-record/${user.id}",
                  width: 100,
                  height: 100,
                ),
              ),
              pw.Center(child: pw.Text('Escanea para ver historial digital', style: pw.TextStyle(font: font, fontSize: 10))),
              pw.SizedBox(height: 20),
              pw.Footer(
                leading: pw.Text(DateTime.now().toString(), style: pw.TextStyle(font: font, fontSize: 8)),
                trailing: pw.Text('Generado por Dr. AI Simulator', style: pw.TextStyle(font: font, fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    return await _savePdfFile(pdf, user.userCode);
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 14)),
        ],
      ),
    );
  }

  static Future<String> _savePdfFile(pw.Document pdf, String fileNameSuffix) async {
    if (Platform.isAndroid) {
      // Solicitar permisos
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        // En Android 13+ (API 33+) MANAGE_EXTERNAL_STORAGE puede ser necesario o Scoped Storage.
        // Para simplicidad en API < 30 request storage. En 30+ usamos getExternalStoragePublicDirectory o similar si es posible
        // O simplemente Downloads folder
        status = await Permission.storage.request();
      }
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory(); // Fallback
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final String path = '${directory!.path}/DrAI_Simulado_$fileNameSuffix.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }
}

import 'package:flutter/material.dart';
import 'nfc_session_controller.dart';
import 'nfc_payment_simulator.dart';
import 'nfc_pdf_generator.dart';
import 'dart:math';

class NfcSimulatorPage extends StatefulWidget {
  const NfcSimulatorPage({super.key});

  @override
  State<NfcSimulatorPage> createState() => _NfcSimulatorPageState();
}

class _NfcSimulatorPageState extends State<NfcSimulatorPage> {
  final NfcSessionController _controller = NfcSessionController();
  bool _isScanning = false;

  void _scanTag() async {
    setState(() {
      _isScanning = true;
    });

    // Simular delay de lectura NFC
    await Future.delayed(const Duration(seconds: 2));

    // Generar ID random para simular distintos tags
    String randomId = "TAG-${Random().nextInt(999999)}";
    String? currentId = _controller.currentUser?.id;

    if (!mounted) return;

    // Si es la primera vez (no hay usuario)
    if (currentId == null) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tarjeta NFC Detectada'),
          content: Text('ID: $randomId\n¿Deseas usarla como identificador para este simulador?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usar')),
          ],
        ),
      );

      if (confirm == true) {
        _controller.scanTag(randomId);
      }
    } else {
      // Ya hay usuario, simplemente recargamos (o simulamos leer el mismo tag)
      // En este simulador, "escanear" de nuevo podría significar re-validar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario verificado con NFC correctamente.')),
      );
    }

    setState(() {
      _isScanning = false;
    });
  }

  void _startPayment() async {
    bool? success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NfcPaymentSimulator()),
    );

    if (success == true) {
      setState(() {
        _controller.upgradeToPremium();
      });
    }
  }

  void _downloadPdf() async {
    if (_controller.currentUser == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando PDF...')),
      );

      String path = await NfcPdfGenerator.generateAndSavePdf(
        _controller.currentUser!,
        _controller.isPremium,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF guardado correctamente:\n$path'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MockUserModel? user = _controller.currentUser;
    bool isPremium = _controller.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador NFC Dr. AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _controller.clearSession();
              });
            },
            tooltip: 'Reiniciar Simulación',
          )
        ],
      ),
      body: Center(
        child: user == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.nfc, size: 100, color: Colors.blueGrey),
                  const SizedBox(height: 20),
                  const Text('Acerque su tarjeta NFC', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanTag,
                    icon: _isScanning
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering),
                    label: Text(_isScanning ? 'Escaneando...' : 'Escanear Ahora (Simulado)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text(user.userCode, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 20),
                            const Divider(),
                            _buildDataRow('Edad', '${user.age} años'),
                            _buildDataRow('Sangre', user.bloodType),
                            const SizedBox(height: 10),
                            const Text('Padecimientos:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8,
                              children: user.conditions
                                  .map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (isPremium)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              border: Border.all(color: Colors.amber),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.star, color: Colors.amber),
                                SizedBox(width: 10),
                                Text('MIEMBRO PREMIUM',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _downloadPdf,
                            icon: const Icon(Icons.download),
                            label: const Text('Descargar Carnet PDF Real'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const Text('¿Deseas acceder a tu historial completo?', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _startPayment,
                            icon: const Icon(Icons.workspace_premium),
                            label: const Text('Activar Carnet Médico Premium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

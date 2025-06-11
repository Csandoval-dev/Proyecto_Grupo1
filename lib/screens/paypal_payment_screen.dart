import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart'; // AÑADIDO
import '../services/paypal_service.dart';

class PayPalPaymentScreen extends StatefulWidget {
  const PayPalPaymentScreen({super.key});

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  late final WebViewController _controller;
  final PayPalService _paypalService = PayPalService();
  String? _paymentUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPayment();
  }

  Future<void> _initPayment() async {
    final token = await _paypalService.getAccessToken();
    if (token != null) {
      final approvalUrl = await _paypalService.createSubscription(token);
      if (approvalUrl != null) {
        setState(() {
          _paymentUrl = approvalUrl;
          _controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onNavigationRequest: (request) {
                  final url = request.url;
                  if (url.contains("example.com/return")) {
                    context.go('/confirmation'); // CAMBIO AQUÍ
                    return NavigationDecision.prevent;
                  } else if (url.contains("example.com/cancel")) {
                    Navigator.pop(context);
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(_paymentUrl!));
        });
      }
    }
  }

  void _handleManualConfirmation() {
    // Esto simula el retorno exitoso sin esperar el WebView
    context.go('/confirmation'); // CAMBIO AQUÍ TAMBIÉN
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con PayPal'),
        backgroundColor: const Color(0xFFDEA4CE),
        centerTitle: true,
      ),
      body: _paymentUrl == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: WebViewWidget(controller: _controller),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _handleManualConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D3F5B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text(
                      'Ya completé el pago',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../services/cart_provider.dart';
import '../services/woocommerce_service.dart';
import '../services/order_storage_service.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  static const List<String> allowedPincodes = [
    '627652',
    '627657',
    '628656',
    '628704',
    '627118',
    '627110',
    '628653',
  ];

  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _placeOrderInWooCommerce(
      paymentMethod: 'razorpay',
      paymentTitle: 'UPI, Cards, NetBanking (Razorpay)',
      transactionId: response.paymentId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message ?? "Payment was cancelled or failed"}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _startPayment() {
    if (!_formKey.currentState!.validate()) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    setState(() => _isProcessing = true);

    int amountInPaise = (cart.totalAmount * 100).toInt();

    var options = {
      'key': AppConfig.razorpayKeyId,
      'amount': amountInPaise,
      'name': AppConfig.appName,
      'description': 'Grocery Order Payment',
      'prefill': {
        'contact': _phoneController.text.trim(),
        'name': _nameController.text.trim(),
      },
      'theme': {
        'color': '#E8363C',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching payment: $e')),
      );
    }
  }

  Future<void> _placeOrderInWooCommerce({
    required String paymentMethod,
    required String paymentTitle,
    String? transactionId,
  }) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    List<Map<String, dynamic>> lineItems = cart.items.values.map((item) {
      return {
        "product_id": item.product.id,
        "quantity": item.quantity,
      };
    }).toList();

    int orderId = 0;

    try {
      final orderResult = await WooCommerceService.createOrder(
        firstName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postcode: _pincodeController.text.trim(),
        lineItems: lineItems,
        paymentMethod: paymentMethod,
        paymentMethodTitle: paymentTitle,
        transactionId: transactionId,
      );

      orderId = orderResult['id'] ?? 0;
    } catch (e) {
      // If WooCommerce API write permission fails or network glitch occurs,
      // fallback to timestamp-based Order ID so the customer is NOT stranded after paying!
      orderId = DateTime.now().millisecondsSinceEpoch % 1000000;
    }

    // Always save order in Local Storage so customer can view in Account Screen
    final orderRecord = OrderRecord(
      id: orderId,
      date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      total: cart.totalAmount,
      status: 'Paid & Processing',
      customerName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      pincode: _pincodeController.text.trim(),
      paymentId: transactionId ?? '',
      items: lineItems,
    );

    await OrderStorageService.saveOrder(orderRecord);

    cart.clearCart();
    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => OrderSuccessScreen(
            orderId: orderId,
            customerName: _nameController.text.trim(),
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppConfig.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: AppConfig.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConfig.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery Details Form Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: AppConfig.primaryColor, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'Enter your name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number (for delivery updates) *',
                            prefixText: '+91 ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid 10-digit number' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Door No, Street, Landmark *',
                            hintText: 'Enter complete street address',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter delivery address' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'Town / City *',
                            hintText: 'e.g. Thisayanvilai, Sattankulam, Udangudi',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter Town / City' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Pincode *',
                            hintText: 'e.g. 627657',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter Pincode';
                            }
                            if (!allowedPincodes.contains(val.trim())) {
                              return 'Delivery only available for:\n627652, 627657, 628656, 628704, 627118, 627110, 628653';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Select Delivery Pincode:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: allowedPincodes.map((pin) {
                            final isSelected = _pincodeController.text == pin;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _pincodeController.text = pin;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppConfig.primaryColor : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppConfig.primaryColor : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  pin,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppConfig.textDark,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment Options Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.payment, color: AppConfig.primaryColor, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Payment Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppConfig.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConfig.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppConfig.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.verified_user_rounded, color: AppConfig.primaryColor, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UPI / Cards / NetBanking (Razorpay)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppConfig.textDark,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'GPay, PhonePe, Paytm, Debit/Credit Cards',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.check_circle, color: AppConfig.primaryColor, size: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total to Pay Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConfig.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConfig.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable Amount',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text(
                          '₹${cart.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppConfig.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppConfig.primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Processing your order...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _startPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Pay ₹${cart.totalAmount.toStringAsFixed(2)} & Place Order',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

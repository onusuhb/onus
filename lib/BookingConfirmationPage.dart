import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'models/service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Service service;

  const BookingConfirmationPage({super.key, required this.service});

  @override
  _BookingConfirmationPageState createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String _companyName = "Loading...";
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanyName();
  }

  Future<void> _fetchCompanyName() async {
    if (widget.service.userId.isNotEmpty) {
      try {
        DocumentSnapshot companyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.service.userId)
            .get();

        if (companyDoc.exists) {
          setState(() {
            _companyName = companyDoc['fullName'] ?? "Unknown Company";
          });
        } else {
          setState(() {
            _companyName = "Unknown Company";
          });
        }
      } catch (e) {
        setState(() {
          _companyName = "Error fetching company";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEquipmentRental = widget.service.category == "Equipment Rental";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.teal, size: 24),
                SizedBox(width: 8.0),
                Text(
                  'Service Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _buildDetailRow(Icons.business, 'Company:', _companyName),
            _buildDetailRow(Icons.build, 'Service:', widget.service.name),
            _buildDetailRow(
                Icons.category, 'Category:', widget.service.category),
            _buildDetailRow(
                Icons.description, 'Description:', widget.service.description),
            _buildDetailRow(
              Icons.attach_money,
              'Price:',
              "SAR ${widget.service.priceValue.toStringAsFixed(2)} ${widget.service.priceUnit}",
            ),
            const SizedBox(height: 24.0),
            const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.teal, size: 24),
                SizedBox(width: 8.0),
                Text(
                  'Select Date and Time',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (isEquipmentRental)
              ElevatedButton.icon(
                onPressed:
                    _isBooking ? null : () => _selectRentalDates(context),
                icon: const Icon(Icons.date_range, color: Colors.white),
                label: Text(
                  selectedStartDate != null && selectedEndDate != null
                      ? 'Rental: ${selectedStartDate!.toLocal().toString().split(' ')[0]} - ${selectedEndDate!.toLocal().toString().split(' ')[0]}'
                      : 'Choose Start & End Dates',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _isBooking ? null : () => _selectDateTime(context),
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: Text(
                  selectedDate != null && selectedTime != null
                      ? 'Selected: ${selectedDate!.toLocal().toString().split(' ')[0]} at ${selectedTime!.format(context)}'
                      : 'Choose Date and Time',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            const SizedBox(height: 24.0),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isBooking ? null : _confirmBooking,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: _isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8.0),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: '$label ',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDateTime(BuildContext context) async {
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 5)));

    if (date != null) {
      final time =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());

      if (time != null) {
        setState(() {
          selectedDate = date;
          selectedTime = time;
        });
      }
    }
  }

  void _selectRentalDates(BuildContext context) async {
    final start = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 5)));
    if (start != null) {
      final end = await showDatePicker(
          context: context,
          initialDate: start,
          firstDate: start,
          lastDate: start.add(const Duration(days: 5)));
      if (end != null) {
        setState(() {
          selectedStartDate = start;
          selectedEndDate = end;
        });
      }
    }
  }

  Future<void> _confirmBooking() async {
    final isEquipmentRental = widget.service.category == "Equipment Rental";
    final isConstruction = widget.service.category == "Construction";
    final isRenovation = widget.service.category == "Renovation";

    if (isEquipmentRental) {
      if (selectedStartDate == null || selectedEndDate == null) {
        _showErrorDialog("Please select a rental start and end date.");
        return;
      }

      int rentalDays =
          selectedEndDate!.difference(selectedStartDate!).inDays + 1;
      if (rentalDays > 5) {
        _showErrorDialog("Rental period cannot exceed 5 days.");
        return;
      }
    } else if (isConstruction || isRenovation) {
      if (selectedDate == null || selectedTime == null) {
        _showErrorDialog("Please select a date and time for the service.");
        return;
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final existingBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .where('serviceId', isEqualTo: widget.service.id)
            .where('status', whereIn: ['Pending', 'Completed']).get();

        if (existingBookings.docs.isNotEmpty) {
          if (isEquipmentRental) {
            for (var doc in existingBookings.docs) {
              final booking = doc.data();
              final existingStartDate =
                  DateTime.parse(booking['selectedStartDate']);
              final existingEndDate =
                  DateTime.parse(booking['selectedEndDate']);

              if ((selectedStartDate!.isBefore(existingEndDate) ||
                      selectedStartDate!.isAtSameMomentAs(existingEndDate)) &&
                  (selectedEndDate!.isAfter(existingStartDate) ||
                      selectedEndDate!.isAtSameMomentAs(existingStartDate))) {
                _showErrorDialog(
                    "You already have a booking for this equipment during the selected period. Please choose different dates.");
                return;
              }
            }
          } else {
            _showErrorDialog(
                "You already have an active booking for this service.");
            return;
          }
        }
      }
    } catch (e) {
      print("Error checking existing bookings: $e");
    }

    if (isEquipmentRental &&
        widget.service.hasInventory &&
        widget.service.stockQuantity <= 0) {
      _showErrorDialog("Sorry, this equipment is currently out of stock.");
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog("Please log in to make a booking.");
        return;
      }

      print('Creating booking with:');
      print('Service ID: ${widget.service.id}');
      print('User ID: ${user.uid}');
      print('Company ID: ${widget.service.userId}');
      print('Service Name: ${widget.service.name}');
      print('Category: ${widget.service.category}');

      final bookingData = {
        'serviceId': widget.service.id,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'companyId': widget.service.userId,
        'serviceName': widget.service.name,
        'category': widget.service.category,
        'price': widget.service.priceValue,
        'priceUnit': widget.service.priceUnit,
        'selectedDate': selectedDate?.toIso8601String(),
        'selectedTime': selectedTime?.format(context),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.service.category == 'Equipment Rental') {
        bookingData.addAll({
          'selectedStartDate': selectedStartDate?.toIso8601String(),
          'selectedEndDate': selectedEndDate?.toIso8601String(),
        });
      }

      print('Creating booking with data: $bookingData');  

      final bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);
      print('Booking created with ID: ${bookingRef.id}');

      if (widget.service.category == "Equipment Rental" &&
          widget.service.hasInventory) {
        await FirebaseFirestore.instance
            .collection('services')
            .doc(widget.service.id)
            .update({
          'stockQuantity': FieldValue.increment(-1),
        });
      }

      _showPaymentModal();
    } catch (e) {
      print('Error creating booking: $e');
      _showErrorDialog(
          "An error occurred while processing your booking. Please try again.");
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missing Information'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    label: 'Card',
                    onTap: () {
                      Navigator.pop(context);
                      _showCardPaymentForm();
                    },
                  ),
                  _buildPaymentOption(
                    icon: Icons.account_balance_wallet,
                    label: 'Apple Pay',
                    onTap: () {
                      Navigator.pop(context);
                      _showApplePayMockModal();
                    },
                  ),
                  _buildPaymentOption(
                    icon: Icons.paypal,
                    label: 'PayPal',
                    onTap: () {
                      Navigator.pop(context);
                      _showPayPalMockModal();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal.shade100,
            child: Icon(icon, size: 30, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  String? _validateCardName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the cardholder name';
    }
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return 'Name should only contain letters and spaces';
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the card number';
    }
    value = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[0-9]{16}$').hasMatch(value)) {
      return 'Please enter a valid 16-digit card number';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the expiry date';
    }
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
      return 'Please enter a valid date (MM/YY)';
    }
    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'Card has expired';
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the CVV';
    }
    if (!RegExp(r'^[0-9]{3,4}$').hasMatch(value)) {
      return 'Please enter a valid CVV (3 or 4 digits)';
    }
    return null;
  }

  void _showCardPaymentForm() {
    final cardNameController = TextEditingController();
    final cardNumberController = TextEditingController();
    final expiryDateController = TextEditingController();
    final cvvController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    double totalAmount = _calculateTotalAmount();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.credit_card, size: 40, color: Colors.teal),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter Payment Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Total Amount: SAR ${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: cardNameController,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      errorStyle: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        height: 1,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      errorMaxLines: 2,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: _validateCardName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cardNumberController,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                      counterText: '',
                      errorStyle: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        height: 1,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      errorMaxLines: 2,
                    ),
                    validator: _validateCardNumber,
                    onChanged: (value) {
                      final newValue = value.replaceAll(RegExp(r'\s'), '');
                      if (newValue.length > 0) {
                        final formatted =
                            newValue.split('').asMap().entries.map((e) {
                          return e.key % 4 == 0 && e.key != 0
                              ? ' ${e.value}'
                              : e.value;
                        }).join('');
                        if (formatted != value) {
                          cardNumberController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                                offset: formatted.length),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: expiryDateController,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date (MM/YY)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                            counterText: '',
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              height: 1,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            errorMaxLines: 2,
                          ),
                          validator: _validateExpiryDate,
                          onChanged: (value) {
                            if (value.length == 2 && !value.contains('/')) {
                              expiryDateController.text = '$value/';
                              expiryDateController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: expiryDateController.text.length),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: cvvController,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.security),
                            counterText: '',
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              height: 1,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            errorMaxLines: 2,
                          ),
                          validator: _validateCVV,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        _showPaymentConfirmationDialog(totalAmount);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Pay Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 32.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateTotalAmount() {
    if (widget.service.category == "Equipment Rental" &&
        selectedStartDate != null &&
        selectedEndDate != null) {
      int days = selectedEndDate!.difference(selectedStartDate!).inDays + 1;
      return widget.service.priceValue * days;
    }
    return widget.service.priceValue;
  }

  void _showPaymentConfirmationDialog(double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to pay:'),
            const SizedBox(height: 8),
            Text(
              'SAR ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.service.category == "Equipment Rental"
                  ? 'For rental period: ${selectedStartDate?.toString().split(' ')[0]} to ${selectedEndDate?.toString().split(' ')[0]}'
                  : 'For service on: ${selectedDate?.toString().split(' ')[0]} at ${selectedTime?.format(context)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPaymentSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  void _showApplePayMockModal() {
    double totalAmount = _calculateTotalAmount();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.apple, size: 40, color: Colors.black),
              const SizedBox(height: 10),
              const Text(
                'Apple Pay',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Total Amount: SAR ${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Double-click the side button to confirm.'),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentConfirmationDialog(totalAmount);
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirm Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14.0, horizontal: 32.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPayPalMockModal() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    double totalAmount = _calculateTotalAmount();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.paypal, size: 40, color: Colors.indigo),
                const SizedBox(height: 10),
                const Text(
                  'PayPal Login',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Amount: SAR ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPaymentConfirmationDialog(totalAmount);
                  },
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Login & Pay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content:
            const Text('Thank you! Your booking and payment are confirmed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

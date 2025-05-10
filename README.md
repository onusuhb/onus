# Onus - Service Booking Platform

Onus is a Flutter-based service booking platform that connects customers with service providers. The platform allows companies to list their services and customers to book them.

## Features

- **User Authentication**
  - Customer and Company registration
  - Secure login system
  - Role-based access control

- **Customer Features**
  - Browse available services
  - Book services
  - View booking history
  - Manage bookings

- **Company Features**
  - List and manage services
  - Handle customer bookings
  - Track service requests
  - Company profile management

- **Admin Features**
  - User management
  - Company approval system
  - Platform statistics
  - Service management

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Firebase account
- Android Studio / VS Code

### Installation

1. Clone the repository
```bash
git clone https://github.com/onusuhb/onus.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files
   - Enable Authentication and Firestore

4. Run the application
```bash
flutter run
```

## Project Structure

```
lib/
├── authentication/
│   ├── auth_gate.dart
│   ├── login_screen.dart
│   └── registration_screen.dart
├── models/
│   └── service.dart
├── CompanyHomeScreen.dart
├── ServiceDetailsPage.dart
├── BookingConfirmationPage.dart
├── ManageCustomerBookingsPage.dart
├── ManageCompanyBookingsPage.dart
└── ...
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


## Contact

For any queries or support, please contact us at: onusuhb@gmail.com


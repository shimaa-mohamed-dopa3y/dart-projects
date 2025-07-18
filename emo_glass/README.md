# Emo Glasses - AI-Powered Emotion Detection for the Visually Impaired

## 🌟 Overview

Emo Glasses is a revolutionary Flutter application designed specifically for blind and visually impaired users. It leverages AI-powered smart glasses to detect emotions in real-time and provides audio feedback through text-to-speech technology, making emotional communication accessible to everyone.

## 🚀 Features

### For Patients (Visually Impaired Users)
- **🎯 Real-time Emotion Detection**: AI-powered emotion analysis through smart glasses camera
- **🎤 Voice Recording**: Record and upload audio to the cloud for analysis
- **🚨 Emergency Button**: Quick access to emergency services with voice confirmation
- **🔊 Full Accessibility**: Complete screen reader support and voice announcements
- **⚙️ Customizable Settings**: Adjustable speech rate and accessibility preferences
- **👤 Profile Management**: Edit personal information and glasses serial number

### For Specialists (Healthcare Providers)
- **📊 Patient Dashboard**: Overview of all assigned patients with statistics
- **📈 Patient Records**: View timeline of patient photos, audio recordings, and emotions
- **🎵 Audio Playback**: Listen to patient recordings directly in the app
- **📸 Photo Gallery**: View photos captured by patient's smart glasses
- **📋 Patient Details**: Complete patient information and interaction history

### Technical Features
- **🔐 Secure Authentication**: Role-based login for patients and specialists
- **☁️ Cloud Integration**: Seamless API integration for data synchronization
- **🎨 Pixel-Perfect UI**: Modern design matching provided screenshots exactly
- **♿ Accessibility First**: Built with blind users in mind from ground up
- **🌐 Offline Support**: Local storage for critical functionality

## 🏗️ Architecture

The app follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/                    # Core utilities and services
│   ├── providers/          # Riverpod state management
│   ├── services/           # Audio, TTS, and other services
│   ├── theme.dart          # App theme and colors
│   └── widgets/            # Reusable UI components
├── data/                   # Data layer
│   ├── models/             # Data models
│   ├── repositories/       # Repository implementations
│   └── services/           # API services
├── domain/                 # Domain layer
│   ├── entities/           # Business entities
│   └── repositories/       # Repository interfaces
└── presentation/           # UI layer
    ├── auth/               # Authentication screens
    ├── onboarding/         # Onboarding flow
    ├── patient/            # Patient-specific screens
    └── specialist/         # Specialist-specific screens
```

## 🛠️ Technologies Used

- **Framework**: Flutter 3.7.2+
- **State Management**: Riverpod
- **UI**: Custom responsive design with ScreenUtil
- **Fonts**: Google Fonts (Montserrat)
- **Icons**: Iconsax for modern icons
- **Audio**: flutter_sound for recording and playback
- **TTS**: flutter_tts for text-to-speech
- **HTTP**: Dio for API communication
- **Storage**: shared_preferences for local data
- **Permissions**: permission_handler for audio access

## 📡 API Integration

Base URL: `https://63cd-41-45-117-2.ngrok-free.app`

### Authentication Endpoints
- `POST /api/users` - User registration (patient/doctor)
- `POST /api/users/login` - User authentication
- `POST /api/users/logout` - User logout

### Profile Management
- `GET /api/profile` - Get user profile
- `PUT /api/profile` - Update user profile

### Patient Management
- `GET /api/patients` - Get patients list (specialists)
- `GET /api/patients/{id}` - Get patient details
- `PUT /api/patients/{id}/status` - Update patient status
- `PUT /api/patients/{id}/assign` - Directly assign patient to doctor

### Doctor Management
- `GET /api/doctors` - Get doctors list
- `GET /api/doctors/{id}` - Get doctor details
- `GET /api/doctors/requests` - Get assignment requests

### Doctor-Patient Assignment
- `POST /api/doctors/{id}/request-assign` - Request assignment to doctor
- `POST /api/requests/{id}/accept` - Accept assignment request
- `POST /api/requests/{id}/decline` - Decline assignment request

### File Upload & Management
- `POST /api/audio/upload` - Upload audio recordings
- `POST /api/images/upload-image-esp32/{serialNumber}` - Upload images from glasses
- `GET /api/images/{fileId}?fileType={type}` - Get file by ID (image/audio)

### Notifications
- `GET /api/notifications` - Get notifications
- `PUT /api/notifications/{id}/read` - Mark notification as read
- `GET /api/notification-settings` - Get notification settings
- `PUT /api/notification-settings` - Update notification settings

### Additional Features (Available in API Service)
- Password reset functionality
- Email verification
- Patient statistics and analytics
- Emotion analysis results
- Patient timeline and records
- Emergency contacts management
- Device management
- Health metrics and monitoring
- Appointment scheduling
- Messaging and communication
- Data export and backup
- System health and monitoring
- User preferences and settings
- Account management

### Error Handling
The API service includes comprehensive error handling for:
- Network connectivity issues
- Authentication errors (401)
- Authorization errors (403)
- Resource not found (404)
- Validation errors (422)
- Rate limiting (429)
- Server errors (500, 502, 503)
- SSL certificate issues
- Timeout errors

## 🎯 User Flows

### Patient Journey
1. **Onboarding** → Role selection (Patient)
2. **Registration** → Enter name, email, password, glasses serial number
3. **Home Screen** → Toggle emotion detection, record voice, emergency access
4. **Voice Recording** → Tap to record, automatic upload and processing
5. **Settings** → Adjust accessibility preferences, logout

### Specialist Journey
1. **Onboarding** → Role selection (Specialist)
2. **Registration** → Enter name, email, password, specialization
3. **Dashboard** → View patient statistics and list
4. **Patient Details** → Review patient records, photos, and audio
5. **Audio Playback** → Listen to patient recordings

## ♿ Accessibility Features

- **Full Screen Reader Support**: Every UI element has semantic labels
- **Voice Announcements**: All actions are announced via TTS
- **Large Touch Targets**: Buttons designed for easy access
- **High Contrast**: Colors chosen for maximum visibility
- **Voice Navigation**: Navigate entirely through audio feedback
- **Customizable Speech Rate**: Adjust TTS speed to user preference

## 🎨 Design System

### Colors
- **Primary**: #6B9BA5 (Calming blue-green)
- **Secondary**: #B6C7D1 (Light blue-gray)
- **Background**: #EAF2F5 (Very light blue)
- **Error**: #D96C6C (Accessible red)
- **Success**: #4CAF50 (Accessible green)

### Typography
- **Font Family**: Montserrat
- **Responsive Sizing**: Scales with device screen size
- **Weight Hierarchy**: Regular (400) to ExtraBold (800)

## 🚀 Getting Started

### Prerequisites
- Flutter 3.7.2 or higher
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd emo_glasses
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Add the logo asset**
   - Place your logo image at `assets/images/image.png`

4. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🔧 Configuration

### API Configuration
Update the base URL in `lib/data/services/api_service.dart`:
```dart
static const String baseUrl = 'YOUR_API_BASE_URL';
```

### Audio Permissions
The app automatically handles microphone permissions for voice recording.

## 📱 Screenshots

The app includes the following key screens:
- Onboarding with role selection
- Patient/Specialist registration forms
- Patient home with emotion detection toggle
- Voice recording interface
- Specialist dashboard with patient statistics
- Patient details with timeline of records
- Settings screens with accessibility options

## 🧪 Testing

### Manual Testing Scenarios
1. **Registration Flow**: Test both patient and specialist registration
2. **Voice Recording**: Verify audio recording and upload functionality
3. **Accessibility**: Test with screen reader enabled
4. **Emergency Flow**: Ensure emergency button works correctly
5. **Specialist Dashboard**: Verify patient data display and navigation

### Accessibility Testing
- Test with TalkBack (Android) or VoiceOver (iOS)
- Verify all buttons announce their purpose
- Ensure navigation works entirely through audio

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Open an issue on GitHub
- Contact the development team
- Check the documentation in the `/docs` folder

## 🙏 Acknowledgments

- Thanks to the accessibility community for their valuable feedback
- Flutter team for the excellent framework
- All contributors who helped make this app inclusive and accessible

---

**Emo Glasses - Bridging the gap between technology and human emotion for the visually impaired community.**

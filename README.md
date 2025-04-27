# Church Connect - Group Management App

A comprehensive Flutter application designed to streamline church group management, event coordination, and member communication.

![Church Connect App](assets/images/citam_logo.jpg)

## Overview

Church Connect is a multi-platform application that helps church administrators and members manage groups, coordinate events, and facilitate communication within the church community. The app provides different interfaces for super admins, group admins, and regular users, each with tailored functionality to meet their specific needs.

## Features

### For All Users
- **User Authentication**: Secure login, signup, and password reset functionality
- **Profile Management**: Create and update personal profiles
- **Region Selection**: 
  - Select your church region during profile setup
  - View detailed region information
  - See region assignments in user profiles
  - Filter groups and events by region
- **Group Membership**: View and interact with groups you belong to
- **Event Participation**: View upcoming events and manage attendance

### For Group Administrators
- **Group Management**: Create, edit, and manage church groups
- **Member Administration**: Add, remove, and manage group members
- **Event Creation**: Schedule and organize group events
- **Analytics Dashboard**: Track group attendance and engagement

### For Super Administrators
- **Church-wide Administration**: Manage all groups and users
- **Role Management**: Assign and modify user roles
- **Region Management**: 
  - Create, edit, and delete church regions
  - Add descriptive information to regions
  - Assign region managers
  - View region-specific analytics
  - Generate reports by region
- **System Configuration**: Configure app settings and permissions
- **Global Analytics**: Access comprehensive church-wide statistics

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase
- **Authentication**: Supabase Auth
- **Database**: PostgreSQL (via Supabase)
- **Storage**: Supabase Storage

## Installation

### Prerequisites
- Flutter SDK (version ^3.7.2)
- Dart SDK
- Android Studio / VS Code
- Git

### Setup Instructions

1. Clone the repository:
   ```
   git clone https://github.com/your-username/group_management_church_app.git
   ```

2. Navigate to the project directory:
   ```
   cd group_management_church_app
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Configure Supabase:
   - Create a `.env` file in the project root
   - Add your Supabase URL and API key:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

5. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── core/            # Core functionality and utilities
│   ├── auth/        # Authentication wrapper and services
│   ├── navigation/  # Navigation and routing
│   ├── theme/       # App theming
│   └── utils/       # Utility functions
├── data/
│   ├── models/      # Data models
│   ├── providers/   # State management
│   └── services/    # API and backend services
├── features/
│   ├── admin/       # Admin-specific screens
│   ├── auth/        # Authentication screens
│   ├── events/      # Event management
│   ├── super_admin/ # Super admin functionality
│   └── user/        # User-specific screens
└── widgets/         # Reusable UI components
```

## Organization Structure

### User Roles

1. **Super Admin**: Has complete control over the application, including user management, group creation, region management, and system configuration.

2. **Admin**: Manages specific groups, including member administration, event planning, and group-specific settings.

3. **User**: Regular church members who can join groups, view and RSVP to events, and interact with other group members.

### Regional Organization

The app uses a regional organization structure to better manage church groups and members:

1. **Regions**: Geographical or administrative divisions of the church (e.g., North Campus, South Campus, Youth Ministry)

2. **Groups**: Smaller units within regions (e.g., Bible Study Groups, Worship Teams, Service Groups)

3. **Members**: Individual church members assigned to specific regions and groups

This hierarchical structure allows for:
- Better organization of church activities
- Targeted communication to specific regions
- Region-specific analytics and reporting
- Simplified management of large church communities

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Your Name - Purity Sang
Email - puritysang180@gmail.com

Project Link: [https://github.com/purity-dev-614E/church_connect](https://github.com/your-username/group_management_church_app)

## Recent Updates

### Version 1.2.0 - Region Selection Feature

We've enhanced the app with a comprehensive region selection system:

- **User Experience Improvements**:
  - Redesigned region selection UI with improved visibility
  - Added "View All Regions" dialog for easier selection
  - Implemented region information display
  - Added success messages with region confirmation

- **Profile Integration**:
  - Region information now displayed in user profiles
  - Visual indicators for region assignment status
  - Region filtering throughout the app

- **Admin Tools**:
  - Enhanced region management interface
  - Region-specific analytics and reporting
  - Bulk user assignment to regions

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Supabase](https://supabase.io/)
- [Provider](https://pub.dev/packages/provider)
- [Google Fonts](https://pub.dev/packages/google_fonts)
- [FL Chart](https://pub.dev/packages/fl_chart)
- [Lottie](https://pub.dev/packages/lottie)

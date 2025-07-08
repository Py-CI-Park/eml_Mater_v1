# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a web-based email management application for .eml files, designed for closed network environments. The application consists of a Flask backend and React frontend, allowing users to browse, search, and manage .eml email files stored locally.

**Version**: 1.0 Stable Release  
**Last Updated**: 2025-07-08  
**Status**: Production Ready with Enhanced Installation System

## Installation and Setup

### Automated Installation (Recommended)
```bash
# For Windows users - Enhanced installation system with safety checks
# 1. Pre-installation check
설치전_체크리스트.bat  # Run as administrator

# 2. Environment cleanup (if needed)
환경정리.bat  # Run as administrator  

# 3. Main installation
INSTALL_SAFE.bat  # Run as administrator (English-based, most stable)
# OR
INSTALL.bat  # Run as administrator (Korean-based, enhanced stability)

# 4. Installation verification
설치검증.bat  # Run as administrator
```

### Development Commands

### Quick Start
```bash
# Run the entire application (after installation)
python run.py
# OR use the generated batch files
이메일관리자_실행.bat  # Auto-generated during installation
```

### Backend Development
```bash
# Install Python dependencies
cd backend
pip install -r requirements.txt

# Run Flask server
python app.py
# Server runs on http://localhost:5000
```

### Frontend Development
```bash
# Install Node.js dependencies
cd frontend
npm install

# Start React development server
npm start
# Server runs on http://localhost:3000

# Build production version
npm run build

# Run tests
npm test
```

## Architecture Overview

### Backend (Flask)
- **app.py**: Main Flask application with REST API endpoints
- **email_parser.py**: Email parsing logic for .eml files using Python's email library
- **models.py**: Database models and managers for SQLite (tags, search index, email status)
- **requirements.txt**: Python dependencies (Flask, Flask-CORS, email parsing libraries)

The backend provides RESTful APIs for:
- Configuration management (email folder paths)
- Folder browsing and email listing
- Full email content parsing with attachments
- Search functionality across email content
- Statistics and metadata management

### Frontend (React)
- **App.js**: Main application component with navigation and state management
- **components/**: Reusable UI components
  - **FolderTree.js**: Left sidebar for folder navigation
  - **EmailList.js**: Middle panel showing email list
  - **EmailViewer.js**: Right panel for email content display
  - **SearchBar.js**: Top search functionality
  - **Settings.js**: Configuration management UI
- **services/api.js**: Axios-based API client for backend communication
- **styles/**: CSS styling

### Key Technologies
- **Backend**: Flask 2.3.3, SQLite, email library for .eml parsing
- **Frontend**: React 18, Bootstrap 5, Axios for API calls, DOMPurify for HTML sanitization
- **Security**: CORS configured, HTML sanitization, localhost-only operation

### Data Flow
1. User configures email root folder path via Settings
2. Backend scans folder structure for .eml files
3. Email headers are parsed for quick listing
4. Full email content (including attachments) loaded on demand
5. Search functionality indexes email content in SQLite
6. Frontend displays three-panel layout: folders, email list, email viewer

### Configuration
- Backend configuration stored in `config.json`
- Frontend proxy configured to connect to backend on localhost:5000
- Database file: `email_manager.db` (SQLite)

## Important Notes

- The application is designed for security in closed networks (localhost only)
- Email parsing handles various encodings and MIME types
- Attachments are extracted and served through temporary files
- Search functionality supports subject, sender, and body content
- Database maintains email status (read/unread, starred) and tags for future features

## Installation System Architecture

### Enhanced Installation Tools (New in v1.0)
- **설치전_체크리스트.bat**: Pre-installation system verification
  - Admin privileges check
  - Disk space verification  
  - Port conflict detection
  - Antivirus interference check
  - Internet connectivity test
  - System requirements validation

- **환경정리.bat**: Complete environment cleanup
  - Removes corrupted installations
  - Backs up existing configurations
  - Cleans Python virtual environments
  - Removes Node.js modules
  - Terminates conflicting processes
  - Prepares clean installation environment

- **INSTALL_SAFE.bat**: English-based stable installer
  - Enhanced error handling
  - Safe logging system
  - Step-by-step progress tracking
  - Automatic rollback on failures
  - Memory-safe progress bars
  - Comprehensive validation

- **INSTALL.bat**: Korean-based enhanced installer
  - All INSTALL_SAFE.bat features
  - Korean language interface
  - Cultural localization
  - Enhanced user experience

- **단계별검증.bat**: Step-by-step installation validator
  - Individual component testing
  - Selective re-installation
  - Granular problem diagnosis
  - Independent step verification

- **설치검증.bat**: Comprehensive post-installation verification
  - Full system validation
  - Server startup testing
  - Database connectivity check
  - Port availability verification
  - Configuration validation

### Installation Safety Features
- **Infinite Loop Prevention**: Progress bars with safety limits
- **Memory Management**: Log file size limits and rotation
- **Error Recovery**: Automatic backup and rollback mechanisms  
- **Process Management**: Safe termination of conflicting services
- **Log System**: Comprehensive audit trail with .log files
- **Admin Verification**: Automatic privilege escalation requests

### Troubleshooting Tools
- **로그테스트.bat**: Log file creation testing
- **배치파일_테스트.bat**: Batch file validation utility
- **설치가이드.txt**: Comprehensive troubleshooting guide

## File Structure and Git Management

### Key Files and Directories
```
eml_Mater_v1/
├── backend/                 # Flask backend application
│   ├── app.py              # Main Flask application
│   ├── email_parser.py     # Email parsing logic
│   ├── models.py           # Database models
│   ├── requirements.txt    # Python dependencies
│   └── config.json*        # Configuration (gitignored)
├── frontend/               # React frontend application  
│   ├── src/                # React source code
│   ├── public/             # Static assets
│   ├── package.json        # Node.js dependencies
│   └── node_modules/*      # Dependencies (gitignored)
├── installation/           # Installation tools
│   ├── INSTALL_SAFE.bat    # English installer
│   ├── INSTALL.bat         # Korean installer
│   ├── 환경정리.bat        # Cleanup utility
│   ├── 설치검증.bat        # Verification tool
│   └── 설치가이드.txt      # User guide
├── .gitignore             # Git exclusion rules
├── CLAUDE.md              # This file
└── README.md              # Project documentation
```

### Git Exclusions (.gitignore)
The project excludes sensitive and generated files:
- **Virtual environments**: `venv/`, `.env/`
- **Dependencies**: `node_modules/`, `package-lock.json`
- **Databases**: `*.db`, `email_manager.db`
- **Configuration**: `config.json`, sensitive settings
- **Logs**: `*.log`, installation logs, debug files
- **Temporary files**: Build artifacts, cache files
- **User data**: Email files, test folders
- **System files**: OS-specific files, IDE settings
- **Security**: API keys, certificates, secrets

## Development Guidelines

### Code Quality Standards
- **Error Handling**: Comprehensive try-catch blocks with logging
- **Security**: Input validation, SQL injection prevention
- **Performance**: Efficient email parsing, lazy loading
- **Logging**: Structured logging with timestamps
- **Testing**: Unit tests for critical components
- **Documentation**: Inline comments and API documentation

### Installation Development
- **Safety First**: All batch files must prevent infinite loops
- **Error Recovery**: Implement rollback mechanisms
- **User Experience**: Clear progress indication and error messages
- **Compatibility**: Support various Windows versions and configurations
- **Logging**: Comprehensive audit trails for debugging

### Security Considerations
- **Network Isolation**: Localhost-only operation for closed networks
- **Input Sanitization**: HTML/script sanitization for email content
- **File Access**: Restricted to configured email directories
- **Process Isolation**: Separate frontend/backend processes
- **Configuration Security**: Sensitive data excluded from version control

## Important Notes for Developers

### Installation Issues Resolution
This project has undergone major stability improvements to resolve installation termination issues:

1. **Previous Issues (Resolved)**:
   - INSTALL.bat terminating mid-execution
   - Corrupted log files (binary data)
   - Unicode character problems in batch files
   - Infinite loops in progress_bar functions
   - Memory overflow in logging systems

2. **Current Solution**:
   - Enhanced installation system with multiple tools
   - Safe progress bars with loop prevention
   - Memory-managed logging with size limits
   - Comprehensive error handling and recovery
   - Multiple installation methods for different scenarios

### GitHub Repository Preparation
- All sensitive files excluded via comprehensive .gitignore
- Installation logs and temporary files not tracked
- User data and configuration files properly excluded
- Dependencies (node_modules, venv) excluded from repository
- Database files and user content excluded for security

### Deployment Notes
- Users must run installation tools locally after cloning
- Configuration files will be generated during installation
- Virtual environments created locally, not in repository
- Database created on first run, not included in repository
- All user-specific data excluded from version control

### Testing and Validation
- Use 로그테스트.bat to verify log file creation capability
- Run 설치전_체크리스트.bat before installation
- Use 단계별검증.bat for granular problem diagnosis
- Complete verification with 설치검증.bat after installation

### Maintenance Guidelines
- Regular testing of installation tools on clean systems
- Validation of .gitignore rules for new file types
- Documentation updates for new features
- Security review of excluded sensitive files
- Performance monitoring of installation processes
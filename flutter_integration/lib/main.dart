import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'screens/registration_screen.dart';
import 'screens/chat_screen.dart';
import 'models/user_profile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le service API
  ApiService.init();
  
  runApp(EasyHealthApp());
}

class EasyHealthApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: MainScreen(),
      routes: {
        '/registration': (context) => RegistrationScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/chat': (context) => ChatScreen(otherUser: UserProfile(id: '', fullName: '', email: '', role: 'patient', isApproved: true, createdAt: DateTime.now(), updatedAt: DateTime.now())),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isConnected = false;
  bool _isCheckingConnection = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final isConnected = await ApiService.testConnection();
      setState(() {
        _isConnected = isConnected;
        _isCheckingConnection = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isCheckingConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingConnection) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vérification de la connexion...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('EasyHealth'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.medical_services,
                  size: 60,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
            SizedBox(height: 32),

            // Status
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
                border: Border.all(
                  color: _isConnected ? Colors.green.shade200 : Colors.red.shade200,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected ? 'Backend Connecté' : 'Backend Non Connecté',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        Text(
                          _isConnected 
                              ? 'L\'API EasyHealth est accessible'
                              : 'Vérifiez que le backend est démarré sur localhost:4000',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Actions
            if (_isConnected) ...[
              _buildActionButton(
                'Créer un Compte',
                Icons.person_add,
                Colors.blue,
                () => Navigator.pushNamed(context, '/registration'),
              ),
              SizedBox(height: 12),
              _buildActionButton(
                'Se Connecter',
                Icons.login,
                Colors.green,
                () => Navigator.pushNamed(context, '/login'),
              ),
              SizedBox(height: 12),
              _buildActionButton(
                'Tester la Messagerie',
                Icons.chat,
                Colors.purple,
                () => Navigator.pushNamed(context, '/chat'),
              ),
            ] else ...[
              _buildActionButton(
                'Actualiser',
                Icons.refresh,
                Colors.orange,
                _checkConnection,
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pour démarrer le backend:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Ouvrir un terminal dans le dossier backend\n2. Exécuter: node server.js\n3. Attendre "EasyHealth API listening on port 4000"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Connexion',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                obscureText: true,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement login
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text('Se Connecter'),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/registration');
              },
              child: Text('Pas encore de compte? S\'inscrire'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EasyHealth'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Bienvenue sur EasyHealth!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Fonctionnalités disponibles:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            _buildFeatureItem('✅ Inscription par rôle (Patient, Médecin, Pharmacie, Lab)'),
            _buildFeatureItem('✅ Messagerie avec envoi d\'images'),
            _buildFeatureItem('✅ Demandes de livraison (Patient → Pharmacie)'),
            _buildFeatureItem('✅ Authentification JWT sécurisée'),
            _buildFeatureItem('✅ Base de données nettoyée'),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                child: Text('Tester la Messagerie'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

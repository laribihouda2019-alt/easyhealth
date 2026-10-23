import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specializationController = TextEditingController();
  final _communeController = TextEditingController(); // For non-Oran communees

  UserRole _selectedRole = UserRole.patient;
  PlatformFile? _selectedDocument;
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _selectedWilaya = 'Oran';
  String? _selectedCommune;

  final List<String> _wilayas = ['Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna', 'Bejaia', 'Biskra', 'Bechar', 'Blida', 'Bouira', 'Tamanrasset', 'Tebessa', 'Tlemcen', 'Tiaret', 'Tizi Ouzou', 'Alger', 'Djelfa', 'Jijel', 'Setif', 'Saida', 'Skikda', 'Sidi Bel Abbes', 'Annabba', 'Guelma', 'Constantine', 'Medea', 'Mostaganem', 'M\'Sila', 'Mascara', 'Ouargla', 'Oran', 'El Bayadh', 'Illizi', 'Bordj Bou Arreridj', 'Boumerdes', 'El Tarf', 'Tindouf', 'Tissemsilt', 'El Oued', 'Khenchela', 'Souk Ahras', 'Tipaza', 'Mila', 'Ain Defla', 'Naama', 'Ain Temouchent', 'Ghardaia', 'Relizane'];
  
  final List<String> _oranCommunes = [
    'Bir El Djir',
    'Es-Senia',
    'Akid Lotfi',
    'Canastel',
    'Maraval',
    'Centre Ville'
  ];

  bool get _requiresDocument =>
      _selectedRole == UserRole.doctor ||
      _selectedRole == UserRole.pharmacy ||
      _selectedRole == UserRole.lab;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _specializationController.dispose();
    _communeController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedDocument = result.files.first);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_requiresDocument && _selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez telecharger votre document justificatif'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final communeToSave = _selectedWilaya == 'Oran' 
          ? (_selectedCommune ?? 'Autre') 
          : _communeController.text.trim().isNotEmpty 
              ? _communeController.text.trim() 
              : 'Autre';

      
      
      
      

      await AuthService().register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: _selectedRole.value,
        wilaya: _selectedWilaya,
        commune: communeToSave,
        extraFields: _selectedRole == UserRole.doctor 
            ? {'specialization': _specializationController.text.trim()} 
            : _selectedRole == UserRole.pharmacy
                ? {'pharmacyName': _fullNameController.text.trim()}
                : _selectedRole == UserRole.lab
                    ? {'labName': _fullNameController.text.trim()}
                    : null,
      );

      if (_requiresDocument && _selectedDocument != null) {
        await ApiService().createVerificationRequest(
          roleRequested: _selectedRole.value,
          documentType: 'credential',
          documentUrl: _selectedDocument!.name,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _requiresDocument
                ? 'Inscription envoyee! En attente de validation admin.'
                : 'Inscription reussie!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Creer un compte'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Rejoignez EasyHealth',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez votre role et completez vos informations',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items:
                          [
                            UserRole.patient,
                            UserRole.doctor,
                            UserRole.pharmacy,
                            UserRole.lab,
                          ].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.displayName),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                            _selectedDocument = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    if (_selectedRole == UserRole.doctor) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specializationController,
                        decoration: InputDecoration(
                          labelText: 'Specialisation',
                          hintText: 'ex: Cardiologue, Generaliste...',
                          prefixIcon: const Icon(Icons.psychology_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedRole == UserRole.doctor &&
                              (value == null || value.isEmpty)) {
                            return 'Veuillez indiquer votre specialite';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre email';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedWilaya,
                      decoration: InputDecoration(
                        labelText: 'Wilaya',
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _wilayas.map((w) {
                        return DropdownMenuItem(value: w, child: Text(w));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedWilaya = value;
                            _selectedCommune = null; // reset commune
                          });
                        }
                      },
                    ),
                    if (_selectedWilaya == 'Oran') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCommune,
                        decoration: InputDecoration(
                          labelText: 'Commune (District)',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _oranCommunes.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCommune = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez choisir votre quartier';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _communeController,
                        decoration: InputDecoration(
                          labelText: 'Commune (Ville)',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez préciser votre commune';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un mot de passe';
                        }
                        if (value.length < 6) {
                          return 'Minimum 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    if (_requiresDocument) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Document justificatif',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Telecharger votre certificat, diplome ou agrement',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDocument,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _selectedDocument?.name ?? 'Choisir un fichier',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ce document sera verifie par un administrateur avant activation de votre compte.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Creer mon compte',
                      isLoading: _isLoading,
                      onPressed: _handleSignup,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



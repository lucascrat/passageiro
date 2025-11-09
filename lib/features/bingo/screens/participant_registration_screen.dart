import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/participant_model.dart';
import '../services/participant_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipantRegistrationScreen extends StatefulWidget {
  const ParticipantRegistrationScreen({super.key});

  @override
  State<ParticipantRegistrationScreen> createState() => _ParticipantRegistrationScreenState();
}

class _ParticipantRegistrationScreenState extends State<ParticipantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pixController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  ParticipantService? _participantService;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    try {
      final supabase = Supabase.instance.client;
      _participantService = ParticipantService(supabase);
      _loadExistingParticipant();
    } catch (e) {
      print('Erro ao inicializar serviço: $e');
    }
  }

  Future<void> _loadExistingParticipant() async {
    if (_participantService == null) return;
    
    try {
      final participant = await _participantService!.getCurrentParticipant();
      if (participant != null && mounted) {
        setState(() {
          _nameController.text = participant.name;
          _phoneController.text = participant.phone;
          _pixController.text = participant.pixKey;
          _isEditing = true;
        });
      }
    } catch (e) {
      print('Erro ao carregar participante: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pixController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    if (value.trim().length > 50) {
      return 'Nome deve ter no máximo 50 caracteres';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefone é obrigatório';
    }
    if (!ParticipantService.isValidPhone(value)) {
      return 'Formato inválido. Use: (11) 99999-9999';
    }
    return null;
  }

  String? _validatePixKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Chave PIX é obrigatória';
    }
    if (!ParticipantService.isValidPixKey(value)) {
      return 'Chave PIX inválida. Use CPF, telefone, email ou chave aleatória';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _participantService == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final form = ParticipantForm(
        name: _nameController.text,
        phone: _phoneController.text,
        pixKey: _pixController.text,
      );

      if (_isEditing) {
        await _participantService!.updateParticipant(form);
      } else {
        await _participantService!.registerParticipant(form);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Dados atualizados com sucesso!' : 'Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Voltar para a tela de Bingo
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Dados' : 'Cadastro de Participante',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF9C27B0),
              Color(0xFFF5F5F5),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Card principal
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ícone e título
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          _isEditing 
                              ? 'Atualize seus dados para continuar jogando'
                              : 'Preencha seus dados para participar do Bingo',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Campo Nome
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome ou Apelido',
                            hintText: 'Digite seu nome ou apelido',
                            prefixIcon: const Icon(Icons.person, color: Color(0xFF9C27B0)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                          ),
                          validator: _validateName,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Campo Telefone
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Telefone',
                            hintText: '(11) 99999-9999',
                            prefixIcon: const Icon(Icons.phone, color: Color(0xFF9C27B0)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                          ),
                          validator: _validatePhone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                            _PhoneInputFormatter(),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Campo PIX
                        TextFormField(
                          controller: _pixController,
                          decoration: InputDecoration(
                            labelText: 'Chave PIX',
                            hintText: 'CPF, telefone, email ou chave aleatória',
                            prefixIcon: const Icon(Icons.pix, color: Color(0xFF9C27B0)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF9C27B0), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                          ),
                          validator: _validatePixKey,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Botão de submit
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFFFFD700)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9C27B0).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isEditing ? 'ATUALIZAR DADOS' : 'CADASTRAR',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Texto informativo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFF9C27B0),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Seus dados são necessários para o pagamento de prêmios via PIX.',
                                  style: TextStyle(
                                    color: const Color(0xFF9C27B0),
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length <= 2) {
      return newValue;
    }
    
    String formatted = '';
    
    if (text.length <= 2) {
      formatted = '($text';
    } else if (text.length <= 6) {
      formatted = '(${text.substring(0, 2)}) ${text.substring(2)}';
    } else if (text.length <= 10) {
      formatted = '(${text.substring(0, 2)}) ${text.substring(2, 6)}-${text.substring(6)}';
    } else {
      formatted = '(${text.substring(0, 2)}) ${text.substring(2, 7)}-${text.substring(7, 11)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
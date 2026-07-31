import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme/theme_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/app_card.dart';
import '../utils/responsive.dart';

class PatientInformationModal extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic> patient) onSaved;

  const PatientInformationModal({
    super.key,
    this.initialData,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
    required Function(Map<String, dynamic> patient) onSaved,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PatientInformationModal(
        initialData: initialData,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<PatientInformationModal> createState() => _PatientInformationModalState();
}

class _PatientInformationModalState extends State<PatientInformationModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _qualificationController;
  late TextEditingController _ageController;
  late TextEditingController _notesController;

  String _gender = 'Male';
  bool _isLoading = false;
  String? _errorMessage;

  // Duplicate detection state
  Map<String, dynamic>? _duplicatePatient;
  bool _showDuplicatePrompt = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _qualificationSuggestions = [
    'Student',
    'Engineer',
    'Teacher',
    'Doctor',
    'Business',
    'Software Developer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _firstNameController = TextEditingController(text: data?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: data?['last_name'] ?? '');
    _phoneController = TextEditingController(text: data?['phone_number'] ?? '');
    _qualificationController = TextEditingController(text: data?['qualification'] ?? '');
    _ageController = TextEditingController(text: data?['age']?.toString() ?? '');
    _notesController = TextEditingController(text: data?['notes'] ?? '');

    if (data?['gender'] != null && _genderOptions.contains(data!['gender'])) {
      _gender = data['gender'];
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final fn = _firstNameController.text.trim();
    final ln = _lastNameController.text.trim();
    return fn.isNotEmpty && ln.isNotEmpty && _gender.isNotEmpty;
  }

  Future<void> _submitForm({bool forceCreate = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'gender': _gender,
      'phone_number': _phoneController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'age': _ageController.text.trim().isEmpty ? null : int.tryParse(_ageController.text.trim()),
      'notes': _notesController.text.trim(),
    };

    try {
      final isEdit = widget.initialData?['id'] != null;
      Map<String, dynamic> result;

      if (isEdit) {
        final patientId = widget.initialData!['id'];
        result = await ApiService.updatePatient(patientId, payload);
      } else {
        result = await ApiService.createPatient(payload, forceCreate: forceCreate);
      }

      if (!mounted) return;

      if (result['success'] == true) {
        if (result['is_duplicate'] == true && !forceCreate) {
          setState(() {
            _isLoading = false;
            _duplicatePatient = result['existing_patient'];
            _showDuplicatePrompt = true;
          });
          return;
        }

        final patientData = result['patient'] ?? result['existing_patient'];
        widget.onSaved(patientData);

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Patient information updated successfully.'
                  : 'Patient information saved successfully.',
            ),
            backgroundColor: ThemeColors.success(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Failed to save patient details.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isPhone = Responsive.isPhone(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      elevation: 10,
      backgroundColor: ThemeColors.surface(context),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 16 : 40,
        vertical: isPhone ? 24 : 40,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ThemeColors.primary(context).withValues(alpha: 0.1),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Icon(
                          widget.initialData != null ? Icons.edit_note : Icons.person_add_outlined,
                          color: ThemeColors.primary(context),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.initialData != null ? 'Edit Patient Information' : 'Patient Registration',
                              style: AppTypography.cardTitle(context).copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Complete required clinical records before AI diagnostic scanning.',
                              style: AppTypography.caption(context),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ThemeColors.error(context).withValues(alpha: 0.1),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: ThemeColors.error(context).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: ThemeColors.error(context), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.caption(context).copyWith(
                                color: ThemeColors.error(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Duplicate Patient Alert Prompt
                  if (_showDuplicatePrompt && _duplicatePatient != null) ...[
                    AppCard(
                      color: ThemeColors.warning(context).withValues(alpha: 0.08),
                      border: BorderSide(color: ThemeColors.warning(context).withValues(alpha: 0.4)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: ThemeColors.warning(context)),
                              const SizedBox(width: 10),
                              Text(
                                'Duplicate Patient Found',
                                style: AppTypography.cardTitle(context).copyWith(
                                  color: ThemeColors.warning(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A patient matching these details already exists:',
                            style: AppTypography.caption(context),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ThemeColors.surface(context),
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(color: ThemeColors.border(context)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 18, color: ThemeColors.secondaryText(context)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_duplicatePatient!['full_name']} (${_duplicatePatient!['patient_code']}) • Phone: ${_duplicatePatient!['phone_number']}',
                                    style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Use Existing Patient',
                                  icon: Icons.check_circle_outline,
                                  height: 38,
                                  onPressed: () {
                                    widget.onSaved(_duplicatePatient!);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Create New Record',
                                  icon: Icons.person_add_alt_1_outlined,
                                  variant: PrimaryButtonVariant.outlined,
                                  height: 38,
                                  onPressed: () => _submitForm(forceCreate: true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields Layout (Responsive 2-column or 1-column)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useTwoCol = constraints.maxWidth > 500;

                      if (useTwoCol) {
                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildFirstNameField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildLastNameField()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildGenderField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildPhoneField()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildQualificationField()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildAgeField()),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _buildFirstNameField(),
                          const SizedBox(height: 16),
                          _buildLastNameField(),
                          const SizedBox(height: 16),
                          _buildGenderField(),
                          const SizedBox(height: 16),
                          _buildPhoneField(),
                          const SizedBox(height: 16),
                          _buildQualificationField(),
                          const SizedBox(height: 16),
                          _buildAgeField(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildNotesField(),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Actions Footer (Cancel & Save Buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PrimaryButton(
                        label: 'Cancel',
                        variant: PrimaryButtonVariant.outlined,
                        fullWidth: false,
                        height: 42,
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      PrimaryButton(
                        label: _isLoading
                            ? 'Saving...'
                            : (widget.initialData != null ? 'Update Patient' : 'Save Patient'),
                        icon: Icons.save_outlined,
                        isLoading: _isLoading,
                        fullWidth: false,
                        height: 42,
                        onPressed: (_isFormValid && !_isLoading) ? () => _submitForm() : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstNameController,
      decoration: const InputDecoration(
        labelText: 'First Name *',
        hintText: 'e.g. John',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'First Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastNameController,
      decoration: const InputDecoration(
        labelText: 'Last Name *',
        hintText: 'e.g. Smith',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Last Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: const InputDecoration(
        labelText: 'Gender *',
        prefixIcon: Icon(Icons.wc_outlined),
      ),
      items: _genderOptions
          .map((g) => DropdownMenuItem(
                value: g,
                child: Text(g),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _gender = val;
          });
        }
      },
      validator: (val) => val == null || val.isEmpty ? 'Gender is required' : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Phone Number',
        hintText: 'e.g. 9876543210',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty && value.trim().length < 7) {
          return 'Phone Number is invalid';
        }
        return null;
      },
    );
  }

  Widget _buildQualificationField() {
    return RawAutocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _qualificationSuggestions;
        }
        return _qualificationSuggestions.where((option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _qualificationController.text = selection;
      },
      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
        if (textEditingController.text != _qualificationController.text && _qualificationController.text.isNotEmpty) {
          textEditingController.text = _qualificationController.text;
        }
        textEditingController.addListener(() {
          _qualificationController.text = textEditingController.text;
        });

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Qualification',
            hintText: 'e.g. Engineer, Student, Doctor',
            prefixIcon: Icon(Icons.school_outlined),
          ),
        );
      },
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: AppRadius.borderMd,
            child: SizedBox(
              width: 250,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Age',
        hintText: 'e.g. 28',
        prefixIcon: Icon(Icons.cake_outlined),
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final val = int.tryParse(value.trim());
          if (val == null || val < 1 || val > 120) {
            return 'Enter valid age (1-120)';
          }
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Clinical Notes (Optional)',
        hintText: 'Add initial notes or patient symptoms...',
        prefixIcon: Icon(Icons.notes_outlined),
      ),
    );
  }
}

import 'dart:io';

import 'package:assureflex/core/utils/app_snack.dart';
import 'package:assureflex/data/repositories/auth_repository.dart';
import 'package:assureflex/presentation/widgets/claim_form/instructions_dialog.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../data/repositories/claim_repository.dart';
import '../../widgets/common/cirlce_checkbox.dart';
import '../../widgets/common/custom_button.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


class ClaimForm extends StatefulWidget {
  const ClaimForm({super.key});

  @override
  State<ClaimForm> createState() => _ClaimFormState();
}

class _ClaimFormState extends State<ClaimForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isAgreed = false;

  // Controllers for Participant Identification
  final _companyNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Controllers for Confirmation Section
  final _dateController = TextEditingController();
  final _ymd = DateFormat('yyyy-MM-dd');

  // Employee Reimbursement Section
  final List<Map<String, TextEditingController>> _employeeReimbursements = [];

  // Provider Payment Section
  final List<Map<String, TextEditingController>> _providerPayments = [];

  double _ppTotal = 0; // participants total
  double _spTotal = 0; // providers total
  double _formTotal = 0; // grand total

  final Set<TextEditingController> _feeControllersListening = {};

  File? _signatureFile;
  final List<PlatformFile> _documents = [];
  bool _submitting = false;

  final _imagePicker = ImagePicker();

  final _authRepo = AuthRepository();
  bool signingOut = false;


  @override
  void initState() {
    super.initState();
    _addEmployeeReimbursement();
    _addProviderPayment();
    _attachFeeListeners();
  }
  Future<void> _pickSignatureDate() async {
    // if controller has a value, use it as initial
    DateTime initial = DateTime.now();
    try {
      if (_dateController.text.trim().isNotEmpty) {
        initial = DateTime.parse(_dateController.text.trim());
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Date of Signature',
    );
    if (picked != null) {
      _dateController.text = _ymd.format(picked); // always YYYY-MM-DD
      setState(() {}); // if your UI needs refresh
    }
  }
  Future<void> _pickSignature() async {
    // bottom sheet for camera/gallery (you can keep gallery only if you prefer)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ],
        ),
      ),
    );

    if (source == null) return;
    final x = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (x != null) {
      setState(() => _signatureFile = File(x.path));
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf','doc', 'docx'],
    );
    if (result == null) return;
    setState(() {
      _documents.addAll(result.files.where((f) => f.path != null));
    });
  }

  void _removeDocumentAt(int i) {
    setState(() => _documents.removeAt(i));
  }

  void _addEmployeeReimbursement() {
    setState(() {
      _employeeReimbursements.add({
        'claimantLastName': TextEditingController(),
        'claimantFirstName': TextEditingController(),
        'relationship': TextEditingController(),
        'fee': TextEditingController(),
      });
    });
    _attachFeeListeners();
  }

  void _addProviderPayment() {
    setState(() {
      _providerPayments.add({
        'providerName': TextEditingController(),
        'providerAddress': TextEditingController(),
        'claimantLastName': TextEditingController(),
        'claimantFirstName': TextEditingController(),
        'relationship': TextEditingController(),
        'fee': TextEditingController(),
      });
    });
    _attachFeeListeners();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();

    for (var controllers in _employeeReimbursements) {
      controllers.values.forEach((c) => c.dispose());
    }
    for (var controllers in _providerPayments) {
      controllers.values.forEach((c) => c.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.grey100,width: 2))
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Image.asset(
                  'assets/logo.png',
                  height: 40,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.medical_services, color: AppColors.primary),
                ),
          TextButton(
            onPressed: () => InstructionsDialog.show(context),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.grey100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
              minimumSize: Size.zero, // remove default min size
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline, size: 16, color: Color(0xff656565)),
                SizedBox(width: 5), // precise control over icon–label spacing
                Text('Instruction', style: TextStyle(fontSize: 13, color: Color(0xff656565))),
              ],
            ),
          ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: AppSizes.lg,
                      ),
                      child: const Text(
                        'Online Claims Submission Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
              
                    // Main Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Participant Identification Section
                            _buildSectionCard(
                              title: 'Participant Identification',
                              child: Column(
                                children: [
                                  _buildSimpleTextField(
                                      hint: 'Enter Name of Company Employed By',
                                      controller: _companyNameController,
                                      required:true
                                  ),
                                  SizedBox(height: AppSizes.md),
                                  _buildSimpleTextField(
                                    hint: 'Enter Your First Name',
                                    controller: _firstNameController,
                                      required:true
                                  ),
                                  SizedBox(height: AppSizes.md),
                                  _buildSimpleTextField(
                                    hint: 'Enter Your Middle Initial',
                                    controller: _middleInitialController,
                                  ),
                                  SizedBox(height: AppSizes.md),
                                  _buildSimpleTextField(
                                    hint: 'Enter Your Last Name',
                                    controller: _lastNameController,
                                      required:true
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSizes.lg),
              
                            // Confirmation, Authorization and Signature Section
                            _buildSectionCard(
                              title: 'Confirmation, Authorization and Signature',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleCheckbox(
                                        value: _isAgreed,
                                        onChanged: (v) => setState(() => _isAgreed = v),
                                      ),
                                      SizedBox(width: AppSizes.sm),
                                      Expanded(
                                        child: true?const Text(
                                          'I certify that the information provided on this form is correct to my knowledge and that all goods and services have been received and used by me, My spouse and/or dependents, and that the claims submitted here are for myself, my spouse or dependents; and that the claims submitted here are for myself, my spouse or dependents as defined as eligible under the terms of this plan, as outlined in your employee benefit booklet.',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87),
                                        ):RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.black87,
                                              height: 1.5,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: 'I certify that the information provided on this form is correct to my knowledge and that all goods and services have been received. I understand ',
                                              ),
                                              TextSpan(
                                                text: 'that reimbursements will be made against ',
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              TextSpan(
                                                text: 'that the claims submitted here are for myself, my spouse or dependents, and that the claims submitted here is in ',
                                              ),
                                              TextSpan(
                                                text: 'compliance with the terms of the plan, as outlined in my employer benefit booklet.',
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSizes.xl),
            
                                  // Signature Upload
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Signature of Eligible Employee',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                                            ),
                                            SizedBox(height: AppSizes.sm),
                                            Container(
                                              height: 57,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(AppSizes.radiusSm), // softer corners like Figma
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: _pickSignature,
                                                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                                    child: Row(
                                                      children: [
                                                        // Left placeholder / selected state
                                                        Expanded(
                                                          child: Text(
                                                            _signatureFile == null
                                                                ? 'Signature of Eligible Employee'
                                                                : '1 image selected',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: _signatureFile == null ? AppColors.greyText : Colors.black87,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
            
                                                        // Right: icon + link text (Figma color #8FA4B5)
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Image.asset('assets/icons/download.png',width: 12),
                                                            const SizedBox(width: 6),
                                                          ],
                                                        ),
                                                        Text(
                                                          _signatureFile == null ? 'Upload image' : 'Change',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            decoration: TextDecoration.underline,
                                                            decorationColor: Color(0xFF8FA4B5),
                                                            color: Color(0xFF8FA4B5), // #8FA4B5
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSizes.lg),
              
                                  _buildSimpleTextField(
                                    hint: 'Enter Date of Signature',
                                    controller: _dateController,
                                    isDate: true
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSizes.lg),
              
                            // Employee Reimbursement Section
                            _buildSectionCard(
                              title: 'Employee Reimbursement Section:',
                              subtitle: 'Payment to Plan Participant',
                              child: Column(
                                children: [
                                  ListView.separated(
                                    shrinkWrap:true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, i) {
                                        final item =_employeeReimbursements[i];
                                        return Column(
                                          children: [
                                            if(i>0)Align(alignment: Alignment.topRight,child: IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: (){
                                                final row = _employeeReimbursements[i];
                                                _detachFeeListenersOfRow(row);
                                                _employeeReimbursements.removeAt(i);
                                                _recalcTotals();
                                              },
                                            )),
                                            _buildSimpleTextField(
                                              hint: "Enter Claimant's Last Name",
                                              controller: item['claimantLastName'],
                                            ),
                                            SizedBox(height: AppSizes.md),
                                            _buildSimpleTextField(
                                              hint: "Enter Claimant's First Name",
                                              controller: item['claimantFirstName'],
                                            ),
                                            SizedBox(height: AppSizes.md),
                                            _buildSimpleTextField(
                                              hint: 'Enter Relationship to Employee',
                                              controller: item['relationship'],
                                            ),
                                            SizedBox(height: AppSizes.md),
                                            totalAmountTextField('Enter Total of Receipts this claimant',item['fee'])
                                          ],
                                        );
                                      },
                                      separatorBuilder:(ctx, i) => Divider(height: 35,color: Colors.grey[300]),
                                      itemCount: _employeeReimbursements.length),
              
                                  SizedBox(height: AppSizes.xl),
              
                                  CustomButton(
                                    text: 'Click to Add Additional Claimant',
                                    onPressed: _addEmployeeReimbursement,
                                    type: ButtonType.secondary,
                                    size: ButtonSize.medium,
                                  ),
              
                                  SizedBox(height: AppSizes.lg),
              
                                  _buildAmountDisplay('Reimbursement to Plan Participant', '\$$_ppTotal'),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSizes.lg),
              
                            // Provider Payment Section
                            _buildSectionCard(
                              title: 'Provider Payment Section:',
                              subtitle: 'Payment Assigned to Provider',
                              child: Column(
                                children: [
                                  ListView.separated(
                                    shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder:(ctx, i){
                                        final item = _providerPayments[i];
                                        return Column(
                                          children: [
                                            if(i>0)Align(alignment: Alignment.topRight,child: IconButton(
                                              icon: Icon(Icons.close),
                                              onPressed: (){
                                                final row = _providerPayments[i];
                                                _detachFeeListenersOfRow(row);
                                                _providerPayments.removeAt(i);
                                                _recalcTotals();
                                              },
                                            )),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildSimpleTextField(
                                                    hint: 'Name of Service Provider',
                                                    controller: item['providerName'],
                                                  ),
                                                ),
                                                SizedBox(width: AppSizes.md),
                                                Expanded(
                                                  child: _buildSimpleTextField(
                                                    hint: 'Address of Service Provider',
                                                    controller: item['providerAddress'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: AppSizes.md),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildSimpleTextField(
                                                    hint: 'Last Name of Claimant',
                                                    controller: item['claimantLastName'],
                                                  ),
                                                ),
                                                SizedBox(width: AppSizes.md),
                                                Expanded(
                                                  child: _buildSimpleTextField(
                                                    hint: 'First Name of Claimant',
                                                    controller: item['claimantFirstName'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: AppSizes.md),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildSimpleTextField(
                                                    hint: 'Relationship to Employee',
                                                    controller: item['relationship'],
                                                  ),
                                                ),
                                                SizedBox(width: AppSizes.md),
                                                Expanded(
                                                  child: totalAmountTextField('Total amount this claimant',item['fee'])
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                      separatorBuilder:(ctx, i) => Divider(height: 35,color: Colors.grey[300]),
                                      itemCount: _providerPayments.length),
                                  SizedBox(height: AppSizes.md),
              
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: AppSizes.xs),
                                      Expanded(
                                        child: Text(
                                          "Don't complete section unless funds are to be paid to provider.",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
              
                                  SizedBox(height: AppSizes.xl),
              
                                  CustomButton(
                                    text: 'Click to Add Additional Claimant',
                                    onPressed: _addProviderPayment,
                                    type: ButtonType.secondary,
                                    size: ButtonSize.medium,
                                  ),
              
                                  SizedBox(height: AppSizes.lg),
              
                                  _buildAmountDisplay('Reimbursements To Service Providers', '\$$_spTotal'),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSizes.lg),
              
                            // Total Reimbursements
                            _buildAmountDisplay('Total Reimbursements this Claim', '\$$_formTotal',isTotal:true),
              
                            SizedBox(height: AppSizes.xl),
              
                            // Upload Documents Section
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppSizes.xl),
                              decoration: BoxDecoration(
                                color: AppColors.grey100,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Upload Documents',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: AppSizes.lg),
              
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.outline,
                                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _pickDocuments,
                                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppSizes.lg,
                                            vertical: AppSizes.md,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Icon(
                                              //   Icons.upload_file_outlined,
                                              //   color: Colors.grey[600],
                                              //   size: 20,
                                              // ),
                                              Image.asset('assets/icons/download.png',color: Colors.grey[600],width: 13),
                                              SizedBox(width: AppSizes.sm),
                                              Text(
                                                'Upload Image',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  decoration: TextDecoration.underline,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppSizes.md),
                                  if (_documents.isNotEmpty)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: List.generate(_documents.length, (i) {
                                        final f = _documents[i];
                                        return Chip(
                                          label: Text(
                                            f.name,
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () => _removeDocumentAt(i),
                                        );
                                      }),
                                    ),
            
              
                                  Text(
                                    'Tap to Open Document Files on your Device.\nSelect the Medical Receipts and other\nsupporting Documents.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
              
                            SizedBox(height: AppSizes.xl),
              
                            // Processing Fee Notice
                            if(_formTotal<100)...[
                              Center(
                                child: Text(
                                  'Claim is subject to the Standard Processing Fee: \$3.75',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
            
                              SizedBox(height: AppSizes.xl),
                            ],
              
                            // Submit Button
                            CustomButton(
                              text: 'Submit Claim Now',
                              onPressed: _submitForm,
                              type: ButtonType.secondary,
                              size: ButtonSize.small,
                              customTextColor: Colors.black,
                              isLoading: _submitting,
                            ),
              
                            SizedBox(height: AppSizes.md),
              
                            // Print and Reset Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Print Form',
                                    onPressed: _printForm,
                                    type: ButtonType.greyBackground,
                                    customTextColor: AppColors.grey100,
                                    size: ButtonSize.small,
                                  ),
                                ),
                                SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: CustomButton(
                                    text: 'Reset Form',
                                    onPressed: clearForm,
                                    type: ButtonType.greyBackground,
                                    size: ButtonSize.small,
                                  ),
                                ),
                              ],
                            ),
              
                            SizedBox(height: AppSizes.xl),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: logout,
        backgroundColor: AppColors.primary,
        child: signingOut
            ?SizedBox(height: 20,width: 20,child: CircularProgressIndicator(color:Colors.white,strokeWidth: 1.5))
            :Icon(Icons.logout,color: Colors.white),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              shadows: [
                Shadow( // deeper drop
                  offset: Offset(0, 2),
                  blurRadius: 5,
                  color: Colors.black38,
                ),
                Shadow( // subtle ambient
                  offset: Offset(0, 0),
                  blurRadius: 2,
                  color: Colors.black26,
                ),
                Shadow( // brighter top-left highlight
                  offset: Offset(-1.5, -1.5),
                  blurRadius: 3.5,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                shadows: [
                  Shadow( // deeper drop
                    offset: Offset(0, 2),
                    blurRadius: 5,
                    color: Colors.black38,
                  ),
                  Shadow( // subtle ambient
                    offset: Offset(0, 0),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                  Shadow( // brighter top-left highlight
                    offset: Offset(-1.5, -1.5),
                    blurRadius: 3.5,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
  Widget totalAmountTextField(String hint,controller){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: TextFormField(
        controller: controller,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          // hintText: hint,
          label: RichText(
            text: TextSpan(
              text: hint,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
        ),
      ),
    );
  }
  Widget _buildSimpleTextField({
    required String hint,
    required TextEditingController? controller,
    bool required=false,
    bool isDate=false
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: TextFormField(
        controller: controller,
        onTap: isDate?_pickSignatureDate:null,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          // hintText: hint,
          label: RichText(
            text: TextSpan(
              text: hint,
              style: TextStyle(color: Colors.grey, fontSize: 11),
              children: [
                if(required)TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountDisplay(String label, String amount,{bool isTotal=false}) {
    return Container(
      height: 50,
      margin: isTotal?EdgeInsets.symmetric(horizontal:AppSizes.lg):EdgeInsets.zero,
      padding: EdgeInsets.all(AppSizes.radiusSm),
      decoration: BoxDecoration(
        color: AppColors.outline,
        border: Border.all(color: Colors.black87, width: 1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.black87
              ),
              textAlign: TextAlign.start,
              maxLines: 2,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,decoration: TextDecoration.underline,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  List<String> _validateFormFields(String actionName) {
    bool isSubmitting = actionName=='submitting';
    final missing = <String>[];

    if (_companyNameController.text.trim().isEmpty) missing.add('Company Name');
    if (_firstNameController.text.trim().isEmpty)   missing.add('First Name');
    if (_lastNameController.text.trim().isEmpty)    missing.add('Last Name');
    // if (_dateController.text.trim().isEmpty)        missing.add('Date of Signature');
    if (isSubmitting && _signatureFile == null)  missing.add('Signature of Eligible Employee');
    if (isSubmitting && _documents.isEmpty)                         missing.add('At least one supporting document');
    if (isSubmitting && !_isAgreed)                                 missing.add('Agreement');

    // Optional: per-row quick checks
    for (var i = 0; i < _employeeReimbursements.length; i++) {
      final r = _employeeReimbursements[i];
      if ((r['claimantFirstName']?.text ?? '').trim().isEmpty) missing.add('Participant #${i+1} First Name');
      if ((r['claimantLastName']?.text ?? '').trim().isEmpty)  missing.add('Participant #${i+1} Last Name');
      if ((r['fee']?.text ?? '').trim().isEmpty)  missing.add('Participant #${i+1} Total');
    }
    for (var i = 0; i < _providerPayments.length; i++) {
      final r = _providerPayments[i];
      if ((r['providerName']?.text ?? '').trim().isEmpty)      missing.add('Provider #${i+1} Name');
      if ((r['providerAddress']?.text ?? '').trim().isEmpty)   missing.add('Provider #${i+1} Address');
      if ((r['fee']?.text ?? '').trim().isEmpty)  missing.add('Provider #${i+1} Total');
    }

    return missing;
  }

  bool _guardValidation(String actionName) {
    final issues = _validateFormFields(actionName);

    // EXTRA: For printing only, require either signature image OR date.
    if (actionName == 'printing') {
      final noSignature = _signatureFile == null;
      final noDate = _dateController.text.trim().isEmpty;
      if (noSignature && noDate) {
        issues.add('Signature (upload an image) OR Date of Signature');
      }
    }

    if (issues.isNotEmpty) {
      AppSnack.error(context, 'Please complete before $actionName: ${issues.join(",\n")}');
      return false;
    }
    return true;
  }
  logout()async{
    setState(() => signingOut = true);
    bool result = false;
    try{
      result = await _authRepo.logout();
    }catch(e){
      result = false;
      AppSnack.error(context, 'Something went wrong\n$e');
    }finally{
      setState(() => signingOut = false);
    }

    if(result){
      Navigator.pushReplacementNamed(context, '/login');
    }

  }

  Future<void> _submitForm() async {
    if (!_guardValidation('submitting')) return;

    setState(() => _submitting = true);
    try{
// fees from UI rules
//       const int feePerParticipant = 25;
//       const int feePerProvider = 100;


      final map = <String, dynamic>{
        'employer_name': _companyNameController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleInitialController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'employe_date_of_signature': _dateController.text.trim(),
        // totals (as strings or numbers; backend usually accepts either)
        'plan_participant_total_fee': _ppTotal.toString(),
        'service_provider_total_fee': _spTotal.toString(),
        'form_total_fee': _formTotal.toString(),

        // files
        'employe_signature': await MultipartFile.fromFile(_signatureFile!.path),
        // 'documents[]': [
        //   for (final d in _documents) await MultipartFile.fromFile(d.path!)
        // ],
      };
      for (var i = 0; i < _documents.length; i++) {
        final d = _documents[i];
        map['documents[$i]'] = await MultipartFile.fromFile(d.path!);
      }

      // plan_participants[i][...] from Employee Reimbursement list
      for (var i = 0; i < _employeeReimbursements.length; i++) {
        final item = _employeeReimbursements[i];
        map['plan_participants[$i][first_name]']               = item['claimantFirstName']?.text.trim() ?? '';
        map['plan_participants[$i][last_name]']                = item['claimantLastName']?.text.trim() ?? '';
        map['plan_participants[$i][relationship_to_employee]'] = item['relationship']?.text.trim() ?? '';
        map['plan_participants[$i][fee]']                      = item['fee']?.text.trim()??'0';
        print(map);
      }

      // service_providers[i][...] from Provider Payment list
      for (var i = 0; i < _providerPayments.length; i++) {
        final item = _providerPayments[i];
        map['service_providers[$i][name]']                     = item['providerName']?.text.trim() ?? '';
        map['service_providers[$i][address]']                  = item['providerAddress']?.text.trim() ?? '';
        map['service_providers[$i][first_name]']               = item['claimantFirstName']?.text.trim() ?? '';
        map['service_providers[$i][last_name]']                = item['claimantLastName']?.text.trim() ?? '';
        map['service_providers[$i][relationship_to_employee]'] = item['relationship']?.text.trim() ?? '';
        // using your "Total amount this claimant" field as fee; leave blank if empty
        map['service_providers[$i][fee]']                      = item['fee']?.text.trim()??'0';
        print(map);
      }
      await ClaimRepository().submit(map);
      if (!mounted) return;
      AppSnack.success(context, 'Claim submitted successfully');
    }catch(e){
      if (!mounted) return;
      final msg = AppError.message(e);
      AppSnack.error(context, msg);
    }finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double _toNum(String s) => double.tryParse(s.replaceAll(',', '').trim()) ?? 0;

  void _recalcTotals() {
    _ppTotal = _employeeReimbursements.fold<double>(
      0,
          (sum, row) => sum + _toNum(row['fee']?.text ?? ''),
    );
    _spTotal = _providerPayments.fold<double>(
      0,
          (sum, row) => sum + _toNum(row['fee']?.text ?? ''),
    );
    _formTotal = _ppTotal + _spTotal;
    if (mounted) setState(() {});
  }

  void _attachFeeListeners() {
    // attach once per controller so totals update live while typing
    for (final row in _employeeReimbursements) {
      final c = row['fee'];
      if (c != null && !_feeControllersListening.contains(c)) {
        _feeControllersListening.add(c);
        c.addListener(_recalcTotals);
      }
    }
    for (final row in _providerPayments) {
      final c = row['fee'];
      if (c != null && !_feeControllersListening.contains(c)) {
        _feeControllersListening.add(c);
        c.addListener(_recalcTotals);
      }
    }
  }

  void _detachFeeListenersOfRow(Map<String, TextEditingController> row) {
    final c = row['fee'];
    if (c != null && _feeControllersListening.remove(c)) {
      c.removeListener(_recalcTotals);
    }
  }


  Future<void> _printForm() async {
    if (!_guardValidation('printing')) return;

    // helpers
    String _money(num v) => '\$${v.toStringAsFixed(2)}';
    String _safe(String? s) => (s ?? '').trim();
    String _datePretty(String raw) {
      try {
        final d = DateTime.parse(raw);
        return DateFormat('MMMM d, y').format(d); // e.g., June 23, 2025
      } catch (_) {
        return raw;
      }
    }

    // source values
    final employerName   = _safe(_companyNameController.text);
    final firstName      = _safe(_firstNameController.text);
    final middleName     = _safe(_middleInitialController.text);
    final lastName       = _safe(_lastNameController.text);
    final dateOfSigRaw   = _safe(_dateController.text);
    final dateOfSig      = _datePretty(dateOfSigRaw);

    // If user uploaded a signature image, read bytes for PDF
    final sigBytes = _signatureFile != null ? await _signatureFile!.readAsBytes() : null;

    // pdf doc
    final doc = pw.Document();

    // common styles
    final titleStyle      = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.8, 0, 0));
    final sectionHeader   = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
    final tableHeader     = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final cellStyle       = const pw.TextStyle(fontSize: 10);
    final lightGrey       = PdfColor.fromInt(0xFFF2F2F2);
    final boxBorder       = pw.TableBorder.all(color: PdfColors.grey600, width: 0.5);

    pw.Widget infoRow(String k, pw.Widget v) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 180,
              padding: const pw.EdgeInsets.all(6),
              color: lightGrey,
              child: pw.Text(k, style: cellStyle),
            ),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(6),
                child: v,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget infoRowText(String k, String v) => infoRow(k, pw.Text(v, style: cellStyle));

    pw.Widget sectionBox({required List<pw.Widget> children}) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: boxBorder,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(children: children),
      );
    }

    // Build PDF
    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        build: (ctx) => [
          // Title
          pw.Center(child: pw.Text('Claim Form Submission', style: titleStyle)),
          pw.SizedBox(height: 10),

          // Employee Information
          sectionBox(children: [
            pw.Container(
              width: double.maxFinite,
              padding: const pw.EdgeInsets.all(8),
              color: lightGrey,
              child: pw.Text('Employee Information', style: sectionHeader),
            ),
            infoRowText('Employer Name', employerName),
            infoRowText('First Name', firstName),
            infoRowText('Middle Name', middleName),
            infoRowText('Last Name', lastName),
            infoRowText('Date of Signature', dateOfSig),

            // 🔸 Employee Signature row:
            // If signature image exists → show image (and an optional "Signed on <date>" note if a date is present).
            // Else → show the signature date text (or "—" if empty).
            infoRow(
              'Employee Signature',
              sigBytes != null
                  ? pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Signature image box (kept small; tweak width/height if needed)
                  pw.Container(
                    width: 180, // adjust as required
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                    ),
                    child: pw.FittedBox(
                      fit: pw.BoxFit.contain,
                      child: pw.Image(pw.MemoryImage(sigBytes)),
                    ),
                  ),
                  if (dateOfSig.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('Signed on $dateOfSig', style: cellStyle),
                  ],
                ],
              )
                  : pw.Text(
                dateOfSig.isNotEmpty ? dateOfSig : '—',
                style: cellStyle,
              ),
            ),
          ]),
          pw.SizedBox(height: 16),

          // Employee Reimbursement Section (unchanged)
          sectionBox(children: [
            pw.Container(
              width: double.maxFinite,
              padding: const pw.EdgeInsets.all(8),
              color: lightGrey,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Employee Reimbursement Section: Payment to Plan Participant', style: sectionHeader),
                ],
              ),
            ),
            pw.Table(
              border: boxBorder,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(0.9),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Claimants First Name", style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Claimants Last Name",  style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Relationship To Employee", style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Total Of Receipts This Claimant", style: tableHeader)),
                  ],
                ),
                ..._employeeReimbursements.map((r) {
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['claimantFirstName']?.text), style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['claimantLastName']?.text),  style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['relationship']?.text),     style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_money(_toNum(r['fee']?.text ?? '0')), style: cellStyle)),
                  ]);
                }).toList(),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('Reimbursement to Plan Participant:', style: cellStyle)),
                  pw.Text(_money(_ppTotal), style: cellStyle),
                ],
              ),
            ),
          ]),
          pw.SizedBox(height: 16),

          // Provider Payment Section (unchanged)
          sectionBox(children: [
            pw.Container(
              width: double.maxFinite ,
              padding: const pw.EdgeInsets.all(8),
              color: lightGrey,
              child: pw.Text('Provider Payment Section: Payment Assigned to Provider', style: sectionHeader),
            ),
            pw.Table(
              border: boxBorder,
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(1.0),
                3: const pw.FlexColumnWidth(1.0),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(0.9),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Name of Service Provider",    style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Address of Service Provider", style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("First Name of Claimant",      style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Last Name of Claimant",       style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Relationship to Employee",    style: tableHeader)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text("Total amount this claimant",  style: tableHeader)),
                  ],
                ),
                ..._providerPayments.map((r) {
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['providerName']?.text),       style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['providerAddress']?.text),    style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['claimantFirstName']?.text),  style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['claimantLastName']?.text),   style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_safe(r['relationship']?.text),       style: cellStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_money(_toNum(r['fee']?.text ?? '0')), style: cellStyle)),
                  ]);
                }).toList(),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                children: [
                  pw.Expanded(child: pw.Text('Reimbursements To Service Providers:', style: cellStyle)),
                  pw.Text(_money(_spTotal), style: cellStyle),
                ],
              ),
            ),
          ]),
          pw.SizedBox(height: 12),

          // Grand Total box (unchanged)
          pw.Container(
            decoration: pw.BoxDecoration(
              color: lightGrey,
              border: boxBorder,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Text('Total Reimbursements this Claim:', style: sectionHeader)),
                pw.Text(_money(_formTotal), style: sectionHeader),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }



  // Call this to fully reset the form
  void clearForm() {
    // rows to dispose AFTER rebuild
    final removedParticipants = <Map<String, TextEditingController>>[];
    final removedProviders = <Map<String, TextEditingController>>[];

    setState(() {
      // simple fields
      _companyNameController.clear();
      _firstNameController.clear();
      _middleInitialController.clear();
      _lastNameController.clear();
      _dateController.clear();
      _isAgreed = false;

      // files
      _signatureFile = null;
      _documents.clear();

      // PARTICIPANTS: keep first row, clear it; remove the rest (to dispose later)
      if (_employeeReimbursements.isEmpty) {
        _employeeReimbursements.add(_newParticipantRow());
      } else {
        _employeeReimbursements.first['claimantFirstName']?.clear();
        _employeeReimbursements.first['claimantLastName']?.clear();
        _employeeReimbursements.first['relationship']?.clear();
        _employeeReimbursements.first['fee']?.clear();

        if (_employeeReimbursements.length > 1) {
          removedParticipants.addAll(_employeeReimbursements.sublist(1));
          _employeeReimbursements.removeRange(1, _employeeReimbursements.length);
        }
      }

      // PROVIDERS: keep first row, clear it; remove the rest (to dispose later)
      if (_providerPayments.isEmpty) {
        _providerPayments.add(_newProviderRow());
      } else {
        _providerPayments.first['providerName']?.clear();
        _providerPayments.first['providerAddress']?.clear();
        _providerPayments.first['claimantFirstName']?.clear();
        _providerPayments.first['claimantLastName']?.clear();
        _providerPayments.first['relationship']?.clear();
        _providerPayments.first['fee']?.clear();

        if (_providerPayments.length > 1) {
          removedProviders.addAll(_providerPayments.sublist(1));
          _providerPayments.removeRange(1, _providerPayments.length);
        }
      }

      // DO NOT call _formKey.currentState?.reset() here (it re-touches disposed controllers)
    });

    // dispose removed rows AFTER the frame (widgets are rebuilt and no longer referencing them)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final r in removedParticipants) _disposeRow(r);
      for (final r in removedProviders) _disposeRow(r);
    });
    _attachFeeListeners();
    _recalcTotals();
  }

  // Helpers (put inside _ClaimFormState)
  Map<String, TextEditingController> _newParticipantRow() => {
    'claimantFirstName': TextEditingController(),
    'claimantLastName' : TextEditingController(),
    'relationship'     : TextEditingController(),
    'fee': TextEditingController(),
  };

  Map<String, TextEditingController> _newProviderRow() => {
    'providerName'     : TextEditingController(),
    'providerAddress'  : TextEditingController(),
    'claimantFirstName': TextEditingController(),
    'claimantLastName' : TextEditingController(),
    'relationship'     : TextEditingController(),
    'fee'            : TextEditingController(), // your "amount/fee" field
  };

  void _disposeRow(Map<String, TextEditingController> row) {
    for (final c in row.values) { c.dispose(); }
  }
}
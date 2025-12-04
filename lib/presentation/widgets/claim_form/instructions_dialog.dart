import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class InstructionsDialog {
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const InstructionsOverlay();
      },
    );
  }
}

class InstructionsOverlay extends StatelessWidget {
  const InstructionsOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: const Color(0xFF616161).withOpacity(0.95),
        body: GestureDetector(
          onTap: () {}, // Prevent closing when tapping the card
          child: SafeArea(
            child: Column(
              children: [
                // Header with logo and instruction button
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.all(AppSizes.lg),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9C0),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.black87,
                        ),
                        SizedBox(width: AppSizes.xs),
                        const Text(
                          'Instruction',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // White card with instructions
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal:AppSizes.md,vertical: AppSizes.lg),
                      padding: EdgeInsets.all(AppSizes.lg),
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildInstructionItem(
                              'Complete form in full.',
                            ),
                            // SizedBox(height: AppSizes.),

                            _buildInstructionItem(
                              'Only submit for claims incurred, do not submit for claims pre authorizations.',
                            ),
                            // SizedBox(height: AppSizes.),

                            _buildInstructionItem(
                              'Enter receipt totals for same claimant on one line.',
                            ),
                            // SizedBox(height: AppSizes.),

                            _buildInstructionItem(
                              'Only enter information in the service provider payment section if you haven\'t already paid the provider and you are assigning the reimbursement to the service provider.',
                            ),
                            // SizedBox(height: AppSizes.),

                            _buildInstructionItem(
                              'Retain copies of all original receipts and statements provider will not provide copies of receipts submitted.',
                            ),
                            // SizedBox(height: AppSizes.),

                            _buildInstructionItem(
                              'Don\'t include cash registrar receipts or attach cash registrar receipts to formal receipts.',
                            ),
                          ],
                        ),
                      ),
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

  static Widget _buildInstructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 5.8,
          height: 5.8,
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: AppSizes.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
              // fontWeight: FontWeight.w500
            ),
          ),
        ),
      ],
    );
  }
}
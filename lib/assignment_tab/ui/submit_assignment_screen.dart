import 'package:flutter/material.dart';
import '../data/assignment.dart';
import '../data/submission.dart';
import '../logic/assignment_service.dart';
import '../core/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class SubmitAssignmentScreen extends StatefulWidget {
  final Assignment assignment;
  const SubmitAssignmentScreen({super.key, required this.assignment});

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _selectedFilePath;
  String? _selectedFileName;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = widget.assignment.isOverdue;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text('Submit Assignment'),
        backgroundColor: AppColors.getCard(context),
        foregroundColor: AppColors.getTextPrimary(context),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Assignment Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            margin: const EdgeInsets.all(AppConstants.spacing),
            decoration: BoxDecoration(
              color: AppColors.getCard(context),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.assignment,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.assignment.title,
                            style: TextStyle(
                              color: AppColors.getTextPrimary(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: AppColors.getTextSecondary(context),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Due: ${widget.assignment.formattedDeadline}',
                                style: TextStyle(
                                  color: AppColors.getTextSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.assignment.maxScore} pts',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Late Warning (if overdue)
          if (isOverdue)
            Container(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This submission will be marked as late.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (isOverdue) const SizedBox(height: AppConstants.spacing),

          // Answer Input
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing,
              ),
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.getCard(context),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        size: 18,
                        color: AppColors.getTextSecondary(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Answer',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _contentController,
                      enabled: !_isLoading,
                      style: TextStyle(
                        color: AppColors.getTextPrimary(context),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        hintStyle: TextStyle(
                          color: AppColors.getTextSecondary(context),
                          fontSize: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.white.withOpacity(0.03)
                            : Colors.grey.withOpacity(0.03),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // File Attachment Section
                  Text(
                    'Attachments',
                    style: TextStyle(
                      color: AppColors.getTextSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFileName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedFileName!,
                              style: TextStyle(
                                color: AppColors.getTextPrimary(context),
                                fontSize: 13,
                                fontWeight: FontWeight.medium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _removeFile,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppColors.getTextSecondary(context),
                          ),
                        ],
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Attach File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacing),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading
                    ? AppColors.primary.withOpacity(0.6)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                elevation: _isLoading ? 0 : 2,
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Submit Assignment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Please provide an answer or attach a file'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final submission = Submission(
      id: '',
      assignmentId: widget.assignment.id,
      studentId: 'currentStudent',
      studentName: 'Current Student',
      content: _contentController.text.trim(),
      fileName: _selectedFileName,
      submittedAt: DateTime.now(),
      status: widget.assignment.isOverdue ? 'late' : 'submitted',
    );

    await AssignmentService().submitAssignment(submission, filePath: _selectedFilePath);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Assignment submitted successfully!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
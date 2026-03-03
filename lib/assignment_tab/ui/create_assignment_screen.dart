import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/assignment.dart';
import '../logic/assignment_service.dart';
import '../core/app_colors.dart';
import '../../providers/firebase_auth_provider.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String courseId;
  const CreateAssignmentScreen({super.key, required this.courseId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _scoreController = TextEditingController(text: '100');
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        title: const Text('Create Assignment'),
        backgroundColor: AppColors.getCard(context),
        foregroundColor: AppColors.getTextPrimary(context),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacing),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.getCard(context),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppConstants.spacing),
            
            // Description Field
            TextFormField(
              controller: _descController,
              style: TextStyle(color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.getCard(context),
              ),
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppConstants.spacing),
            
            // Max Score Field
            TextFormField(
              controller: _scoreController,
              style: TextStyle(color: AppColors.getTextPrimary(context)),
              decoration: InputDecoration(
                labelText: 'Max Score',
                labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.getCard(context),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppConstants.spacing),
            
            // Deadline Picker
            Container(
              decoration: BoxDecoration(
                color: AppColors.getCard(context),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.5),
                ),
              ),
              child: ListTile(
                title: Text(
                  'Deadline',
                  style: TextStyle(
                    color: AppColors.getTextPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(_deadline),
                  style: TextStyle(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                ),
                onTap: _pickDeadline,
              ),
            ),
            const SizedBox(height: 24),
            
            // Create Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                elevation: 2,
              ),
              onPressed: _isLoading ? null : _create,
              child: _isLoading 
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Create Assignment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline),
      );
      if (time != null) {
        setState(() {
          _deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final auth = context.read<FirebaseAuthProvider>();
      final assignment = Assignment(
        id: '',
        courseId: widget.courseId,
        title: _titleController.text,
        description: _descController.text,
        deadline: _deadline,
        maxScore: int.parse(_scoreController.text),
        createdAt: DateTime.now(),
        createdBy: auth.user?.email ?? 'Unknown',
      );
      await AssignmentService().createAssignment(assignment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create assignment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _scoreController.dispose();
    super.dispose();
  }
}
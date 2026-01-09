import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/file_icon.dart';

class PrintHistoryScreen extends StatefulWidget {
  const PrintHistoryScreen({super.key});

  @override
  State<PrintHistoryScreen> createState() => _PrintHistoryScreenState();
}

class _PrintHistoryScreenState extends State<PrintHistoryScreen> {
  // Filters
  String _filterStatus = 'All'; // 'All', 'Printed', 'Rejected'
  
  List<HistoryItem> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      
      final history = await apiService.getHistory(authService.accessToken!);
      
      setState(() {
        _history = history;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      barrierColor: Colors.black.withOpacity(0.7),
      context: context,
      builder: (context) => GlassDialog(
        title: 'Clear History?',
        content: 'This will permanently delete all history records. This action cannot be undone.',
        confirmText: 'Delete All',
        isDestructive: true,
        onConfirm: () {},
      ),
    );

    if (confirm != true) return;

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      
      await apiService.clearHistory(authService.accessToken!);
      
      setState(() {
        _history = [];
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear history: $e')),
      );
    }
  }

  List<HistoryItem> get _filteredHistory {
    if (_filterStatus == 'All') return _history;
    if (_filterStatus == 'Printed') {
      // Exclude REJECTED even if isPrinted is true (handles legacy buggy data)
      return _history.where((h) => 
          (h.status == 'PRINT_COMPLETED' || h.isPrinted) && h.status != 'REJECTED'
      ).toList();
    }
    if (_filterStatus == 'Rejected') {
      return _history.where((h) => h.status == 'REJECTED').toList();
    }
    return _history;
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final colors = themeService.colors;
    final isDark = themeService.isDarkMode;

    // Gradient for Buttons and Gradient Text
    final primaryGradient = const LinearGradient(
      colors: [Color(0xFF8A2BE2), Color(0xFFBA55D3)],
    );

    // Specific Colors - Dark Mode
    final textGray200 = const Color(0xFFE5E7EB); // gray-200

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Back Button (Left)
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new, 
                    color: isDark ? textGray200 : const Color(0xFF333333), 
                    size: 24
                  ),
                ),
              ),

              // 2. Title (Center)
              Text(
                'File History',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF333333),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 24, 
                ),
              ),

              // 3. Clear History Button (Right)
               InkWell(
                onTap: _history.isEmpty ? null : _clearHistory,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_sweep, 
                    color: isDark ? textGray200 : const Color(0xFF333333), 
                    size: 28
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [colors.backgroundGradientStart, colors.backgroundGradientEnd]
                : [colors.backgroundGradientStart, const Color(0xFFE6E6FA), colors.backgroundGradientEnd], // Tri-color: Pink -> Lavender -> Blue
            stops: isDark ? null : [0.0, 0.5, 1.0], 
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              
              // Filter Segmented Control
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 50, // Fixed height for alignment
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Stack(
                  children: [
                    // Moving Background (The "Glass" Glide)
                    LayoutBuilder(
                        builder: (context, constraints) {
                            // Calculate alignment based on current filter
                            double alignX = 0.0;
                            if (_filterStatus == 'All') alignX = -1.0;
                            if (_filterStatus == 'Printed') alignX = 0.0;
                            if (_filterStatus == 'Rejected') alignX = 1.0;

                            final width = constraints.maxWidth / 3;

                            return AnimatedAlign(
                                alignment: Alignment(alignX, 0),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutCubic,
                                child: Container(
                                    width: width,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        gradient: !isDark ? primaryGradient : null,
                                        color: isDark ? Colors.white.withOpacity(0.1) : null,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: !isDark 
                                            ? [BoxShadow(color: const Color(0xFF8A2BE2).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] 
                                            : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                                    ),
                                ),
                            );
                        }
                    ),

                    // Foreground Buttons
                    Row(
                      children: [
                        _buildFilterTabButton('All', colors, isDark),
                        _buildFilterTabButton('Printed', colors, isDark),
                        _buildFilterTabButton('Rejected', colors, isDark),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            itemCount: _filteredHistory.length,
                            itemBuilder: (context, index) {
                              final item = _filteredHistory[index];
                              return _buildHistoryCard(item, primaryGradient, colors, isDark);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabButton(String text, AppColors colors, bool isDark) {
    final isSelected = _filterStatus == text;
    // For Dark Mode inactive text
    final darkInactiveText = const Color(0xFF9CA3AF); 

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = text),
        behavior: HitTestBehavior.opaque, // Ensure clicks work everywhere
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? darkInactiveText : colors.textSecondary),
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Lato', // Matches HTML
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item, Gradient primaryGradient, AppColors colors, bool isDark) {
    bool isRejected = item.status == 'REJECTED';
    bool isPrinted = (item.status == 'PRINT_COMPLETED' || item.isPrinted) && !isRejected;
    
    // Status Text Widget
    Widget statusWidget;
    if (isPrinted) {
      if (isDark) {
        // Dark Mode: Solid Purple
        statusWidget = const Text(
          'Printed',
          style: TextStyle(
            color: Color(0xFF9370DB), // MediumPurple
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        );
      } else {
        // Light Mode: Gradient Text
        statusWidget = ShaderMask(
          shaderCallback: (bounds) => primaryGradient.createShader(bounds),
          child: const Text(
            'Printed',
            style: TextStyle(
              color: Colors.white, // Required for ShaderMask
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        );
      }
    } else if (isRejected) {
      // Dark Mode: Gray (#9CA3AF), Light Mode: Red (#DC2626 - red-600)
      statusWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.end, // Align right
          children: [
            Text(
              'Rejected',
              style: TextStyle(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (item.rejectionReason != null) 
              Text(
                item.rejectionReason!,
                style: TextStyle(
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFFEF4444), // Subtler red/gray
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
      );
    } else {
       statusWidget = Text(
        item.status,
        style: TextStyle(
          color: isDark ? const Color(0xFF9CA3AF) : colors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      );
    }

    String _formatDate(String dateStr) {
        try {
            final dt = DateTime.parse(dateStr);
            final now = DateTime.now();
            final diff = now.difference(dt);
            
            if (diff.inDays == 0) return 'Today';
            if (diff.inDays == 1) return 'Yesterday';
            if (diff.inDays < 7) return '${diff.inDays} days ago';
            return 'Last week'; 
        } catch (_) {
            return 'Unknown date';
        }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.4),
        ),
        boxShadow: isDark 
            ? null 
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                )
            ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
             // ICON: Light Mode Only (with FileIcon)
             if (!isDark) ...[
                FileIcon(
                  fileName: item.fileName,
                  size: 32,
                  color: const Color(0xFF8A2BE2), 
                ),
                const SizedBox(width: 16),
             ],
            
            // Filename + Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                        color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF333333),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        ),
                    ),
                    
                    if (isDark) ...[
                        const SizedBox(height: 4),
                        Text(
                            '${(item.fileSizeBytes / 1024).toStringAsFixed(1)} KB • ${_formatDate(item.uploadedAt)}',
                            style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                            ),
                        ),
                    ]
                ],
              ),
            ),
            
            if (!isDark) const SizedBox(width: 16),
            
            // Status
            statusWidget,
          ],
        ),
      ),
    );
  }
}

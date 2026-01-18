import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../widgets/glass_container.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(BuildContext) onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> get _pages => [
    const _OnboardingPage1(),
    const _OnboardingPage2(),
    _OnboardingPage3(onGetStarted: _finishOnboarding),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _onSkip() {
    _finishOnboarding();
  }

  Future<void> _finishOnboarding() async {
    // We do NOT set the flag here anymore.
    // The flag is set only after successful login/register.
    widget.onFinish(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: AppConstants.getBackgroundGradient(context),
            ),
          ),
          
          // Page View
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              const _OnboardingPage1(),
              const _OnboardingPage2(),
              _OnboardingPage3(onGetStarted: _finishOnboarding),
            ],
          ),

          // Back Button (Top Left)
          if (_currentPage > 0)
            Positioned(
              top: 50,
              left: 20,
              child: SizedBox(
                width: 44,
                height: 44,
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(12),
                  padding: EdgeInsets.zero,
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Center(
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),

          // Bottom Navigation Area
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (_currentPage != 2) ...[
                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7C3AED), // Primary color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Skip Button
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                   const SizedBox(height: 80), // Reserve space for P3 button
                ],

                const SizedBox(height: 20),
                
                // Dot Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentPage ? 32 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Page 1: SecurePrint ---
class _OnboardingPage1 extends StatelessWidget {
  const _OnboardingPage1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          GlassContainer(
            borderRadius: BorderRadius.circular(30),
            padding: EdgeInsets.zero,
            child: const SizedBox(
              width: 120,
              height: 120,
              child: Center(
                child: Icon(Icons.lock_outline, size: 60, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'SecurePrint',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Print securely.\nLeave no trace.',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- Page 2: End-to-End Encryption ---
class _OnboardingPage2 extends StatelessWidget {
  const _OnboardingPage2();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 100, 32, 160), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Group
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GlassContainer(
                    borderRadius: BorderRadius.circular(70),
                    padding: EdgeInsets.zero,
                    child: const SizedBox(
                      width: 140,
                      height: 140,
                      child: Center(
                        child: Icon(Icons.lock_person, size: 70, color: Colors.white),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 10,
                    right: 80,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 20,
                      child: Icon(Icons.vpn_key, size: 20, color: Colors.white),
                    ),
                  ),
                   const Positioned(
                    bottom: 10,
                    left: 80,
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 20,
                      child: Icon(Icons.verified_user, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'End-to-End\nEncryption',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your files are encrypted before they leave your device. Only the designated print shop can decrypt them.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Auto-Deletion Card
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_delete, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto-Deletion Protocol',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Files are permanently deleted from our servers immediately after printing.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Powered by AES-256 Encryption',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Page 3: Zero Trace Policy ---
class _OnboardingPage3 extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _OnboardingPage3({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ... (Existing UI code)
          const SizedBox(height: 40),
          // Floating Icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
              GlassContainer(
                 borderRadius: BorderRadius.circular(55),
                 padding: EdgeInsets.zero,
                 child: const SizedBox(
                   width: 110,
                   height: 110,
                   child: Center(
                     child: Icon(Icons.delete_sweep, size: 60, color: Colors.white),
                   ),
                 ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // ... (Texts)
          const Text(
            'Zero Trace Policy',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your files are encrypted end-to-end and automatically deleted immediately after printing.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'We never store your documents on our servers. Once the job is done, it\'s gone.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(Icons.check_circle, 'Auto-Deletion'),
              const SizedBox(width: 12),
              _buildBadge(Icons.check_circle, 'E2E Encryption'),
            ],
          ),
          
          const Spacer(),
          
          // Get Started Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40), // Space for dots
        ],
      ),
    );
  }
  
  // Badge Helper
  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

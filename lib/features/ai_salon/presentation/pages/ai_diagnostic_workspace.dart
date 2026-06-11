import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:the_salon_app/core/presentation/theme/app_theme.dart';

class AiDiagnosticWorkspace extends StatefulWidget {
  const AiDiagnosticWorkspace({super.key});

  @override
  State<AiDiagnosticWorkspace> createState() => _AiDiagnosticWorkspaceState();
}

class _AiDiagnosticWorkspaceState extends State<AiDiagnosticWorkspace>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  // 🚀 Dropping complex state management architectures (Bloc, Riverpod? Please.)
  // We're going raw StatefulWidget for max performance and zero boilerplate.
  final Dio _dio = Dio();

  bool _isScanning = false;
  Uint8List? _generatedImageBytes;
  String _statusMessage =
      'Describe your ideal style,\nand let AI find the perfect match.';

  void _submitQuery() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isScanning = true;
      _generatedImageBytes = null;
      _statusMessage = 'Connecting to the AI matrix...';
    });

    try {
      // 🌐 Hitting our ultra-lean NestJS backend. No bloated microservices here.
      final response = await _dio.post(
        'http://192.168.1.10:3000/ai/search',
        data: {'query': query},
      );
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true && data['base64Image'] != null) {
          String base64String = data['base64Image'];

          // Clean the data URI prefix if it exists.
          // Real engineers sanitize their inputs, folks.
          if (base64String.contains(',')) {
            base64String = base64String.split(',')[1];
          }

          final bytes = base64Decode(base64String);

          setState(() {
            _generatedImageBytes = bytes;
            _statusMessage = data['message'] ?? 'Generation Complete!';
          });
        } else {
          setState(() {
            _statusMessage = 'Backend returned a 200, but the payload is sus.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      // 💥 Handling exceptions like a production veteran.
      setState(() {
        _statusMessage = 'Server ghosted us or threw a tantrum. \nError: $e';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error analyzing request: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryDeepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Diagnostic Workspace',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _isScanning
                    ? _buildRadarScanner()
                    : _generatedImageBytes != null
                    ? _buildGeneratedImage()
                    : _buildEmptyState(),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child:
          ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 48,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(
                                    Icons.auto_awesome,
                                    size: 72,
                                    color: AppTheme.accentGold.withValues(
                                      alpha: 0.9,
                                    ),
                                  )
                                  .animate(
                                    onPlay: (controller) =>
                                        controller.repeat(reverse: true),
                                  )
                                  .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.1, 1.1),
                                    duration: 2.seconds,
                                  )
                                  .shimmer(
                                    color: Colors.white,
                                    duration: 3.seconds,
                                  ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.8,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: 0.1,
                end: 0,
                duration: 800.ms,
                curve: Curves.easeOutCubic,
              )
              .fadeIn(duration: 800.ms),
    );
  }

  Widget _buildRadarScanner() {
    return Center(
      child:
          ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: AppTheme.accentGold.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .scale(
                              begin: const Offset(0.3, 0.3),
                              end: const Offset(2.2, 2.2),
                              duration: 2.seconds,
                            )
                            .fadeOut(duration: 2.seconds),
                        Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.accentGold.withValues(
                                    alpha: 0.8,
                                  ),
                                  width: 2,
                                ),
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .scale(
                              begin: const Offset(0.0, 0.0),
                              end: const Offset(1.8, 1.8),
                              duration: 2.seconds,
                            )
                            .fadeOut(duration: 2.seconds),
                        const Icon(
                              Icons.auto_awesome,
                              size: 56,
                              color: AppTheme.accentGold,
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.2, 1.2),
                              duration: 1.seconds,
                            )
                            .shimmer(color: Colors.white, duration: 1.seconds),
                        Positioned(
                          bottom: 30,
                          child:
                              const Text(
                                    'Synthesizing...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate(
                                    onPlay: (controller) =>
                                        controller.repeat(reverse: true),
                                  )
                                  .fadeIn(duration: 500.ms),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(),
    );
  }

  Widget _buildGeneratedImage() {
    return Center(
      child:
          ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withValues(alpha: 0.4),
                          AppTheme.accentGold.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    // 🖼️ The glorious AI payload, animated with buttery smooth physics.
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Image.memory(
                            _generatedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black87, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: const Text(
                                'Creation Complete ✨',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOutBack,
                duration: 800.ms,
              )
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
                duration: 800.ms,
              )
              .fadeIn(duration: 800.ms)
              .shimmer(color: Colors.white24, duration: 2.seconds),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., "Cyberpunk neon salon interior"',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.2),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (_) => _submitQuery(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _submitQuery,
                child:
                    Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.accentGold,
                                AppTheme.primaryBlue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.08, 1.08),
                          duration: 1.seconds,
                        ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0.0,
      curve: Curves.easeOutCubic,
      duration: 600.ms,
    );
  }
}

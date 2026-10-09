import 'package:flutter/material.dart';

/// Authentic Fluent & Apple Minimalist Color System for WardHelm.
/// Strictly anti-AI-slop: zero neon glowing purple orbs.
/// Built with slate obsidian, cyber emerald, deep indigo, and warm accents.
class AppColors {
  AppColors._();

  // Dark Theme Tokens (Slate Obsidian)
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkCard = Color(0xFF243048);       // Slightly elevated
  static const Color darkBorder = Color(0xFF334155);     // Slate 700
  static const Color darkBorderSubtle = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);// Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8);// Slate 400
  static const Color darkTextMuted = Color(0xFF64748B);  // Slate 500

  // Light Theme Tokens (Pure & Subtle Slate)
  static const Color lightBackground = Color(0xFFF8FAFC);// Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);   // Pure White
  static const Color lightCard = Color(0xFFFFFFFF);      // Clean Card
  static const Color lightBorder = Color(0xFFE2E8F0);    // Slate 200
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);// Slate 900
  static const Color lightTextSecondary = Color(0xFF475569);// Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);  // Slate 400

  // Semantic Accents
  static const Color primary = Color(0xFF4F46E5);        // Deep Indigo 600
  static const Color primaryHover = Color(0xFF4338CA);   // Indigo 700
  static const Color primaryLight = Color(0xFFEEF2FF);   // Indigo 50

  static const Color success = Color(0xFF10B981);        // Cyber Emerald 500
  static const Color successBackground = Color(0xFF064E3B);
  static const Color successLight = Color(0xFFECFDF5);

  static const Color warning = Color(0xFFF59E0B);        // Crisp Amber 500
  static const Color warningBackground = Color(0xFF78350F);
  static const Color warningLight = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFEF4444);         // Rose Red 500
  static const Color dangerBackground = Color(0xFF7F1D1D);
  static const Color dangerLight = Color(0xFFFEF2F2);

  static const Color info = Color(0xFF0284C7);           // Sky Blue 600
  static const Color infoLight = Color(0xFFF0F9FF);
}

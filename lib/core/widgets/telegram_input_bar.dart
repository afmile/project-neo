/// Project Neo - Telegram-Style Input Bar
///
/// Reusable input widget inspired by Telegram's design
/// Used across Wall posts and Chat screens
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/neo_theme.dart';

class TelegramInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final Function(String)? onSend;
  final VoidCallback? onAttach;
  final File? selectedImage;
  final VoidCallback? onRemoveImage;
  final bool isSending;

  const TelegramInputBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Mensaje',
    this.onSend,
    this.onAttach,
    this.selectedImage,
    this.onRemoveImage,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview (above bar)
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemoveImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pill-shaped container (Expanded)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: NeoColors.surface, // Match BentoPostCard background
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: NeoColors.border.withOpacity(0.5), // Match BentoPostCard border
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Emoji Icon
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        color: Colors.grey,
                        onPressed: () {
                          // TODO: Implement emoji picker
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),

                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.6),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty && onSend != null) {
                              onSend!(value.trim());
                            }
                          },
                        ),
                      ),

                      // Attach Icon
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        color: Colors.grey,
                        onPressed: onAttach,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Circular Action Button (Mic/Send)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  final hasContent = hasText || selectedImage != null;

                  return GestureDetector(
                    onTap: () {
                      if (isSending) return;
                      
                      if (hasContent && onSend != null) {
                        onSend!(controller.text.trim());
                      } else {
                        // TODO: Implement voice recording
                      }
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: hasContent ? const Color(0xFF8A2BE2) : Colors.grey[800],
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              hasContent ? Icons.arrow_upward_rounded : Icons.mic,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

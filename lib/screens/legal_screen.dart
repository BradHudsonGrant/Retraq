import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_spacing.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding.copyWith(
          top: AppSpacing.lg,
          bottom: AppSpacing.xxl,
        ),
        child: Animate(
          effects: [
            FadeEffect(duration: 400.ms, curve: Curves.easeOut),
            SlideEffect(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),
          ],
          child: _MarkdownBody(content: content, colorScheme: cs),
        ),
      ),
    );
  }
}

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.content, required this.colorScheme});

  final String content;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final blocks = content.trim().split('\n\n');
    final children = <Widget>[];

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('# ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              trimmed.substring(2),
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              trimmed.substring(3),
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
      } else if (trimmed.startsWith('- ')) {
        final lines = trimmed.split('\n');
        for (final line in lines) {
          final text = line.startsWith('- ') ? line.substring(2) : line;
          children.add(
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u2022  ',
                    style: tt.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: _buildRichText(
                      context,
                      text.trim(),
                      tt.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ) ??
                          const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        children.add(const SizedBox(height: AppSpacing.sm));
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildRichText(
              context,
              trimmed,
              tt.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ) ??
                  const TextStyle(),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // Matches **bold**, URLs (https://..., http://...), and emails (foo@bar.com).
  static final _inlineRegex = RegExp(
    r'\*\*(.+?)\*\*' // group 1: bold
    r'|'
    r'(https?://[^\s),]+)' // group 2: URL
    r'|'
    r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})', // group 3: email
  );

  Widget _buildRichText(
    BuildContext context,
    String text,
    TextStyle baseStyle,
  ) {
    final cs = colorScheme;
    final linkStyle = TextStyle(
      color: cs.primary,
      decoration: TextDecoration.underline,
      decorationColor: cs.primary,
    );
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (final match in _inlineRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      if (match.group(1) != null) {
        // Bold
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(2) != null) {
        // URL
        final url = match.group(2)!;
        spans.add(
          TextSpan(
            text: url,
            style: linkStyle,
            recognizer:
                TapGestureRecognizer()
                  ..onTap =
                      () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
          ),
        );
      } else if (match.group(3) != null) {
        // Email
        final email = match.group(3)!;
        spans.add(
          TextSpan(
            text: email,
            style: linkStyle,
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () => launchUrl(Uri.parse('mailto:$email')),
          ),
        );
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }
}

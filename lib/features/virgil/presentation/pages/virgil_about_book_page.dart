import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/env.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../document_chat/domain/entities/document_chat_message.dart';
import '../../../document_chat/domain/entities/document_session.dart';
import '../../../document_chat/presentation/providers/document_chat_providers.dart';
import '../widgets/virgil_brand_header.dart';
import '../widgets/virgil_colors.dart';

/// Route: `virgil/qa` (About Book / document Q&A).
class VirgilAboutBookPage extends ConsumerStatefulWidget {
  const VirgilAboutBookPage({super.key});

  static const _uploadIconAsset = 'assets/Virgil/QA/Group 16.svg';
  static const _processingGifAsset = 'assets/Virgil/QA/Rubricator.gif';
  static const _redBtnAsset = 'assets/Virgil/recommendation/redBtn.svg';

  @override
  ConsumerState<VirgilAboutBookPage> createState() =>
      _VirgilAboutBookPageState();
}

class _VirgilAboutBookPageState extends ConsumerState<VirgilAboutBookPage>
    with RouteAware {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _clearFocus();
  }

  void _clearFocus() {
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onSubmit(DocumentChatState state) {
    final notifier = ref.read(documentChatProvider.notifier);
    if (state.session == null || state.isUploading) {
      notifier.pickAndUpload();
      return;
    }
    if (!state.canSendQuestion) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _clearFocus();
    notifier.sendQuestion(text);
    _controller.clear();
    setState(() {});
  }

  String _errorText(AppLocalizations l10n, DocumentChatState state) {
    switch (state.errorKind) {
      case DocumentChatErrorKind.fileTooLarge:
        return l10n.documentChatFileTooLarge(20);
      case DocumentChatErrorKind.unsupportedFormat:
        return l10n.documentChatUnsupportedFormat;
      case DocumentChatErrorKind.sessionExpired:
        return l10n.documentChatSessionExpired;
      case DocumentChatErrorKind.processingFailed:
        final detail = state.error;
        if (detail != null &&
            detail.isNotEmpty &&
            detail != 'processing_failed') {
          return detail;
        }
        return l10n.documentChatProcessingFailed;
      case DocumentChatErrorKind.questionLimit:
        return l10n.documentChatQuestionsRemaining(0);
      case DocumentChatErrorKind.dailyUploadLimit:
        return l10n.virgilDailyUploadLimit;
      case DocumentChatErrorKind.stillProcessing:
        return l10n.documentChatStillProcessing;
      case DocumentChatErrorKind.pollTimeout:
        return l10n.documentChatProcessingFailed;
      case DocumentChatErrorKind.generic:
      case null:
        return state.error ?? l10n.documentChatProcessingFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);

    if (!Env.hasSemanticApiConfig) {
      return Scaffold(
        backgroundColor: colors.paper,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(badge: l10n.virgilBetaBadge),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.semanticApiNotConfigured,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: colors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(documentChatProvider);
    final session = state.session;
    final isProcessing = state.isUploading ||
        (session != null && (session.isProcessing || state.isPolling));
    final isFailed = session != null &&
        (session.isFailed ||
            state.errorKind == DocumentChatErrorKind.processingFailed ||
            state.errorKind == DocumentChatErrorKind.sessionExpired ||
            state.errorKind == DocumentChatErrorKind.pollTimeout);
    final isReady = session != null && session.isReady && !isFailed;
    final canSubmit = session == null
        ? !state.isUploading
        : state.canSendQuestion && _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(badge: l10n.virgilBetaBadge),
            Expanded(
              child: _Body(
                state: state,
                isProcessing: isProcessing,
                isFailed: isFailed,
                isReady: isReady,
                errorText: state.error != null ? _errorText(l10n, state) : null,
                onPickFile: () =>
                    ref.read(documentChatProvider.notifier).pickAndUpload(),
                onRetry: () =>
                    ref.read(documentChatProvider.notifier).resetSession(),
              ),
            ),
            if (session == null && !isProcessing)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  l10n.virgilQaPrivacyNotice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w300,
                    fontSize: 11,
                    height: 1.35,
                    color: colors.ink,
                  ),
                ),
              ),
            _BottomBar(
              controller: _controller,
              focusNode: _focusNode,
              hintText: l10n.virgilQaInputHint,
              enabled: !isProcessing && !isFailed,
              submitEnabled: canSubmit && !isProcessing && !isFailed,
              onChanged: (_) => setState(() {}),
              onSubmit: () => _onSubmit(state),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.badge});

  final String badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: VirgilBrandHeader.height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Align(
          alignment: Alignment.centerLeft,
          child: VirgilBrandHeader(badge: badge),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.isProcessing,
    required this.isFailed,
    required this.isReady,
    required this.errorText,
    required this.onPickFile,
    required this.onRetry,
  });

  final DocumentChatState state;
  final bool isProcessing;
  final bool isFailed;
  final bool isReady;
  final String? errorText;
  final VoidCallback onPickFile;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isFailed) {
      return _ErrorBody(
        message: errorText ?? l10n.documentChatProcessingFailed,
        onRetry: onRetry,
      );
    }

    if (isProcessing) {
      return _ProcessingBody(progress: state.session?.embedProgress);
    }

    if (isReady) {
      return _ChatBody(
        session: state.session!,
        messages: state.messages,
        isSending: state.isSending,
        errorText: errorText,
        onNewFile: onRetry,
      );
    }

    return _EmptyBody(
      errorText: errorText,
      onPickFile: onPickFile,
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.onPickFile,
    this.errorText,
  });

  final VoidCallback onPickFile;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                errorText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: colors.accent,
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onPickFile,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      VirgilAboutBookPage._uploadIconAsset,
                      width: 132,
                      height: 84,
                      colorFilter: ColorFilter.mode(
                        colors.ink,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.virgilQaUploadTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        height: 1.35,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.virgilQaSizeLimit,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        height: 1.35,
                        color: colors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.virgilQaPagesLimit,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        height: 1.35,
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingBody extends StatelessWidget {
  const _ProcessingBody({this.progress});

  final double? progress;

  static const _ringSize = 104.0;
  static const _gifSize = 64.0;
  static const _strokeWidth = 4.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: _ringSize,
                    height: _ringSize,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: _strokeWidth,
                      backgroundColor: colors.track,
                      color: colors.accent,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Image.asset(
                    VirgilAboutBookPage._processingGifAsset,
                    width: _gifSize,
                    height: _gifSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.virgilQaProcessingTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                height: 1.35,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.virgilQaProcessingSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w300,
                fontSize: 14,
                height: 1.35,
                color: colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBody extends StatelessWidget {
  const _ChatBody({
    required this.session,
    required this.messages,
    required this.isSending,
    required this.onNewFile,
    this.errorText,
  });

  final DocumentSession session;
  final List<DocumentChatMessage> messages;
  final bool isSending;
  final VoidCallback onNewFile;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);
    final format = session.format.toUpperCase();
    final meta = session.pageCount != null
        ? l10n.virgilQaFileMeta(session.filename, format, session.pageCount!)
        : session.chapterCount != null
            ? l10n.virgilQaFileMetaChapters(
                session.filename,
                format,
                session.chapterCount!,
              )
            : '${session.filename} | $format';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: colors.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: colors.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onNewFile,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    l10n.documentChatNewFile,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: colors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            l10n.virgilQuestionsRemaining(session.questionsRemaining),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w300,
              fontSize: 12,
              color: colors.muted,
            ),
          ),
        ),
        if (session.truncated)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              l10n.documentChatTruncatedWarning,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: colors.muted,
              ),
            ),
          ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              errorText!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: colors.accent,
              ),
            ),
          ),
        Expanded(
          child: messages.isEmpty && !isSending
              ? const SizedBox.shrink()
              : _MessageList(
                  messages: messages,
                  isSending: isSending,
                ),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isSending,
  });

  final List<DocumentChatMessage> messages;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= messages.length) {
          return const _TypingBubble();
        }
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final DocumentChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const _Avatar(filled: false),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.ink,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      height: 1.4,
                      color: colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            const _Avatar(filled: true),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.filled});

  final bool filled;

  static const _size = 28.0;

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.ink : colors.paper,
        border: Border.all(color: colors.ink, width: 1),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const _Avatar(filled: false),
          const SizedBox(width: 10),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = VirgilColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onRetry,
              child: Text(
                l10n.documentChatPickFile,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: colors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.enabled,
    required this.submitEnabled,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool enabled;
  final bool submitEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  static const _sectionHeight = 64.0;
  static const _controlSize = 36.0;
  static const _gap = 17.0;

  @override
  Widget build(BuildContext context) {
    final colors = VirgilColors.of(context);
    return SizedBox(
      height: _sectionHeight,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: _controlSize,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                  child: Material(
                    color: colors.paper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: colors.ink,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: enabled ? () => focusNode.requestFocus() : null,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            enabled: enabled,
                            onChanged: onChanged,
                            textInputAction: TextInputAction.send,
                            textAlignVertical: TextAlignVertical.center,
                            cursorHeight: 14,
                            cursorColor: colors.ink,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1,
                              color: colors.ink,
                            ),
                            decoration: InputDecoration.collapsed(
                              hintText: hintText,
                              hintStyle: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w100,
                                fontSize: 12,
                                height: 1,
                                color: colors.muted,
                              ),
                            ),
                            onSubmitted: (_) {
                              if (submitEnabled) onSubmit();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            Opacity(
              opacity: submitEnabled ? 1 : 0.45,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: submitEnabled ? onSubmit : null,
                  customBorder: const CircleBorder(),
                  child: SvgPicture.asset(
                    VirgilAboutBookPage._redBtnAsset,
                    width: _controlSize,
                    height: _controlSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

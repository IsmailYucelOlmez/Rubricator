import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/document_chat_api_datasource.dart';
import '../../data/datasources/document_chat_exception.dart';
import '../../data/repositories/document_chat_repository_impl.dart';
import '../../domain/entities/document_chat_message.dart';
import '../../domain/entities/document_session.dart';
import '../../domain/repositories/document_chat_repository.dart';
import '../../domain/usecases/ask_document_question_usecase.dart';
import '../../domain/usecases/create_document_session_usecase.dart';
import '../../domain/usecases/delete_document_session_usecase.dart';
import '../../domain/usecases/poll_document_session_usecase.dart';

const _maxFileSizeBytes = 20 * 1024 * 1024;
const _pollInterval = Duration(seconds: 2);
const _pollTimeout = Duration(minutes: 10);

final documentChatApiDataSourceProvider = Provider<DocumentChatApiDataSource>(
  (ref) => DocumentChatApiDataSource(),
);

final documentChatRepositoryProvider = Provider<DocumentChatRepository>(
  (ref) => DocumentChatRepositoryImpl(
    ref.watch(documentChatApiDataSourceProvider),
  ),
);

final createDocumentSessionUseCaseProvider =
    Provider<CreateDocumentSessionUseCase>(
  (ref) => CreateDocumentSessionUseCase(
    ref.watch(documentChatRepositoryProvider),
  ),
);

final pollDocumentSessionUseCaseProvider = Provider<PollDocumentSessionUseCase>(
  (ref) => PollDocumentSessionUseCase(
    ref.watch(documentChatRepositoryProvider),
  ),
);

final askDocumentQuestionUseCaseProvider = Provider<AskDocumentQuestionUseCase>(
  (ref) => AskDocumentQuestionUseCase(
    ref.watch(documentChatRepositoryProvider),
  ),
);

final deleteDocumentSessionUseCaseProvider =
    Provider<DeleteDocumentSessionUseCase>(
  (ref) => DeleteDocumentSessionUseCase(
    ref.watch(documentChatRepositoryProvider),
  ),
);

class DocumentChatState {
  const DocumentChatState({
    this.session,
    this.messages = const [],
    this.isUploading = false,
    this.isPolling = false,
    this.isSending = false,
    this.error,
    this.errorKind,
  });

  final DocumentSession? session;
  final List<DocumentChatMessage> messages;
  final bool isUploading;
  final bool isPolling;
  final bool isSending;
  final String? error;
  final DocumentChatErrorKind? errorKind;

  bool get hasActiveSession =>
      session != null && !session!.isExpired && session!.isReady;

  bool get canSendQuestion =>
      hasActiveSession &&
      !isSending &&
      !isPolling &&
      !isUploading &&
      (session?.questionsRemaining ?? 0) > 0;

  DocumentChatState copyWith({
    DocumentSession? session,
    List<DocumentChatMessage>? messages,
    bool? isUploading,
    bool? isPolling,
    bool? isSending,
    String? error,
    DocumentChatErrorKind? errorKind,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return DocumentChatState(
      session: clearSession ? null : (session ?? this.session),
      messages: messages ?? this.messages,
      isUploading: isUploading ?? this.isUploading,
      isPolling: isPolling ?? this.isPolling,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      errorKind: clearError ? null : (errorKind ?? this.errorKind),
    );
  }
}

enum DocumentChatErrorKind {
  generic,
  fileTooLarge,
  unsupportedFormat,
  sessionExpired,
  processingFailed,
  questionLimit,
  stillProcessing,
  pollTimeout,
}

class DocumentChatNotifier extends StateNotifier<DocumentChatState> {
  DocumentChatNotifier({
    required CreateDocumentSessionUseCase createSession,
    required PollDocumentSessionUseCase pollSession,
    required AskDocumentQuestionUseCase askQuestion,
    required DeleteDocumentSessionUseCase deleteSession,
  })  : _createSession = createSession,
        _pollSession = pollSession,
        _askQuestion = askQuestion,
        _deleteSession = deleteSession,
        super(const DocumentChatState());

  final CreateDocumentSessionUseCase _createSession;
  final PollDocumentSessionUseCase _pollSession;
  final AskDocumentQuestionUseCase _askQuestion;
  final DeleteDocumentSessionUseCase _deleteSession;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  int _messageSeq = 0;
  bool _disposed = false;

  void _setState(DocumentChatState next) {
    if (_disposed) return;
    state = next;
  }

  Future<void> pickAndUpload() async {
    _setState(state.copyWith(
      isUploading: true,
      clearError: true,
    ));

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'epub'],
        withData: false,
      );

      if (_disposed) return;

      if (result == null || result.files.isEmpty) {
        _setState(state.copyWith(isUploading: false));
        return;
      }

      final file = result.files.single;
      final path = file.path;
      final name = file.name;

      if (path == null || path.isEmpty) {
        _setState(state.copyWith(
          isUploading: false,
          error: 'Could not read the selected file.',
          errorKind: DocumentChatErrorKind.generic,
        ));
        return;
      }

      final lower = name.toLowerCase();
      if (!lower.endsWith('.pdf') && !lower.endsWith('.epub')) {
        _setState(state.copyWith(
          isUploading: false,
          error: 'unsupported_format',
          errorKind: DocumentChatErrorKind.unsupportedFormat,
        ));
        return;
      }

      if (file.size > _maxFileSizeBytes) {
        _setState(state.copyWith(
          isUploading: false,
          error: 'file_too_large',
          errorKind: DocumentChatErrorKind.fileTooLarge,
        ));
        return;
      }

      await _disposeRemoteSession();
      if (_disposed) return;

      final session = await _createSession(
        filePath: path,
        filename: name,
      );
      if (_disposed) return;

      _setState(state.copyWith(
        session: session,
        messages: const [],
        isUploading: false,
        clearError: true,
      ));

      if (session.isReady) {
        return;
      }
      if (session.isFailed) {
        _setState(state.copyWith(
          error: session.errorMessage ?? 'processing_failed',
          errorKind: DocumentChatErrorKind.processingFailed,
        ));
        return;
      }

      _startPolling(session.sessionId);
    } on DocumentChatException catch (e) {
      _setState(state.copyWith(
        isUploading: false,
        error: e.message,
        errorKind: _mapException(e),
      ));
    } catch (e) {
      _setState(state.copyWith(
        isUploading: false,
        error: e.toString(),
        errorKind: DocumentChatErrorKind.generic,
      ));
    }
  }

  Future<void> sendQuestion(String raw) async {
    final question = raw.trim();
    if (question.isEmpty) return;

    final session = state.session;
    if (session == null || !session.isReady || session.isExpired) {
      _setState(state.copyWith(
        error: 'session_expired',
        errorKind: DocumentChatErrorKind.sessionExpired,
      ));
      return;
    }
    if (session.questionsRemaining <= 0) {
      _setState(state.copyWith(
        error: 'question_limit',
        errorKind: DocumentChatErrorKind.questionLimit,
      ));
      return;
    }

    final userMessage = DocumentChatMessage(
      id: _nextId(),
      role: 'user',
      content: question,
      createdAt: DateTime.now().toUtc(),
    );

    _setState(state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    ));

    try {
      final answer = await _askQuestion(
        sessionId: session.sessionId,
        question: question,
      );
      if (_disposed) return;

      final assistant = DocumentChatMessage(
        id: _nextId(),
        role: 'assistant',
        content: answer.answer,
        sources: answer.sources,
        createdAt: DateTime.now().toUtc(),
      );

      _setState(state.copyWith(
        messages: [...state.messages, assistant],
        isSending: false,
        session: session.copyWith(
          questionsRemaining: answer.questionsRemaining,
          expiresAt: answer.sessionExpiresAt,
          questionCount: session.questionCount + 1,
        ),
      ));
    } on DocumentChatException catch (e) {
      if (e.isStillProcessing) {
        _setState(state.copyWith(
          isSending: false,
          error: e.message,
          errorKind: DocumentChatErrorKind.stillProcessing,
        ));
        _startPolling(session.sessionId);
        return;
      }
      _setState(state.copyWith(
        isSending: false,
        error: e.message,
        errorKind: _mapException(e),
      ));
    } catch (e) {
      _setState(state.copyWith(
        isSending: false,
        error: e.toString(),
        errorKind: DocumentChatErrorKind.generic,
      ));
    }
  }

  Future<void> resetSession() async {
    _stopPolling();
    await _disposeRemoteSession();
    _setState(const DocumentChatState());
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    // Do not DELETE the remote session here. File-picker / tab rebuilds can
    // dispose this notifier while an upload just succeeded; wiping the
    // session makes the UI look like the upload failed.
    super.dispose();
  }

  void _startPolling(String sessionId) {
    _stopPolling();
    _pollStartedAt = DateTime.now();
    _setState(state.copyWith(isPolling: true, clearError: true));

    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce(sessionId));
    unawaited(_pollOnce(sessionId));
  }

  Future<void> _pollOnce(String sessionId) async {
    if (_disposed) return;

    final started = _pollStartedAt;
    if (started != null &&
        DateTime.now().difference(started) > _pollTimeout) {
      _stopPolling();
      _setState(state.copyWith(
        isPolling: false,
        error: 'poll_timeout',
        errorKind: DocumentChatErrorKind.pollTimeout,
      ));
      return;
    }

    try {
      final updated = await _pollSession(sessionId);
      if (_disposed) return;

      final merged = updated.copyWith(
        filename: updated.filename.isNotEmpty
            ? updated.filename
            : state.session?.filename ?? '',
      );

      if (merged.isProcessing) {
        _setState(state.copyWith(session: merged, isPolling: true));
        return;
      }

      _stopPolling();

      if (merged.isFailed) {
        _setState(state.copyWith(
          session: merged,
          isPolling: false,
          error: merged.errorMessage ?? 'processing_failed',
          errorKind: DocumentChatErrorKind.processingFailed,
        ));
        return;
      }

      _setState(state.copyWith(
        session: merged,
        isPolling: false,
        clearError: true,
      ));
    } on DocumentChatException catch (e) {
      if (e.isSessionExpired) {
        _stopPolling();
        _setState(state.copyWith(
          isPolling: false,
          error: e.message,
          errorKind: DocumentChatErrorKind.sessionExpired,
        ));
        return;
      }
      // Transient poll errors: keep trying until timeout.
    } catch (_) {
      // Keep polling on transient failures.
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollStartedAt = null;
  }

  Future<void> _disposeRemoteSession() async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    try {
      await _deleteSession(sessionId);
    } catch (_) {}
  }

  String _nextId() {
    _messageSeq += 1;
    return 'msg_$_messageSeq';
  }

  DocumentChatErrorKind _mapException(DocumentChatException e) {
    if (e.isFileTooLarge) return DocumentChatErrorKind.fileTooLarge;
    if (e.isUnsupportedFormat) return DocumentChatErrorKind.unsupportedFormat;
    if (e.isSessionExpired) return DocumentChatErrorKind.sessionExpired;
    if (e.isProcessingFailed) return DocumentChatErrorKind.processingFailed;
    if (e.isQuestionLimit) return DocumentChatErrorKind.questionLimit;
    if (e.isStillProcessing) return DocumentChatErrorKind.stillProcessing;
    return DocumentChatErrorKind.generic;
  }
}

/// Not autoDispose: file picker pauses the activity and can briefly drop
/// listeners; recreating mid-upload wiped session state and looked like a
/// failed upload even after HTTP 201.
final documentChatProvider =
    StateNotifierProvider<DocumentChatNotifier, DocumentChatState>(
  (ref) => DocumentChatNotifier(
    createSession: ref.watch(createDocumentSessionUseCaseProvider),
    pollSession: ref.watch(pollDocumentSessionUseCaseProvider),
    askQuestion: ref.watch(askDocumentQuestionUseCaseProvider),
    deleteSession: ref.watch(deleteDocumentSessionUseCaseProvider),
  ),
);

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import '../../models/route/route_step.dart';
import '../navigation_logger.dart';

/// Priority level for voice queue items.
enum VoicePriority {
  /// Normal priority - waits in queue.
  normal,

  /// High priority - can optionally interrupt current playback.
  high,
}

/// Item in the voice queue.
class VoiceQueueItem {
  /// Unique identifier for this item.
  final int id;

  /// Text to speak.
  final String text;

  /// Priority level.
  final VoicePriority priority;

  /// Timestamp when item was added to queue.
  final DateTime addedAt;

  /// Step index this item belongs to.
  /// Used to skip stale items when step has advanced.
  /// Null for non-step-related items (e.g., off-route, arrival).
  final int? stepIndex;

  const VoiceQueueItem({
    required this.id,
    required this.text,
    required this.priority,
    required this.addedAt,
    this.stepIndex,
  });

  @override
  String toString() =>
      'VoiceQueueItem(id: $id, step: $stepIndex, priority: $priority, text: "${text.length > 30 ? '${text.substring(0, 30)}...' : text}")';
}

/// Configuration for voice guidance.
class VoiceGuidanceOptions {
  final bool enabled;
  final String language;
  final double speechRate;
  final double volume;
  final double pitch;
  final bool announceArrival;
  final bool announceOffRoute;

  /// Distance threshold in meters to trigger short instruction announcement.
  /// When user is within this distance from the next maneuver,
  /// the short instruction (voice_instruction_short) will be spoken.
  final double shortInstructionThreshold;

  /// Custom message for off-route announcement.
  /// Defaults to Russian: "Вы сошли с маршрута."
  final String offRouteMessage;

  /// Custom message for arrival announcement.
  /// Defaults to Russian: "Вы прибыли в пункт назначения."
  final String arrivalMessage;

  // === Queue options ===

  /// Whether high priority messages should interrupt current playback.
  ///
  /// When false (default), high priority messages are added to the front
  /// of the queue but wait for current playback to finish.
  ///
  /// When true, high priority messages stop current playback and
  /// immediately start speaking.
  final bool interruptOnHighPriority;

  /// Maximum number of items in the queue.
  ///
  /// When the queue is full, oldest normal-priority items are removed
  /// to make room for new messages. High priority items are never
  /// removed due to overflow.
  ///
  /// Default is 10 items.
  final int maxQueueSize;

  const VoiceGuidanceOptions({
    this.enabled = false,
    this.language = 'en-US',
    this.speechRate = 0.5,
    this.volume = 1.0,
    this.pitch = 1.0,
    this.announceArrival = true,
    this.announceOffRoute = true,
    this.shortInstructionThreshold = 30.0,
    this.offRouteMessage = 'Вы сошли с маршрута.',
    this.arrivalMessage = 'Вы прибыли в пункт назначения.',
    this.interruptOnHighPriority = false,
    this.maxQueueSize = 10,
  });

  VoiceGuidanceOptions copyWith({
    bool? enabled,
    String? language,
    double? speechRate,
    double? volume,
    double? pitch,
    bool? announceArrival,
    bool? announceOffRoute,
    double? shortInstructionThreshold,
    String? offRouteMessage,
    String? arrivalMessage,
    bool? interruptOnHighPriority,
    int? maxQueueSize,
  }) {
    return VoiceGuidanceOptions(
      enabled: enabled ?? this.enabled,
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      announceArrival: announceArrival ?? this.announceArrival,
      announceOffRoute: announceOffRoute ?? this.announceOffRoute,
      shortInstructionThreshold:
          shortInstructionThreshold ?? this.shortInstructionThreshold,
      offRouteMessage: offRouteMessage ?? this.offRouteMessage,
      arrivalMessage: arrivalMessage ?? this.arrivalMessage,
      interruptOnHighPriority:
          interruptOnHighPriority ?? this.interruptOnHighPriority,
      maxQueueSize: maxQueueSize ?? this.maxQueueSize,
    );
  }
}

/// Voice guidance helper using platform TTS with queue support.
///
/// Messages are queued and played sequentially without interrupting
/// each other, unless explicitly configured to allow interruption.
class VoiceGuidance {
  final FlutterTts _tts = FlutterTts();
  final VoiceGuidanceOptions options;

  bool _initialized = false;
  int? _lastSpokenStepIndex;
  int? _lastShortSpokenStepIndex;
  int? _lastUpcomingSpokenStepIndex;
  bool _arrivalSpoken = false;
  bool _offRouteSpoken = false;

  /// After speaking off-route, we wait for user to return to route
  /// before allowing another off-route announcement.
  bool _waitingForReturnToRoute = false;

  // === Queue state ===

  /// Queue of messages waiting to be spoken.
  final List<VoiceQueueItem> _queue = [];

  /// Whether TTS is currently playing.
  bool _isPlaying = false;

  /// ID counter for queue items.
  int _nextItemId = 0;

  /// ID of currently playing item (for logging).
  int? _currentItemId;

  /// Whether queue processing is active.
  bool _isProcessing = false;

  /// Current navigation step index. Used to filter stale queue items.
  int _currentStepIndex = 0;

  VoiceGuidance(this.options);

  /// Updates the current step index for stale item filtering.
  /// Call this when step changes in NavigationController.
  void updateCurrentStepIndex(int stepIndex) {
    if (stepIndex != _currentStepIndex) {
      NavigationLogger.debug('VoiceGuidance', 'updateCurrentStepIndex', {
        'previousStep': _currentStepIndex,
        'newStep': stepIndex,
      });
      _currentStepIndex = stepIndex;
    }
  }

  /// Gets the current step index.
  int get currentStepIndex => _currentStepIndex;

  Future<void> initialize() async {
    if (_initialized) {
      NavigationLogger.debug('VoiceGuidance', 'Already initialized');
      return;
    }
    if (!options.enabled) {
      NavigationLogger.info('VoiceGuidance', 'Voice guidance disabled in options');
      return;
    }

    try {
      NavigationLogger.info('VoiceGuidance', 'Initializing TTS', {
        'language': options.language,
      });

      // Check available languages
      final languages = await _tts.getLanguages;
      NavigationLogger.debug('VoiceGuidance', 'Available languages', {
        'languages': languages?.toString(),
      });

      // Set language and check result
      final langResult = await _tts.setLanguage(options.language);
      NavigationLogger.debug('VoiceGuidance', 'setLanguage result', {
        'result': langResult,
      });

      await _tts.setSpeechRate(options.speechRate);
      await _tts.setVolume(options.volume);
      await _tts.setPitch(options.pitch);

      // Set up completion handler for queue processing
      _tts.setCompletionHandler(() {
        NavigationLogger.debug('VoiceGuidance', 'TTS completion callback', {
          'itemId': _currentItemId,
          'queueSize': _queue.length,
        });
        _isPlaying = false;
        _currentItemId = null;
        // Process next item in queue
        _processQueue();
      });

      // Set up error handler
      _tts.setErrorHandler((error) {
        NavigationLogger.warn('VoiceGuidance', 'TTS error callback', {
          'error': error.toString(),
          'itemId': _currentItemId,
        });
        _isPlaying = false;
        _currentItemId = null;
        // Continue with next item despite error
        _processQueue();
      });

      // Set up cancel handler (when stop() is called)
      _tts.setCancelHandler(() {
        NavigationLogger.debug('VoiceGuidance', 'TTS cancel callback', {
          'itemId': _currentItemId,
        });
        _isPlaying = false;
        _currentItemId = null;
        // Don't auto-process queue after cancel - let caller decide
      });

      // Check if TTS is available
      final isAvailable = await _tts.isLanguageAvailable(options.language);
      NavigationLogger.debug('VoiceGuidance', 'Language availability', {
        'language': options.language,
        'available': isAvailable,
      });

      _initialized = true;
      NavigationLogger.info('VoiceGuidance', 'TTS initialized successfully with queue support');
    } catch (error, stack) {
      NavigationLogger.error('VoiceGuidance', 'Failed to initialize TTS', error, stack);
    }
  }

  /// Speaks the full voice instruction for a step.
  /// Falls back to [instruction] if [voiceInstruction] is not available.
  ///
  /// Messages are queued with normal priority and will not interrupt
  /// currently playing instructions.
  ///
  /// [overrideText] - if provided, speaks this text instead of voiceInstruction/instruction.
  /// Useful for reroute scenarios where instruction is preferred over voiceInstruction.
  Future<void> speakStep(RouteStep step, int stepIndex, {String? overrideText}) async {
    if (!options.enabled) return;
    if (_lastSpokenStepIndex == stepIndex) return;

    _lastSpokenStepIndex = stepIndex;
    // Also set _lastUpcomingSpokenStepIndex to prevent speakUpcomingStep() from repeating
    // This fixes bug where voice repeats 3-4 times while stationary near a turn
    _lastUpcomingSpokenStepIndex = stepIndex;
    // Also set _lastShortSpokenStepIndex to prevent speakShortInstruction() from repeating
    _lastShortSpokenStepIndex = stepIndex;

    NavigationLogger.debug('VoiceGuidance', 'speakStep deduplication state updated', {
      'stepIndex': stepIndex,
      'lastSpoken': _lastSpokenStepIndex,
      'lastUpcoming': _lastUpcomingSpokenStepIndex,
      'lastShort': _lastShortSpokenStepIndex,
    });

    // Use override text if provided, otherwise prefer voiceInstruction, fallback to instruction
    final String textToSpeak;
    final String instructionType;
    if (overrideText != null) {
      textToSpeak = overrideText;
      instructionType = 'override';
    } else {
      textToSpeak = step.voiceInstruction ?? step.instruction;
      instructionType = step.voiceInstruction != null ? 'voiceInstruction' : 'instruction';
    }
    NavigationLogger.info('VoiceGuidance', 'speakStep enqueueing', {
      'stepIndex': stepIndex,
      'instructionType': instructionType,
      'priority': 'normal',
    });

    _enqueue(textToSpeak, VoicePriority.normal, stepIndex: stepIndex);

    // Speak next maneuver hint if available (also queued)
    if (step.nextManeuverHint != null) {
      NavigationLogger.debug('VoiceGuidance', 'speakStep enqueueing nextManeuverHint', {
        'stepIndex': stepIndex,
      });
      _enqueue(step.nextManeuverHint!, VoicePriority.normal, stepIndex: stepIndex);
    }
  }

  /// Speaks a short instruction, useful for quick reminders when approaching maneuver.
  /// Falls back to [instruction] if [voiceInstructionShort] is not available.
  ///
  /// Messages are queued with normal priority and will not interrupt
  /// currently playing instructions.
  ///
  /// Returns true if instruction was queued, false if skipped (already spoken).
  Future<bool> speakShortInstruction(RouteStep step, int stepIndex) async {
    if (!options.enabled) {
      NavigationLogger.debug('VoiceGuidance', 'speakShortInstruction skipped - disabled');
      return false;
    }

    // Prevent duplicate short instructions for the same step
    if (_lastShortSpokenStepIndex == stepIndex) {
      NavigationLogger.debug('VoiceGuidance', 'speakShortInstruction skipped - already spoken', {
        'stepIndex': stepIndex,
      });
      return false;
    }

    _lastShortSpokenStepIndex = stepIndex;

    final textToSpeak = step.voiceInstructionShort ?? step.instruction;
    final instructionType = step.voiceInstructionShort != null
        ? 'voiceInstructionShort'
        : 'instruction';
    NavigationLogger.info('VoiceGuidance', 'speakShortInstruction enqueueing', {
      'stepIndex': stepIndex,
      'instructionType': instructionType,
      'priority': 'normal',
    });

    _enqueue(textToSpeak, VoicePriority.normal, stepIndex: stepIndex);
    return true;
  }

  /// Speaks the UPCOMING maneuver instruction proactively, BEFORE the step changes.
  /// This is called when approaching a maneuver (e.g., 250m before turn).
  /// Uses the full voiceInstruction to give the driver advance notice.
  ///
  /// This is different from [speakStep] which is called when step changes (too late).
  /// The UPCOMING instruction should be spoken BEFORE the maneuver, not after.
  ///
  /// Returns true if instruction was queued, false if skipped (already spoken).
  Future<bool> speakUpcomingStep(RouteStep step, int stepIndex) async {
    if (!options.enabled) {
      NavigationLogger.debug('VoiceGuidance', 'speakUpcomingStep skipped - disabled');
      return false;
    }

    // Prevent duplicate upcoming instructions for the same step
    // This handles both:
    // 1. STEP_TRANSITION call (when stepJustChanged) - announces new step immediately
    // 2. UPCOMING threshold call (when approaching maneuver) - should NOT repeat if #1 already spoke
    if (_lastUpcomingSpokenStepIndex == stepIndex) {
      NavigationLogger.debug('VoiceGuidance', 'speakUpcomingStep skipped - deduplication', {
        'stepIndex': stepIndex,
        'lastUpcomingSpokenStepIndex': _lastUpcomingSpokenStepIndex,
      });
      return false;
    }

    _lastUpcomingSpokenStepIndex = stepIndex;

    // Use voiceInstruction for full instruction, fallback to instruction
    final textToSpeak = step.voiceInstruction ?? step.instruction;
    final instructionType = step.voiceInstruction != null
        ? 'voiceInstruction'
        : 'instruction';
    NavigationLogger.info('VoiceGuidance', 'speakUpcomingStep enqueueing UPCOMING', {
      'stepIndex': stepIndex,
      'instructionType': instructionType,
      'priority': 'normal',
      'textPreview': textToSpeak.length > 50 ? '${textToSpeak.substring(0, 50)}...' : textToSpeak,
    });

    _enqueue(textToSpeak, VoicePriority.normal, stepIndex: stepIndex);

    // Also speak next maneuver hint if available (e.g., "а затем через 50 метров направо")
    if (step.nextManeuverHint != null) {
      NavigationLogger.debug('VoiceGuidance', 'speakUpcomingStep enqueueing nextManeuverHint', {
        'stepIndex': stepIndex,
      });
      _enqueue(step.nextManeuverHint!, VoicePriority.normal, stepIndex: stepIndex);
    }

    return true;
  }

  /// Announces arrival at destination.
  ///
  /// Queued with HIGH priority as this is an important event.
  /// Returns a Future that completes when the speech is finished.
  Future<void> speakArrival([String? message]) async {
    if (!options.enabled || !options.announceArrival) return;
    if (_arrivalSpoken) return;

    _arrivalSpoken = true;
    final textToSpeak = message ?? options.arrivalMessage;
    final isCustom = message != null;
    NavigationLogger.info('VoiceGuidance', 'speakArrival enqueueing', {
      'isCustom': isCustom,
      'priority': 'high',
    });

    // Speak directly and wait for completion instead of using queue
    // This ensures arrival message is fully spoken before navigation ends
    await _speakAndWait(textToSpeak);
  }

  /// Speaks text and waits for TTS to complete.
  Future<void> _speakAndWait(String text) async {
    if (!_initialized) {
      NavigationLogger.warn('VoiceGuidance', '_speakAndWait skipped - TTS not initialized');
      return;
    }

    final completer = Completer<void>();

    // Set up one-time completion handler
    void onComplete() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    void onError(dynamic error) {
      NavigationLogger.warn('VoiceGuidance', '_speakAndWait error', {'error': error});
      if (!completer.isCompleted) {
        completer.complete(); // Complete anyway to not block
      }
    }

    _tts.setCompletionHandler(onComplete);
    _tts.setErrorHandler(onError);

    try {
      NavigationLogger.info('VoiceGuidance', '_speakAndWait speaking', {
        'text': text,
      });
      await _tts.speak(text);

      // Wait for completion with timeout
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          NavigationLogger.warn('VoiceGuidance', '_speakAndWait timeout');
        },
      );

      NavigationLogger.info('VoiceGuidance', '_speakAndWait completed');
    } catch (e) {
      NavigationLogger.error('VoiceGuidance', '_speakAndWait failed', e);
    } finally {
      // Restore queue completion handler
      _tts.setCompletionHandler(() {
        _isPlaying = false;
        _currentItemId = null;
        _processQueue();
      });
      _tts.setErrorHandler((error) {
        _isPlaying = false;
        _currentItemId = null;
        _processQueue();
      });
    }
  }

  /// Announces that user has gone off-route.
  ///
  /// Queued with HIGH priority as this is an important navigation event.
  Future<void> speakOffRoute([String? message]) async {
    if (!options.enabled || !options.announceOffRoute) {
      NavigationLogger.debug('VoiceGuidance', 'speakOffRoute skipped', {
        'enabled': options.enabled,
        'announceOffRoute': options.announceOffRoute,
      });
      return;
    }
    if (_offRouteSpoken) {
      NavigationLogger.debug('VoiceGuidance', 'speakOffRoute skipped - already spoken', {
        'waitingForReturn': _waitingForReturnToRoute,
      });
      return;
    }

    _offRouteSpoken = true;
    _waitingForReturnToRoute = true;
    final textToSpeak = message ?? options.offRouteMessage;
    final isCustom = message != null;
    NavigationLogger.info('VoiceGuidance', 'speakOffRoute enqueueing', {
      'isCustom': isCustom,
      'priority': 'high',
    });
    _enqueue(textToSpeak, VoicePriority.high);
  }

  /// Called when user's route status changes.
  /// If [isOnRoute] is true, resets off-route announcement state
  /// so it can be announced again if user goes off-route later.
  void onRouteStatusChanged(bool isOnRoute) {
    NavigationLogger.debug('VoiceGuidance', 'onRouteStatusChanged', {
      'isOnRoute': isOnRoute,
      'wasWaiting': _waitingForReturnToRoute,
      'wasOffRouteSpoken': _offRouteSpoken,
    });

    if (isOnRoute && _waitingForReturnToRoute) {
      // User returned to route - allow future off-route announcements
      _offRouteSpoken = false;
      _waitingForReturnToRoute = false;
      NavigationLogger.info('VoiceGuidance', 'User returned to route, off-route state reset');
    }
  }

  /// Called when a new route is set (e.g., after reroute).
  /// Does NOT reset off-route state immediately - waits for user to be on-route first.
  /// This prevents repeated off-route announcements during rerouting.
  void onNewRoute() {
    NavigationLogger.info('VoiceGuidance', 'onNewRoute', {
      'offRouteSpoken': _offRouteSpoken,
      'waitingForReturn': _waitingForReturnToRoute,
      'lastUpcoming': _lastUpcomingSpokenStepIndex,
    });
    // Reset step-related state for new route
    _lastSpokenStepIndex = null;
    _lastShortSpokenStepIndex = null;
    _lastUpcomingSpokenStepIndex = null;
    // Do NOT reset _offRouteSpoken here - wait for onRouteStatusChanged(true)
  }

  /// Fully resets all voice guidance state including the queue.
  /// Call this when navigation is stopped completely.
  void reset() {
    NavigationLogger.info('VoiceGuidance', 'reset', {
      'offRouteSpoken': _offRouteSpoken,
      'waitingForReturn': _waitingForReturnToRoute,
      'arrivalSpoken': _arrivalSpoken,
      'lastUpcoming': _lastUpcomingSpokenStepIndex,
      'queueSize': _queue.length,
      'isPlaying': _isPlaying,
    });
    _lastSpokenStepIndex = null;
    _lastShortSpokenStepIndex = null;
    _lastUpcomingSpokenStepIndex = null;
    _arrivalSpoken = false;
    _offRouteSpoken = false;
    _waitingForReturnToRoute = false;
    // Clear queue but don't stop current playback
    _queue.clear();
    NavigationLogger.debug('VoiceGuidance', 'State and queue cleared');
  }

  /// Disposes of TTS resources and clears the queue.
  Future<void> dispose() async {
    NavigationLogger.info('VoiceGuidance', 'dispose', {
      'queueSize': _queue.length,
      'isPlaying': _isPlaying,
    });
    _queue.clear();
    _isPlaying = false;
    _isProcessing = false;
    _currentItemId = null;
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore TTS shutdown errors.
    }
    NavigationLogger.debug('VoiceGuidance', 'Disposed');
  }

  /// Speaks arbitrary text. Use for custom announcements like reroute instructions.
  ///
  /// Queued with normal priority by default.
  /// Use [priority] parameter to specify high priority for important messages.
  Future<void> speakText(String text, {VoicePriority priority = VoicePriority.normal}) async {
    if (!options.enabled) {
      NavigationLogger.debug('VoiceGuidance', 'speakText skipped - disabled');
      return;
    }
    NavigationLogger.info('VoiceGuidance', 'speakText enqueueing', {
      'textPreview': text.length > 50 ? '${text.substring(0, 50)}...' : text,
      'priority': priority.name,
    });
    _enqueue(text, priority);
  }

  /// Adds a message to the queue and starts processing if not already playing.
  ///
  /// [text] - Text to speak.
  /// [priority] - Priority level (normal or high).
  /// [stepIndex] - Optional step index for filtering stale items.
  void _enqueue(String text, VoicePriority priority, {int? stepIndex}) {
    if (!_initialized) {
      NavigationLogger.warn('VoiceGuidance', '_enqueue skipped - TTS not initialized');
      return;
    }

    final item = VoiceQueueItem(
      id: _nextItemId++,
      text: text,
      priority: priority,
      addedAt: DateTime.now(),
      stepIndex: stepIndex,
    );

    // Handle high priority messages
    if (priority == VoicePriority.high) {
      NavigationLogger.debug('VoiceGuidance', '_enqueue high priority', {
        'itemId': item.id,
        'stepIndex': stepIndex,
        'interruptOnHighPriority': options.interruptOnHighPriority,
      });

      if (options.interruptOnHighPriority && _isPlaying) {
        // Interrupt current playback
        NavigationLogger.debug('VoiceGuidance', '_enqueue interrupting current playback');
        _tts.stop().then((_) {
          // Insert at front of queue
          _queue.insert(0, item);
          NavigationLogger.debug('VoiceGuidance', '_enqueue inserted at front after stop', {
            'queueSize': _queue.length,
          });
          _processQueue();
        });
        return;
      } else {
        // Add to front of queue (after other high priority items)
        int insertIndex = 0;
        while (insertIndex < _queue.length &&
            _queue[insertIndex].priority == VoicePriority.high) {
          insertIndex++;
        }
        _queue.insert(insertIndex, item);
        NavigationLogger.debug('VoiceGuidance', '_enqueue inserted high priority', {
          'insertIndex': insertIndex,
          'queueSize': _queue.length,
        });
      }
    } else {
      // Normal priority - add to end of queue
      _queue.add(item);
      NavigationLogger.debug('VoiceGuidance', '_enqueue added item', {
        'itemId': item.id,
        'stepIndex': stepIndex,
        'queueSize': _queue.length,
      });
    }

    // Handle queue overflow
    _handleQueueOverflow();

    // Start processing if not already playing
    if (!_isPlaying && !_isProcessing) {
      _processQueue();
    }
  }

  /// Removes oldest normal-priority items if queue exceeds maxQueueSize.
  void _handleQueueOverflow() {
    if (_queue.length <= options.maxQueueSize) return;

    final overflow = _queue.length - options.maxQueueSize;
    NavigationLogger.debug('VoiceGuidance', '_handleQueueOverflow', {
      'overflow': overflow,
      'maxQueueSize': options.maxQueueSize,
    });

    int removed = 0;
    // Remove oldest normal-priority items (iterate from start)
    for (int i = 0; i < _queue.length && removed < overflow;) {
      if (_queue[i].priority == VoicePriority.normal) {
        NavigationLogger.debug('VoiceGuidance', '_handleQueueOverflow removing', {
          'itemId': _queue[i].id,
        });
        _queue.removeAt(i);
        removed++;
      } else {
        i++;
      }
    }

    if (removed < overflow) {
      NavigationLogger.warn('VoiceGuidance', '_handleQueueOverflow incomplete', {
        'removed': removed,
        'overflow': overflow,
        'reason': 'high priority items protected',
      });
    }
  }

  /// Processes the next item in the queue.
  void _processQueue() {
    // Prevent re-entry
    if (_isProcessing) {
      NavigationLogger.debug('VoiceGuidance', '_processQueue skipped - already processing');
      return;
    }

    // Skip stale items (items for steps we've already passed)
    while (_queue.isNotEmpty) {
      final nextItem = _queue.first;
      // Skip items that belong to old steps
      // High priority items (arrival, off-route) have stepIndex=null and are never skipped
      if (nextItem.stepIndex != null && nextItem.stepIndex! < _currentStepIndex) {
        NavigationLogger.debug('VoiceGuidance', '_processQueue SKIPPING stale item', {
          'itemId': nextItem.id,
          'itemStep': nextItem.stepIndex,
          'currentStep': _currentStepIndex,
        });
        _queue.removeAt(0);
        continue;
      }
      break;
    }

    if (_queue.isEmpty) {
      NavigationLogger.debug('VoiceGuidance', '_processQueue empty, stopping');
      _isPlaying = false;
      _isProcessing = false;
      return;
    }

    _isProcessing = true;

    final item = _queue.removeAt(0);
    _currentItemId = item.id;
    _isPlaying = true;

    NavigationLogger.debug('VoiceGuidance', '_processQueue playing', {
      'itemId': item.id,
      'stepIndex': item.stepIndex,
      'currentStep': _currentStepIndex,
      'remainingQueue': _queue.length,
    });

    _speakDirect(item.text).then((_) {
      _isProcessing = false;
      // Completion handler will call _processQueue() when TTS finishes
    }).catchError((error, stack) {
      NavigationLogger.error('VoiceGuidance', '_processQueue error speaking', error, stack);
      _isPlaying = false;
      _isProcessing = false;
      _currentItemId = null;
      // Try next item
      _processQueue();
    });
  }

  /// Directly speaks text without queue management.
  /// Used internally by _processQueue().
  Future<void> _speakDirect(String text) async {
    try {
      NavigationLogger.debug('VoiceGuidance', '_speakDirect', {
        'textPreview': text.length > 50 ? '${text.substring(0, 50)}...' : text,
      });
      // NO stop() call here - let the queue manage playback
      final result = await _tts.speak(text);
      NavigationLogger.debug('VoiceGuidance', '_speakDirect result', {
        'result': result,
      });
    } catch (error, stack) {
      NavigationLogger.error('VoiceGuidance', '_speakDirect failed', error, stack);
      rethrow;
    }
  }

  // === Queue management methods ===

  /// Clears all pending items from the queue.
  ///
  /// Does NOT stop currently playing audio.
  /// Use [stopAndClear] to also stop current playback.
  void clearQueue() {
    final clearedCount = _queue.length;
    _queue.clear();
    NavigationLogger.debug('VoiceGuidance', 'clearQueue', {
      'clearedCount': clearedCount,
    });
  }

  /// Stops current playback and clears the queue.
  ///
  /// Use this when you need to immediately silence voice guidance,
  /// for example when navigation is cancelled.
  Future<void> stopAndClear() async {
    final clearedCount = _queue.length;
    final wasPlaying = _isPlaying;

    _queue.clear();
    _isPlaying = false;
    _isProcessing = false;
    _currentItemId = null;

    NavigationLogger.info('VoiceGuidance', 'stopAndClear', {
      'clearedCount': clearedCount,
      'wasPlaying': wasPlaying,
    });

    try {
      await _tts.stop();
      NavigationLogger.debug('VoiceGuidance', 'stopAndClear TTS stopped');
    } catch (error) {
      NavigationLogger.warn('VoiceGuidance', 'stopAndClear error stopping TTS', {
        'error': error.toString(),
      });
    }
  }

  // === Queue status getters ===

  /// Returns true if TTS is currently playing.
  bool get isPlaying => _isPlaying;

  /// Returns the current queue size.
  int get queueSize => _queue.length;

  /// Returns a copy of the current queue for debugging.
  List<VoiceQueueItem> get queueSnapshot => List.unmodifiable(_queue);
}

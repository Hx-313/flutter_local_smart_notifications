import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_smart_notifications/flutter_local_smart_notifications.dart';

import 'expense_notification_config.dart';

const _brandLime = Color(0xFFD6FF3F);
const _brandEmerald = Color(0xFF42D89B);
const _brandIvory = Color(0xFFF2F5E8);
const _brandInk = Color(0xFF07110E);
const _brandSurface = Color(0xFF0B211A);
const _brandRaisedSurface = Color(0xFF112A21);
const _brandMutedText = Color(0xFFB5C8BA);
const _statusWarning = Color(0xFFFFC857);

class NotificationLabApp extends StatelessWidget {
  const NotificationLabApp({super.key, this.initialize = true});

  /// Set to false in widget tests or when inspecting the UI on an unsupported
  /// desktop platform. Every operation still returns a typed failure.
  final bool initialize;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Notifications Lab',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: NotificationLabHome(initialize: initialize),
    );
  }

  ThemeData _buildTheme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _brandLime,
          brightness: Brightness.dark,
        ).copyWith(
          primary: _brandLime,
          onPrimary: _brandInk,
          secondary: _brandEmerald,
          onSecondary: _brandInk,
          surface: _brandSurface,
          onSurface: _brandIvory,
          onSurfaceVariant: _brandMutedText,
        );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: _brandInk,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: _brandInk,
        foregroundColor: _brandIvory,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _brandSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _brandRaisedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: _brandLime,
        labelColor: _brandLime,
        unselectedLabelColor: _brandMutedText,
      ),
    );
  }
}

class NotificationLabHome extends StatefulWidget {
  const NotificationLabHome({super.key, required this.initialize});

  final bool initialize;

  @override
  State<NotificationLabHome> createState() => _NotificationLabHomeState();
}

class _NotificationLabHomeState extends State<NotificationLabHome> {
  NotificationService? _service;
  NotificationPermissionStatus? _permissionStatus;
  String? _initializationMessage;
  final List<String> _activity = <String>[];
  StreamSubscription<RoutingEvent>? _routingSubscription;
  StreamSubscription<NotificationPermissionStatus>? _permissionSubscription;

  bool get _isReady => _service?.isInitialized ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.initialize) {
      unawaited(_initializeRuntime());
    }
  }

  @override
  void dispose() {
    unawaited(_routingSubscription?.cancel());
    unawaited(_permissionSubscription?.cancel());
    super.dispose();
  }

  Future<void> _initializeRuntime() async {
    final result = await NotificationService.initialize(
      expenseNotificationConfig,
    );
    if (!mounted) return;
    if (result.isFailure) {
      setState(() {
        _initializationMessage = result.failureOrNull.toString();
      });
      return;
    }

    final service = result.valueOrNull!;
    _service = service;
    _routingSubscription = service.onRoutingEvent.listen((event) {
      _record(
        'Routing event: ${event.source.name} / ${event.interaction.name} '
        '→ ${event.target}',
      );
    });
    _permissionSubscription = service.onPermissionStatusChanged.listen((
      status,
    ) {
      if (!mounted) return;
      setState(() => _permissionStatus = status);
    });
    final permission = await service.checkPermission();
    if (!mounted) return;
    setState(() {
      _permissionStatus = permission.valueOrNull;
      _initializationMessage = permission.isFailure
          ? permission.failureOrNull.toString()
          : 'Runtime initialized';
    });
  }

  void _record(String message) {
    if (!mounted) return;
    setState(() {
      _activity.insert(0, '${TimeOfDay.now().format(context)}  $message');
      if (_activity.length > 12) _activity.removeLast();
    });
  }

  Future<void> _run(
    String label,
    Future<NotificationResult<dynamic>> Function(NotificationService service)
    operation,
  ) async {
    final service = _service ?? NotificationService.instance;
    final result = await operation(service);
    if (!mounted) return;
    final message = result.fold(
      onSuccess: (_) => '$label: success',
      onFailure: (failure) =>
          '$label: ${failure.runtimeType} — ${failure.message}',
    );
    _record(message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestPermission({bool exact = false}) async {
    await _run(
      exact
          ? 'Notification + exact alarm permission'
          : 'Notification permission',
      (service) =>
          service.requestPermission(context: context, includeExactAlarm: exact),
    );
  }

  Future<void> _initializeFromButton() async {
    if (_isReady) return;
    await _initializeRuntime();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: const Row(
            children: [
              _Logo(size: 44),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMART NOTIFICATIONS', style: TextStyle(fontSize: 15)),
                    Text(
                      'Capability lab',
                      style: TextStyle(fontSize: 12, color: _brandMutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(key: Key('tab-matrix'), text: 'Test matrix'),
              Tab(key: Key('tab-instant'), text: 'Instant'),
              Tab(key: Key('tab-schedule'), text: 'Scheduling'),
              Tab(key: Key('tab-reminders'), text: 'Reminders'),
            ],
          ),
        ),
        body: Column(
          children: [
            _RuntimeBanner(
              ready: _isReady,
              permissionStatus: _permissionStatus,
              message: _initializationMessage,
              onInitialize: _initializeFromButton,
              onRequestPermission: _requestPermission,
              onRequestExact: () => _requestPermission(exact: true),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TestMatrix(onRecord: _record),
                  _InstantPage(onRun: _run),
                  _SchedulingPage(onRun: _run),
                  _RemindersPage(onRun: _run),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _ActivityBar(activity: _activity),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: Image.asset(
        'assets/logo.png',
        key: const Key('app-logo'),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.primary,
          alignment: Alignment.center,
          child: const Icon(Icons.notifications_active),
        ),
      ),
    );
  }
}

class _RuntimeBanner extends StatelessWidget {
  const _RuntimeBanner({
    required this.ready,
    required this.permissionStatus,
    required this.message,
    required this.onInitialize,
    required this.onRequestPermission,
    required this.onRequestExact,
  });

  final bool ready;
  final NotificationPermissionStatus? permissionStatus;
  final String? message;
  final VoidCallback onInitialize;
  final VoidCallback onRequestPermission;
  final VoidCallback onRequestExact;

  @override
  Widget build(BuildContext context) {
    final color = ready ? _brandEmerald : _statusWarning;
    final status = permissionStatus == null
        ? 'Permission not checked'
        : permissionStatus.runtimeType.toString();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: _brandSurface,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                ready ? Icons.check_circle : Icons.info,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ready
                      ? 'Runtime ready · $status'
                      : 'Runtime not initialized · $status',
                  key: const Key('runtime-status'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              if (!ready)
                TextButton(
                  key: const Key('initialize-button'),
                  onPressed: onInitialize,
                  child: const Text('Initialize'),
                ),
            ],
          ),
          if (message != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message!,
                key: const Key('runtime-message'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _brandMutedText, fontSize: 12),
              ),
            ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('permission-button'),
                onPressed: onRequestPermission,
                icon: const Icon(Icons.notifications_outlined, size: 16),
                label: const Text('Ask permission'),
              ),
              OutlinedButton.icon(
                key: const Key('exact-permission-button'),
                onPressed: onRequestExact,
                icon: const Icon(Icons.alarm, size: 16),
                label: const Text('Ask exact alarm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestMatrix extends StatefulWidget {
  const _TestMatrix({required this.onRecord});

  final ValueChanged<String> onRecord;

  @override
  State<_TestMatrix> createState() => _TestMatrixState();
}

class _TestMatrixState extends State<_TestMatrix> {
  final List<_MatrixResult> _results = <_MatrixResult>[];
  bool _running = false;

  void _runAll() {
    setState(() => _running = true);
    final results = <_MatrixResult>[];
    void check(String name, bool passed, String detail) {
      results.add(_MatrixResult(name: name, passed: passed, detail: detail));
    }

    const payload = NotificationPayload(
      id: 100,
      title: 'Matrix payload',
      body: 'Nested application data',
      channelId: 'general',
      data: {
        'route': '/expenses',
        'filters': {'month': 9},
      },
      silent: true,
    );
    final payloadCopy = NotificationPayload.fromMap(payload.toMap());
    check(
      'Payload data round trip',
      payloadCopy.data['filters'] is Map && payloadCopy.silent,
      'nested data and silent flag preserved',
    );

    final schedule = ScheduledNotification(
      payload: payload,
      scheduledTime: DateTime(2026, 9, 21, 9),
      repeatInterval: RepeatInterval.weekly,
      exactTiming: true,
      semantics: NotificationScheduleSemantics.localWallClock,
    );
    final scheduleCopy = ScheduledNotification.fromMap(schedule.toMap());
    check(
      'Schedule recurrence round trip',
      scheduleCopy.repeatInterval == RepeatInterval.weekly &&
          scheduleCopy.exactTiming &&
          scheduleCopy.semantics ==
              NotificationScheduleSemantics.localWallClock,
      'weekly, exact, and local-wall-clock flags preserved',
    );

    final reminder = ReminderNotification(
      payload: payload,
      scheduledTime: DateTime(2026, 9, 22, 8),
      timeout: const Duration(minutes: 10),
      persistent: true,
      fullScreenIntent: true,
      exactTiming: true,
      actions: const [
        NotificationAction(id: 'open', title: 'Open'),
        NotificationAction(
          id: 'dismiss',
          title: 'Dismiss',
          cancelNotification: true,
          openApp: false,
        ),
      ],
      semantics: NotificationScheduleSemantics.absoluteInstant,
    );
    final reminderCopy = ReminderNotification.fromMap(reminder.toMap());
    check(
      'Reminder policy round trip',
      !reminderCopy.isInstant &&
          reminderCopy.persistent &&
          reminderCopy.fullScreenIntent &&
          reminderCopy.actions.length == 2,
      'scheduled persistent reminder policy preserved',
    );

    check(
      'App config declares every provider',
      expenseNotificationConfig.enabledProviders.length == 3 &&
          expenseNotificationConfig.channelIds.contains('due_dates'),
      'instant, scheduled, reminder, general, reminders, due_dates',
    );
    check(
      'All recurrence modes are available',
      RepeatInterval.values.length == 5,
      'none, daily, weekly, monthly, yearly',
    );
    check(
      'Both timezone semantics are available',
      NotificationScheduleSemantics.values.length == 2,
      'absolute instant and local wall clock',
    );

    setState(() {
      _results
        ..clear()
        ..addAll(results);
      _running = false;
    });
    widget.onRecord(
      'Matrix: ${results.where((result) => result.passed).length}/'
      '${results.length} checks passed',
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const _SectionIntro(
          eyebrow: 'PUBLIC API VERIFICATION',
          title: 'Run the capability matrix',
          description:
              'These checks exercise public entities and app configuration without creating real alarms. Use the other tabs for device-backed delivery tests.',
        ),
        FilledButton.icon(
          key: const Key('run-matrix'),
          onPressed: _running ? null : _runAll,
          icon: _running
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fact_check_outlined),
          label: Text(_running ? 'Running checks…' : 'Run all local checks'),
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '${_results.where((result) => result.passed).length}/${_results.length} checks passed',
            key: const Key('matrix-summary'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._results.map((result) => _MatrixResultTile(result: result)),
        ],
        const SizedBox(height: 16),
        const _InfoCard(
          icon: Icons.phone_android,
          title: 'Device test checklist',
          body:
              'On Android, validate API 31, 33, 34, and 35+: permission denial, exact-alarm refusal, reboot restoration, timezone changes, notification taps, and action taps. On iOS, validate settings return and the 64-pending limit.',
        ),
      ],
    );
  }
}

class _InstantPage extends StatelessWidget {
  const _InstantPage({required this.onRun});

  final Future<void> Function(
    String label,
    Future<NotificationResult<dynamic>> Function(NotificationService service)
    operation,
  )
  onRun;

  NotificationPayload _payload({
    required int id,
    required String title,
    required String body,
    String channelId = 'general',
    bool silent = false,
    String? soundName,
  }) => NotificationPayload(
    id: id,
    title: title,
    body: body,
    channelId: channelId,
    data: const {'route': '/expenses', 'source': 'notification_lab'},
    silent: silent,
    soundName: soundName,
  );

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const _SectionIntro(
          eyebrow: 'LOCAL INSTANT',
          title: 'Instant notifications',
          description:
              'Fire immediately on a physical device. Tap notifications to observe onRoutingEvent in the activity feed.',
        ),
        _CaseCard(
          title: 'Basic alert',
          description: 'Title, body, channel, and routing data.',
          tags: const ['general', 'tap routing'],
          buttonKey: 'instant-basic',
          onPressed: () => onRun(
            'Basic instant notification',
            (service) => service.showNotification(
              _payload(
                id: 1101,
                title: 'Expense recorded',
                body: 'Your coffee expense was added.',
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Silent presentation',
          description: 'Exercises silent delivery for this notification.',
          tags: const ['silent'],
          buttonKey: 'instant-silent',
          onPressed: () => onRun(
            'Silent instant notification',
            (service) => service.showNotification(
              _payload(
                id: 1103,
                title: 'Monthly report ready',
                body: 'Open the report to review your spending.',
                channelId: 'reminders',
                silent: true,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Cancel this notification',
          description: 'Cancel by ID using the shared cancel API.',
          tags: const ['cancelNotification'],
          buttonKey: 'instant-cancel',
          onPressed: () => onRun(
            'Cancel notification 1103',
            (service) => service.cancelNotification(1103),
          ),
        ),
        _CaseCard(
          title: 'Cancel everything',
          description: 'Cancel instant, scheduled, and reminder work.',
          tags: const ['cancelAll'],
          buttonKey: 'instant-cancel-all',
          onPressed: () => onRun(
            'Cancel all notifications',
            (service) => service.cancelAll(),
          ),
        ),
      ],
    );
  }
}

class _SchedulingPage extends StatelessWidget {
  const _SchedulingPage({required this.onRun});

  final Future<void> Function(
    String label,
    Future<NotificationResult<dynamic>> Function(NotificationService service)
    operation,
  )
  onRun;

  DateTime _after(Duration duration) => DateTime.now().add(duration);

  ScheduledNotification _schedule({
    required int id,
    required String title,
    required DateTime at,
    RepeatInterval repeat = RepeatInterval.none,
    bool exact = false,
    NotificationScheduleSemantics semantics =
        NotificationScheduleSemantics.absoluteInstant,
  }) => ScheduledNotification(
    payload: NotificationPayload(
      id: id,
      title: title,
      body: 'Scheduled from the notification lab.',
      channelId: repeat == RepeatInterval.none ? 'general' : 'reminders',
      data: const {'route': '/schedule'},
    ),
    scheduledTime: at,
    repeatInterval: repeat,
    exactTiming: exact,
    allowWhileIdle: true,
    semantics: semantics,
  );

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const _SectionIntro(
          eyebrow: 'LOCAL SCHEDULED',
          title: 'Time, recurrence, and timezone semantics',
          description:
              'Each schedule below is future-dated. Exact cases require the Android special access grant and never silently downgrade.',
        ),
        _CaseCard(
          title: 'One-shot · absolute · inexact',
          description:
              'A fixed instant that is allowed to use platform inexact timing.',
          tags: const ['none', 'absoluteInstant', 'inexact'],
          buttonKey: 'schedule-one-shot',
          onPressed: () => onRun(
            'One-shot schedule',
            (service) => service.scheduleNotification(
              _schedule(
                id: 2101,
                title: 'One-shot expense check',
                at: _after(const Duration(minutes: 1)),
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'One-shot · absolute · exact',
          description: 'A fixed instant that must be precise on Android.',
          tags: const ['none', 'absoluteInstant', 'exactTiming'],
          buttonKey: 'schedule-exact',
          onPressed: () => onRun(
            'Exact schedule',
            (service) => service.scheduleNotification(
              _schedule(
                id: 2102,
                title: 'Exact bill deadline',
                at: _after(const Duration(minutes: 2)),
                exact: true,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Daily · local wall clock',
          description:
              'Every day at the local calendar time; resyncs after timezone changes.',
          tags: const ['daily', 'localWallClock'],
          buttonKey: 'schedule-daily',
          onPressed: () => onRun(
            'Daily wall-clock schedule',
            (service) => service.scheduleNotification(
              _schedule(
                id: 2103,
                title: 'Daily expense check-in',
                at: _after(const Duration(minutes: 3)),
                repeat: RepeatInterval.daily,
                semantics: NotificationScheduleSemantics.localWallClock,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Weekly · local wall clock',
          description:
              'A weekly reminder that follows local wall-clock meaning.',
          tags: const ['weekly', 'localWallClock'],
          buttonKey: 'schedule-weekly',
          onPressed: () => onRun(
            'Weekly wall-clock schedule',
            (service) => service.scheduleNotification(
              _schedule(
                id: 2104,
                title: 'Weekly budget review',
                at: _after(const Duration(minutes: 4)),
                repeat: RepeatInterval.weekly,
                semantics: NotificationScheduleSemantics.localWallClock,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Monthly · absolute instant',
          description:
              'Monthly recurrence with a fixed-instant interpretation.',
          tags: const ['monthly', 'absoluteInstant'],
          buttonKey: 'schedule-monthly',
          onPressed: () => onRun(
            'Monthly absolute schedule',
            (service) => service.scheduleNotification(
              _schedule(
                id: 2105,
                title: 'Monthly statement review',
                at: _after(const Duration(minutes: 5)),
                repeat: RepeatInterval.monthly,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Yearly · local wall clock',
          description:
              'Yearly recurrence that keeps its local calendar meaning.',
          tags: const ['yearly', 'localWallClock'],
          buttonKey: 'schedule-yearly',
          onPressed: () => onRun(
            'Yearly wall-clock schedule',
            (service) => service.scheduleNotification(
              _schedule(
                id: 2106,
                title: 'Yearly tax reminder',
                at: _after(const Duration(minutes: 6)),
                repeat: RepeatInterval.yearly,
                semantics: NotificationScheduleSemantics.localWallClock,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Past-time rejection',
          description:
              'Negative test: the public API must return PastTimeFailure.',
          tags: const ['negative case', 'PastTimeFailure'],
          buttonKey: 'schedule-past',
          onPressed: () => onRun(
            'Past-time rejection',
            (service) => service.scheduleNotification(
              _schedule(
                id: 2199,
                title: 'Invalid past schedule',
                at: DateTime.now().subtract(const Duration(minutes: 1)),
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Pending IDs',
          description: 'Inspect platform-pending scheduled notification IDs.',
          tags: const ['getPendingScheduled'],
          buttonKey: 'schedule-pending',
          onPressed: () => onRun('Read pending schedules', (service) async {
            final result = await service.getPendingScheduled();
            if (result.isSuccess) {
              return NotificationSuccess<dynamic>(
                'Pending IDs: ${result.valueOrNull!.join(', ')}',
              );
            }
            return NotificationFailureResult<dynamic>(result.failureOrNull!);
          }),
        ),
        _CaseCard(
          title: 'Cancel all schedules',
          description:
              'Remove every scheduled notification while leaving other app state intact.',
          tags: const ['cancelAllScheduled'],
          buttonKey: 'schedule-cancel-all',
          onPressed: () => onRun(
            'Cancel all schedules',
            (service) => service.cancelAllScheduled(),
          ),
        ),
      ],
    );
  }
}

class _RemindersPage extends StatelessWidget {
  const _RemindersPage({required this.onRun});

  final Future<void> Function(
    String label,
    Future<NotificationResult<dynamic>> Function(NotificationService service)
    operation,
  )
  onRun;

  ReminderNotification _reminder({
    required int id,
    required String title,
    DateTime? at,
    bool fullScreen = false,
    bool exact = false,
    NotificationScheduleSemantics semantics =
        NotificationScheduleSemantics.absoluteInstant,
  }) => ReminderNotification(
    payload: NotificationPayload(
      id: id,
      title: title,
      body: 'High-priority reminder from the notification lab.',
      channelId: 'due_dates',
      data: const {'route': '/reminders'},
    ),
    scheduledTime: at,
    timeout: const Duration(minutes: 10),
    persistent: true,
    fullScreenIntent: fullScreen,
    exactTiming: exact,
    actions: const [
      NotificationAction(id: 'done', title: 'Done'),
      NotificationAction(id: 'snooze', title: 'Snooze'),
    ],
    semantics: semantics,
  );

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const _SectionIntro(
          eyebrow: 'PERSISTENT REMINDERS',
          title: 'High-priority alert behavior',
          description:
              'Reminders can be instant or scheduled, with explicit timeout, action, and full-screen policy.',
        ),
        _CaseCard(
          title: 'Instant persistent reminder',
          description:
              'Immediate high-priority reminder with Android action buttons.',
          tags: const ['instant', 'persistent', 'actions'],
          buttonKey: 'reminder-instant',
          onPressed: () => onRun(
            'Instant reminder',
            (service) => service.showReminder(
              _reminder(id: 3101, title: 'Payment due soon'),
            ),
          ),
        ),
        _CaseCard(
          title: 'Scheduled exact reminder',
          description:
              'Future reminder that requires exact-alarm access when exactTiming is true.',
          tags: const ['scheduled', 'exactTiming', 'absoluteInstant'],
          buttonKey: 'reminder-exact',
          onPressed: () => onRun(
            'Exact reminder',
            (service) => service.scheduleReminder(
              _reminder(
                id: 3102,
                title: 'Exact bill alert',
                at: DateTime.now().add(const Duration(minutes: 2)),
                exact: true,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Local wall-clock reminder',
          description:
              'Scheduled reminder that is re-synced after a device timezone change.',
          tags: const ['scheduled', 'localWallClock', 'reboot-safe'],
          buttonKey: 'reminder-wall-clock',
          onPressed: () => onRun(
            'Wall-clock reminder',
            (service) => service.scheduleReminder(
              _reminder(
                id: 3103,
                title: 'Local morning reminder',
                at: DateTime.now().add(const Duration(minutes: 3)),
                semantics: NotificationScheduleSemantics.localWallClock,
              ),
            ),
          ),
        ),
        _CaseCard(
          title: 'Full-screen intent policy',
          description:
              'Exercises the explicit fullScreenIntent flag for alarm-like experiences.',
          tags: const ['fullScreenIntent'],
          buttonKey: 'reminder-full-screen',
          onPressed: () => onRun(
            'Full-screen reminder',
            (service) => service.showReminder(
              _reminder(id: 3104, title: 'Critical due date', fullScreen: true),
            ),
          ),
        ),
        _CaseCard(
          title: 'Cancel reminder by ID',
          description: 'Remove one active reminder.',
          tags: const ['cancelReminder'],
          buttonKey: 'reminder-cancel',
          onPressed: () => onRun(
            'Cancel reminder 3103',
            (service) => service.cancelReminder(3103),
          ),
        ),
        _CaseCard(
          title: 'Cancel all reminders',
          description: 'Remove all persistent reminders.',
          tags: const ['cancelAllReminders'],
          buttonKey: 'reminder-cancel-all',
          onPressed: () => onRun(
            'Cancel all reminders',
            (service) => service.cancelAllReminders(),
          ),
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        itemCount: children.length,
        itemBuilder: (_, index) => children[index],
        separatorBuilder: (_, _) => const SizedBox(height: 12),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.title,
    required this.description,
    required this.tags,
    required this.buttonKey,
    required this.onPressed,
  });

  final String title;
  final String description;
  final List<String> tags;
  final String buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: Key(buttonKey),
                onPressed: onPressed,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Run case'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatrixResult {
  const _MatrixResult({
    required this.name,
    required this.passed,
    required this.detail,
  });

  final String name;
  final bool passed;
  final String detail;
}

class _MatrixResultTile extends StatelessWidget {
  const _MatrixResultTile({required this.result});

  final _MatrixResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = result.passed ? scheme.secondary : scheme.error;
    return Card(
      child: ListTile(
        leading: Icon(
          result.passed ? Icons.check_circle : Icons.error,
          color: color,
        ),
        title: Text(result.name),
        subtitle: Text(result.detail),
        trailing: Text(
          result.passed ? 'PASS' : 'FAIL',
          style: TextStyle(color: color),
        ),
      ),
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({required this.activity});

  final List<String> activity;

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Text(
            'Activity will appear here after running a case.',
            style: TextStyle(color: _brandMutedText),
          ),
        ),
      );
    }
    return SafeArea(
      child: ExpansionTile(
        initiallyExpanded: false,
        title: Text(
          'Activity · ${activity.length}',
          style: const TextStyle(fontSize: 13),
        ),
        children: activity
            .map(
              (entry) => ListTile(
                dense: true,
                leading: const Icon(Icons.chevron_right, size: 16),
                title: Text(entry, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
      ),
    );
  }
}

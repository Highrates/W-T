import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../features/event/data/event_route_points_mock.dart';
import '../../../features/shell/application/feed_controller.dart';
import '../../../features/shell/data/feed_filter_mock.dart';
import '../../../ui/dialogs/app_dialog.dart';
import '../data/create_route_draft_storage.dart';
import '../data/create_route_geo.dart';
import '../data/create_route_sources_mock.dart';
import '../domain/create_route_draft.dart';
import '../domain/create_route_join_mode.dart';
import '../domain/create_route_source.dart';
import '../domain/create_route_step.dart';

final createRouteControllerProvider =
    NotifierProvider<CreateRouteController, CreateRouteWizardState>(
  CreateRouteController.new,
);

final createRouteDraftExistsProvider = FutureProvider<bool>((ref) async {
  return ref.read(createRouteDraftStorageProvider).hasDraft();
});

class CreateRouteWizardState {
  const CreateRouteWizardState({
    this.step = CreateRouteStep.source,
    this.draft = const CreateRouteDraft(),
    this.isPublishing = false,
  });

  final CreateRouteStep step;
  final CreateRouteDraft draft;
  final bool isPublishing;

  CreateRouteWizardState copyWith({
    CreateRouteStep? step,
    CreateRouteDraft? draft,
    bool? isPublishing,
  }) {
    return CreateRouteWizardState(
      step: step ?? this.step,
      draft: draft ?? this.draft,
      isPublishing: isPublishing ?? this.isPublishing,
    );
  }
}

class CreateRouteController extends Notifier<CreateRouteWizardState> {
  @override
  CreateRouteWizardState build() => const CreateRouteWizardState();

  CreateRouteDraftStorage get _storage =>
      ref.read(createRouteDraftStorageProvider);

  void _commit(CreateRouteWizardState next) {
    state = next;
    _storage.save(state);
  }

  void reset() {
    _commit(const CreateRouteWizardState());
  }

  Future<void> discardDraft() async {
    await _storage.clear();
    reset();
  }

  Future<bool> tryRestoreDraft(BuildContext context) async {
    final saved = await _storage.load();
    if (saved == null) return false;

    if (!context.mounted) return false;
    final action = await showAppDialog<_DraftResumeAction>(
      context: context,
      title: 'Есть черновик',
      message: 'Продолжить заполнение или начать новый маршрут?',
      actions: [
        const AppDialogAction(
          label: 'Продолжить',
          value: _DraftResumeAction.resume,
          isPrimary: true,
        ),
        const AppDialogAction(
          label: 'Новый',
          value: _DraftResumeAction.newRoute,
        ),
        const AppDialogAction(
          label: 'Отмена',
          value: _DraftResumeAction.cancel,
        ),
      ],
    );

    if (!context.mounted) return false;

    return switch (action) {
      _DraftResumeAction.resume => () {
          _commit(saved);
          return true;
        }(),
      _DraftResumeAction.newRoute => () {
          discardDraft();
          return false;
        }(),
      _DraftResumeAction.cancel => () {
          if (context.mounted) Navigator.of(context).pop();
          return false;
        }(),
      null => false,
    };
  }

  void setSource(CreateRouteSource source) {
    _commit(
      state.copyWith(
        draft: state.draft.copyWith(
          source: source,
          clearSourceEventId: source == CreateRouteSource.blank,
        ),
      ),
    );
  }

  void selectSourceEvent(String eventId) {
    final event = CreateRouteSourcesMock.previousEventById(eventId);
    if (event == null) return;

    final points = _pointsFromEvent(eventId);
    _commit(
      state.copyWith(
        draft: _freshParticipationDefaults().copyWith(
          source: CreateRouteSource.fromPrevious,
          sourceEventId: eventId,
          formatIds: event.formatIds.toSet(),
          themeIds: event.themeIds.toSet(),
          title: event.title,
          description: '',
          cityId: _cityFromStart(points) ?? event.cityId,
          points: points,
          clearScheduledAt: true,
        ),
      ),
    );
  }

  void selectTemplate(String templateId) {
    final template = CreateRouteSourcesMock.templateOptions
        .where((option) => option.id == templateId)
        .firstOrNull;
    if (template == null) return;

    final seeded = switch (templateId) {
      'tpl_terrenkur' => (
          formatIds: {FeedHotFilterMock.walkId},
          themeIds: {FeedHotFilterMock.natureId, FeedHotFilterMock.foodId},
        ),
      'tpl_culture_walk' => (
          formatIds: {FeedHotFilterMock.walkId},
          themeIds: {FeedHotFilterMock.cultureId},
        ),
      'tpl_drive_sunset' => (
          formatIds: {FeedHotFilterMock.driveId},
          themeIds: {FeedHotFilterMock.natureId},
        ),
      _ => (
          formatIds: {FeedHotFilterMock.walkId},
          themeIds: <String>{FeedHotFilterMock.socialId},
        ),
    };

    final points = _defaultPoints();
    _commit(
      state.copyWith(
        draft: _freshParticipationDefaults().copyWith(
          source: CreateRouteSource.fromTemplate,
          sourceEventId: templateId,
          formatIds: seeded.formatIds,
          themeIds: seeded.themeIds,
          title: '',
          description: '',
          cityId: _cityFromStart(points) ?? 'sochi',
          points: points,
          coverAssets: const [],
          clearScheduledAt: true,
        ),
      ),
    );
  }

  void toggleHotFilter(String id) {
    if (FeedHotFilterMock.isFormatId(id)) {
      final formats = Set<String>.from(state.draft.formatIds);
      if (formats.contains(id)) {
        formats.remove(id);
      } else {
        formats.add(id);
      }
      _commit(state.copyWith(draft: state.draft.copyWith(formatIds: formats)));
      return;
    }
    toggleThemeId(id);
  }

  void toggleThemeId(String themeId) {
    final themes = Set<String>.from(state.draft.themeIds);
    if (themes.contains(themeId)) {
      themes.remove(themeId);
    } else {
      themes.add(themeId);
    }
    _commit(state.copyWith(draft: state.draft.copyWith(themeIds: themes)));
  }

  void setBasics({
    required String title,
    required String description,
  }) {
    _commit(
      state.copyWith(
        draft: state.draft.copyWith(
          title: title.trim(),
          description: description.trim(),
        ),
      ),
    );
  }

  void setSchedule({
    required DateTime? scheduledAt,
    required bool hideExactTime,
  }) {
    _commit(
      state.copyWith(
        draft: state.draft.copyWith(
          scheduledAt: scheduledAt,
          hideExactTime: hideExactTime,
        ),
      ),
    );
  }

  void setPoints(List<CreateRoutePointDraft> points) {
    _commit(
      state.copyWith(
        draft: state.draft.copyWith(
          points: points,
          cityId: _cityFromStart(points) ?? state.draft.cityId,
        ),
      ),
    );
  }

  void addPoint(CreateRoutePointDraft point) {
    var points = [...state.draft.points];
    if (point.isStart) {
      points = points
          .map((existing) => existing.copyWith(isStart: false))
          .toList();
    }
    if (point.isFinish) {
      points = points
          .map((existing) => existing.copyWith(isFinish: false))
          .toList();
    }
    points.add(point);
    setPoints(points);
  }

  void removePointAt(int index) {
    final points = [...state.draft.points]..removeAt(index);
    setPoints(points);
  }

  void updatePointAt(int index, CreateRoutePointDraft point) {
    final points = [...state.draft.points];
    if (index < 0 || index >= points.length) return;
    points[index] = point;
    setPoints(points);
  }

  void setCoverAssets(List<String> assets) {
    _commit(state.copyWith(draft: state.draft.copyWith(coverAssets: assets)));
  }

  void addCoverPaths(List<String> paths) {
    if (paths.isEmpty) return;
    setCoverAssets([...state.draft.coverAssets, ...paths]);
  }

  void removeCoverAt(int index) {
    final covers = [...state.draft.coverAssets];
    if (index < 0 || index >= covers.length) return;
    covers.removeAt(index);
    setCoverAssets(covers);
  }

  void setParticipation({
    required bool isOneOnOne,
    required int? maxParticipants,
    CreateRouteJoinMode? joinMode,
  }) {
    _commit(
      state.copyWith(
        draft: state.draft.copyWith(
          isOneOnOne: isOneOnOne,
          maxParticipants: isOneOnOne ? 2 : maxParticipants,
          joinMode: joinMode ??
              defaultCreateRouteJoinMode(isOneOnOne: isOneOnOne),
        ),
      ),
    );
  }

  String? validateStep(CreateRouteStep step) {
    final draft = state.draft;
    return switch (step) {
      CreateRouteStep.source => switch (draft.source) {
          CreateRouteSource.fromPrevious when draft.sourceEventId == null =>
            'Выберите прошлый маршрут',
          CreateRouteSource.fromTemplate when draft.sourceEventId == null =>
            'Выберите шаблон',
          _ => null,
        },
      CreateRouteStep.formatAndTheme =>
        draft.hotFilterIds.isEmpty ? 'Выберите хотя бы один тег' : null,
      CreateRouteStep.basics =>
        draft.title.trim().isEmpty ? 'Укажите название' : null,
      CreateRouteStep.schedule =>
        draft.scheduledAt == null ? 'Укажите дату и время' : null,
      CreateRouteStep.routePoints =>
        !draft.hasStartPoint || !draft.hasFinishPoint
            ? 'Нужны точки старта и финиша'
            : draft.startPoint == null
                ? 'Добавьте точку старта'
                : null,
      CreateRouteStep.pointDetails => null,
      CreateRouteStep.photos => null,
      CreateRouteStep.participation =>
        !draft.isOneOnOne &&
                (draft.maxParticipants == null || draft.maxParticipants! < 2)
            ? 'Укажите лимит от 2 человек'
            : null,
      CreateRouteStep.review => null,
    };
  }

  bool goNext() {
    final error = validateStep(state.step);
    if (error != null) return false;
    final next = state.step.next;
    if (next == null) return false;
    final draft = next == CreateRouteStep.basics
        ? state.draft.copyWith(description: '')
        : state.draft;
    _commit(state.copyWith(step: next, draft: draft));
    return true;
  }

  void goBack() {
    final previous = state.step.previous;
    if (previous == null) return;
    _commit(state.copyWith(step: previous));
  }

  Future<String?> publish() async {
    final error = validateStep(CreateRouteStep.review);
    if (error != null) return null;

    _commit(state.copyWith(isPublishing: true));
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final draft = state.draft.copyWith(
      cityId: _cityFromStart(state.draft.points) ?? state.draft.cityId,
    );

    final eventId =
        ref.read(eventRepositoryProvider).publishFromDraft(draft);

    await _storage.clear();
    ref.invalidate(feedControllerProvider);
    ref.invalidate(createRouteDraftExistsProvider);

    _commit(const CreateRouteWizardState());
    return eventId;
  }

  CreateRouteDraft _freshParticipationDefaults() {
    return CreateRouteDraft(
      joinMode: defaultCreateRouteJoinMode(isOneOnOne: false),
      maxParticipants: 6,
      isOneOnOne: false,
    );
  }

  String? _cityFromStart(List<CreateRoutePointDraft> points) {
    final start = points.where((point) => point.isStart).firstOrNull;
    if (start == null) return null;
    return start.cityId ?? CreateRouteGeo.resolveCityId(start.location);
  }

  List<CreateRoutePointDraft> _pointsFromEvent(String eventId) {
    final route = EventRoutePointsMock.forEvent(eventId);
    return route
        .asMap()
        .entries
        .map(
          (entry) {
            final cityId = entry.key == 0
                ? CreateRouteGeo.resolveCityId(entry.value.location)
                : entry.value.location.latitude > 0
                    ? CreateRouteGeo.resolveCityId(entry.value.location)
                    : null;
            return CreateRoutePointDraft(
              title: entry.value.title,
              location: entry.value.location,
              detail: entry.value.detail,
              address: entry.value.address,
              description: entry.value.description,
              photoAssets: entry.value.photoAssets,
              cityId: cityId,
              isStart: entry.key == 0,
              isFinish: entry.key == route.length - 1,
            );
          },
        )
        .toList(growable: false);
  }

  List<CreateRoutePointDraft> _defaultPoints() {
    final mock = EventRoutePointsMock.forEvent('terrenkur');
    if (mock.isEmpty) return const [];
    return [
      CreateRoutePointDraft(
        title: mock.first.title,
        location: mock.first.location,
        detail: mock.first.detail,
        address: mock.first.address,
        description: mock.first.description,
        photoAssets: mock.first.photoAssets,
        cityId: CreateRouteGeo.resolveCityId(mock.first.location),
        isStart: true,
      ),
      if (mock.length > 1)
        CreateRoutePointDraft(
          title: mock.last.title,
          location: mock.last.location,
          detail: mock.last.detail,
          address: mock.last.address,
          description: mock.last.description,
          photoAssets: mock.last.photoAssets,
          cityId: CreateRouteGeo.resolveCityId(mock.last.location),
          isFinish: true,
        ),
    ];
  }
}

enum _DraftResumeAction { resume, newRoute, cancel }

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

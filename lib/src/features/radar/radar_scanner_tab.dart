import 'dart:async';

import 'package:accessibility_radar/src/core/accessibility_types.dart';
import 'package:accessibility_radar/src/core/inspector_utils.dart';
import 'package:accessibility_radar/src/features/radar/data/inspector_bridge.dart';
import 'package:accessibility_radar/src/features/radar/domain/tree_scanner.dart' hide formatPropertiesForTooltip;
import 'package:accessibility_radar/src/features/radar/presentation/hit_list_filter.dart';
import 'package:accessibility_radar/src/features/radar/presentation/widgets/hit_tile.dart';
import 'package:accessibility_radar/src/features/radar/presentation/widgets/semantic_hint_message_body.dart';
import 'package:accessibility_radar/src/features/radar/presentation/widgets/wcag_hint_header.dart';
import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/service_extensions.dart' as extensions;
import 'package:devtools_app_shared/utils.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

class RadarScannerTab extends StatefulWidget {
  const RadarScannerTab({super.key});

  @override
  State<RadarScannerTab> createState() => _RadarScannerTabState();
}

class _RadarScannerTabState extends State<RadarScannerTab>
    with AutoDisposeMixin {
  static const double _kPanelSplitterWidth = 8;
  static const double _kMinListPanelFraction = 0.18;
  static const double _kMaxListPanelFraction = 0.82;

  final _bridge = InspectorBridge(serviceManager);
  final _evalDisposable = Disposable();

  bool _busy = false;
  String? _error;
  List<AccessibilityHit> _hits = const [];
  AccessibilityHit? _hovered;
  String? _hoverPropsText;
  EvalOnDartLibrary? _widgetsEval;
  HitListFilter _listFilter = HitListFilter.all;

  double _listPanelFraction = 2 / 5;

  @override
  void initState() {
    super.initState();
    addAutoDisposeListener(serviceManager.connectedState, _onConnectionChange);
    _onConnectionChange();
  }

  @override
  void dispose() {
    _widgetsEval?.dispose();
    _evalDisposable.dispose();
    super.dispose();
  }

  void _onConnectionChange() {
    if (!serviceManager.connectedState.value.connected) {
      _widgetsEval?.dispose();
      _widgetsEval = null;
      setState(() {
        _hits = const [];
        _error = 'Connect a running Flutter app (debug or profile).';
      });
    } else {
      setState(() {
        _error = null;
      });
    }
  }

  List<AccessibilityHit> _visibleHits() {
    switch (_listFilter) {
      case HitListFilter.all:
        return _hits;
      case HitListFilter.foundOnly:
        return _hits.where((h) => !h.isSemanticSuggestion).toList();
      case HitListFilter.hintsOnly:
        return _hits.where((h) => h.isSemanticSuggestion).toList();
      case HitListFilter.warningsOnly:
        return _hits.where((h) => h.hasSemanticWarnings).toList();
    }
  }

  void _setListFilter(HitListFilter next) {
    setState(() {
      _listFilter = next;
      final visible = _visibleHits();
      if (_hovered != null && !visible.contains(_hovered)) {
        _hovered = null;
        _hoverPropsText = null;
      }
    });
  }

  Future<void> _enrichInspectorPropertyTextForHeuristics(
    Map<String, Object?>? root,
    InspectorBridge bridge,
  ) async {
    if (root == null) {
      return;
    }
    Future<void> visit(Map<String, Object?> node) async {
      final String type = node['widgetRuntimeType'] as String? ?? '';
      final String? valueId = node['valueId'] as String?;
      if (valueId != null && _wantsInspectorPropertyTextForHeuristics(type)) {
        final List<Object?>? list = await bridge.getProperties(valueId);
        final String text = flattenInspectorPropertyDescriptions(list);
        if (text.isNotEmpty) {
          node[kAccessibilityInspectorPropertyTextKey] = text;
        }
      }
      final Object? children = node['children'];
      if (children is List) {
        for (final Object? c in children) {
          if (c is Map<String, Object?>) {
            await visit(c);
          } else if (c is Map) {
            await visit(Map<String, Object?>.from(c));
          }
        }
      }
    }
    await visit(root);
  }

  bool _wantsInspectorPropertyTextForHeuristics(String type) {
    return type.contains('TextField') ||
        type.contains('TextFormField') ||
        type == 'CupertinoTextField' ||
        type.contains('DropdownButtonFormField');
  }

  Future<void> _refresh() async {
    if (!serviceManager.connectedState.value.connected) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final tree = await _bridge.getRootWidgetTree(summaryTree: false);
      await _enrichInspectorPropertyTextForHeuristics(tree, _bridge);
      final hits = scanInspectorTree(
        tree,
        includeSemanticGapHints: true,
        includeSemanticWarnings: true,
        filterToLocalProject: true,
      );
      if (mounted) {
        setState(() {
          _hits = hits;
          _busy = false;
          final visible = _visibleHits();
          if (_hovered != null && !visible.contains(_hovered)) {
            _hovered = null;
            _hoverPropsText = null;
          }
        });
        unawaited(_ensureInspectorOverlay());
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e\n$st';
        });
      }
    }
  }

  /// Enables the on-device inspector overlay via [extensions.toggleOnDeviceWidgetInspector].
  Future<void> _ensureInspectorOverlay() async {
    final mgr = serviceManager.serviceExtensionManager;
    final toggle = extensions.toggleOnDeviceWidgetInspector;
    await mgr.waitForServiceExtensionAvailable(toggle.extension);
    await mgr.setServiceExtensionState(
      toggle.extension,
      enabled: true,
      value: toggle.enabledValue,
    );
    await _setInspectorSelectionOnTapEnabled(true);
  }

  Future<void> _setInspectorSelectionOnTapEnabled(bool enabled) async {
    final connected = serviceManager.connectedState.value.connected;
    final svc = serviceManager.service;
    if (!connected || svc == null) return;
    if (serviceManager.connectedApp?.isDartWebAppNow == true) {
      return;
    }
    try {
      await serviceManager.onServiceAvailable;
      _widgetsEval ??= EvalOnDartLibrary(
        'package:flutter/widgets.dart',
        svc,
        serviceManager: serviceManager,
      );
      await _widgetsEval!.eval(
        'WidgetsBinding.instance.debugWidgetInspectorSelectionOnTapEnabled.value = $enabled',
        isAlive: _evalDisposable,
        shouldLogError: false,
      );
    } catch (_) {}
  }

  Future<void> _onHoverChanged(AccessibilityHit? hit) async {
    setState(() {
      _hovered = hit;
      _hoverPropsText = null;
    });
    if (hit == null) return;

    if (hit.valueId == null) {
      if (mounted) {
        setState(
          () => _hoverPropsText =
              'No valueId for this widget. Rescan after navigation changes, '
              'or run a debug or profile build. Release builds may omit inspector refs.',
        );
      }
      return;
    }

    Future<void> fetchProps() async {
      try {
        final props = await _bridge.getProperties(hit.valueId);
        final text = formatPropertiesForTooltip(props);
        if (mounted && _hovered == hit) {
          setState(() => _hoverPropsText = text);
        }
      } catch (_) {
        if (mounted && _hovered == hit) {
          setState(() => _hoverPropsText = 'Could not load properties.');
        }
      }
    }

    Future<void> highlightOnDevice() async {
      try {
        await _ensureInspectorOverlay();
        if (mounted && _hovered == hit) {
          await _bridge.setSelectionById(hit.valueId);
        }
      } catch (_) {}
    }

    await Future.wait([fetchProps(), highlightOnDevice()]);
  }

  @override
  Widget build(BuildContext context) {
    final connected = serviceManager.connectedState.value.connected;
    final visibleHits = _visibleHits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Tooltip(
                  message: _listFilter.tooltip,
                  child: SegmentedButton<HitListFilter>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment<HitListFilter>(
                        value: HitListFilter.all,
                        label: Text(HitListFilter.all.shortLabel),
                        icon: const Icon(Icons.view_list, size: 16),
                      ),
                      ButtonSegment<HitListFilter>(
                        value: HitListFilter.foundOnly,
                        label: Text(HitListFilter.foundOnly.shortLabel),
                        icon: const Icon(Icons.accessibility_new, size: 16),
                      ),
                      ButtonSegment<HitListFilter>(
                        value: HitListFilter.hintsOnly,
                        label: Text(HitListFilter.hintsOnly.shortLabel),
                        icon: const Icon(Icons.lightbulb_outline, size: 16),
                      ),
                      ButtonSegment<HitListFilter>(
                        value: HitListFilter.warningsOnly,
                        label: Text(HitListFilter.warningsOnly.shortLabel),
                        icon: const Icon(Icons.warning_amber_rounded, size: 16),
                      ),
                    ],
                    selected: <HitListFilter>{_listFilter},
                    onSelectionChanged: (Set<HitListFilter> next) {
                      if (next.isEmpty) return;
                      _setListFilter(next.first);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Fetch the widget tree (app project widgets, hints and warnings on). '
                  'Hover a row for inspector properties and device highlight.',
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                onPressed: !connected || _busy ? null : _refresh,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(_busy ? '…' : 'Scan'),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Matches: ${_hits.length} total (semantics: ${_hits.where((h) => h.hasSemanticsInterest).length}, '
          'focus: ${_hits.where((h) => h.hasFocusInterest).length}, '
          'hints: ${_hits.where((h) => h.isSemanticSuggestion).length}, '
          'warnings: ${_hits.where((h) => h.hasSemanticWarnings).length}) · '
          'Showing ${visibleHits.length} with filter',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double rowWidth = constraints.maxWidth;
              final double innerWidth = (rowWidth - _kPanelSplitterWidth).clamp(
                0.0,
                double.infinity,
              );
              final double listWidth = innerWidth * _listPanelFraction;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: listWidth,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: _hits.isEmpty
                          ? Center(
                              child: Text(
                                connected
                                    ? 'Tap Scan to search for semantics & focus widgets.'
                                    : 'Waiting for VM service…',
                              ),
                            )
                          : visibleHits.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Nothing matches this filter (${_listFilter.shortLabel}). '
                                  'Try All, turn on Hints before scanning, or rescan.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: visibleHits.length,
                              itemBuilder: (context, i) {
                                final h = visibleHits[i];
                                return HitTile(
                                  hit: h,
                                  selected: _hovered == h,
                                  onHover: (enter) {
                                    if (enter) {
                                      _onHoverChanged(h);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  Tooltip(
                    message: 'Drag to resize list and properties',
                    waitDuration: const Duration(milliseconds: 400),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: Semantics(
                        label: 'Resize list and properties panels',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (DragUpdateDetails details) {
                            if (innerWidth <= 0) {
                              return;
                            }
                            setState(() {
                              _listPanelFraction =
                                  (_listPanelFraction +
                                          details.delta.dx / innerWidth)
                                      .clamp(
                                        _kMinListPanelFraction,
                                        _kMaxListPanelFraction,
                                      );
                            });
                          },
                          child: SizedBox(
                            width: _kPanelSplitterWidth,
                            child: Center(
                              child: Container(
                                width: 1,
                                color:
                                    Theme.of(context).dividerTheme.color
                                        ?.withValues(alpha: 0.85) ??
                                    Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _hovered == null
                            ? Center(
                                child: Text(
                                  'Hover a row for inspector properties.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hovered!.widgetRuntimeType,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    if (_hovered!.hasSemanticWarnings) ...[
                                      const SizedBox(height: 10),
                                      Material(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .errorContainer
                                            .withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onErrorContainer,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Semantic warnings',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .onErrorContainer,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              for (
                                                var i = 0;
                                                i <
                                                    _hovered!
                                                        .semanticWarnings!
                                                        .length;
                                                i++
                                              ) ...[
                                                if (i > 0)
                                                  const SizedBox(height: 10),
                                                Text(
                                                  _hovered!
                                                      .semanticWarnings![i]
                                                      .shortLabel,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onErrorContainer,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                SelectableText(
                                                  _hovered!
                                                      .semanticWarnings![i]
                                                      .message,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onErrorContainer,
                                                        height: 1.35,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_hovered!.isSemanticSuggestion) ...[
                                      const SizedBox(height: 10),
                                      Material(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              WcagHintHeader(
                                                hints:
                                                    _hovered!.semanticGapHints!,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Where to add semantics',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onTertiaryContainer,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              SemanticHintMessageBody(
                                                fullText: _hovered!
                                                    .semanticSuggestion!,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_hovered!.sourceLocationLabel !=
                                        null) ...[
                                      const SizedBox(height: 6),
                                      Tooltip(
                                        message:
                                            _hovered!.sourceFileUri ??
                                            _hovered!.sourceLocationLabel!,
                                        child: SelectableText(
                                          _hovered!.sourceLocationLabel!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontFamily: 'monospace',
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SelectableText(_hovered!.description),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Inspector properties',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    if (_hovered!.isSemanticSuggestion) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tip: use the inspector property list below for semanticLabel and other fields.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      _hoverPropsText ?? 'Loading…',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            height: 1.4,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

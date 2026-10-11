enum DockState { collapsed, expanded }

class FloatingDockController {
  DockState _state = DockState.collapsed;

  DockState get state => _state;

  /// Hovering expands after 150 ms; leaving collapses after 400 ms.
  DockState decide({
    required bool hovered,
    required Duration hoverDuration,
  }) {
    if (hovered && hoverDuration > const Duration(milliseconds: 150)) {
      _state = DockState.expanded;
    } else if (!hovered && hoverDuration > const Duration(milliseconds: 400)) {
      _state = DockState.collapsed;
    }
    return _state;
  }
}

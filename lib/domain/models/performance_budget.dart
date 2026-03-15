/// Static performance guardrails for room content and effects.
///
/// These constants define the maximum allowable counts for various
/// resource-intensive features per room/era. They serve as authoring
/// guidelines: if generated or hand-authored content exceeds these
/// budgets the room may become laggy or unresponsive.
///
/// The budgets are enforced by validation helpers in this file rather
/// than at parse time so the game still loads gracefully, but the
/// helpers can be used in debug builds or tests to catch regressions.
class PerformanceBudget {
  const PerformanceBudget._();

  // ── Tree / node budgets ────────────────────────────────────────────────

  /// Maximum number of upgrade nodes (excluding the generator node and
  /// secrets) that should be placed in a single era's tech tree.
  /// The current generator produces 200 upgrades/era (10 branches × 20
  /// tiers). Keeping the limit at 210 leaves headroom for future extras.
  static const int maxUpgradeNodesPerEra = 210;

  /// Maximum number of secret nodes shown in a single tree view.
  /// Too many secrets increase node-culling overhead and clutter the tree.
  static const int maxSecretNodesPerEra = 5;

  /// Maximum number of connections drawn by the ConnectionPainter.
  /// Each additional connection is an extra cubic Bezier on the canvas.
  static const int maxConnectionsPerEra = 230;

  // ── Event / overlay budgets ────────────────────────────────────────────

  /// Maximum number of events in a single era's event pool.
  /// The current authoring standard is 11 (8 common + 2 rare + 1 legendary).
  static const int maxEventsPerEra = 12;

  /// Maximum number of simultaneously active overlay effects (transition
  /// flashes, milestone banners, narrative beat cards, gain toasts, etc.).
  /// Exceeding this causes layout thrash and frame-rate drops.
  static const int maxSimultaneousOverlays = 4;

  /// Maximum number of gain toasts queued at any time.
  static const int maxGainToasts = 6;

  // ── Audio budgets ──────────────────────────────────────────────────────

  /// Maximum number of simultaneously playing ambient audio layers per room.
  /// More layers increase mixing cost and can cause audio hitching.
  static const int maxAmbientAudioLayers = 3;

  // ── Animation / VFX budgets ───────────────────────────────────────────

  /// Maximum number of transformation-stage particle or visual effects
  /// active at the same time (e.g. room transformation animations).
  static const int maxTransformationParticles = 8;

  /// Maximum number of ambient animated props in a single backdrop scene.
  static const int maxAmbientAnimatedProps = 6;

  // ── Viewport culling ──────────────────────────────────────────────────

  /// Additional margin (in world-space pixels) added around the visible
  /// viewport when deciding which nodes to build. Prevents node pop-in
  /// during rapid panning.
  static const double nodeViewportCullMargin = 280.0;

  // ── Validation helpers ────────────────────────────────────────────────

  /// Returns true if [nodeCount] is within the allowed limit.
  static bool upgradeNodeCountOk(int nodeCount) =>
      nodeCount <= maxUpgradeNodesPerEra;

  /// Returns true if [secretCount] is within the allowed limit.
  static bool secretNodeCountOk(int secretCount) =>
      secretCount <= maxSecretNodesPerEra;

  /// Returns true if [connectionCount] is within the allowed limit.
  static bool connectionCountOk(int connectionCount) =>
      connectionCount <= maxConnectionsPerEra;

  /// Returns true if [eventCount] is within the allowed limit.
  static bool eventPoolSizeOk(int eventCount) =>
      eventCount <= maxEventsPerEra;

  /// Returns true if [overlayCount] is within the allowed limit.
  static bool overlayCountOk(int overlayCount) =>
      overlayCount <= maxSimultaneousOverlays;

  /// Returns true if [layerCount] is within the allowed audio limit.
  static bool ambientAudioLayerCountOk(int layerCount) =>
      layerCount <= maxAmbientAudioLayers;
}

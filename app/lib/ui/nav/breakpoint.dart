/// Breakpoints Material 3 (SPEC §9) — celular/tablet/desktop como alvos de
/// UX de primeira classe, não fallback um do outro.
enum AppBreakpoint { compact, medium, expanded }

AppBreakpoint breakpointForWidth(double width) {
  if (width < 600) return AppBreakpoint.compact;
  if (width < 840) return AppBreakpoint.medium;
  return AppBreakpoint.expanded;
}

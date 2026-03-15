# UX Design Pitfalls

Common UX mistakes when building features. These are design-level issues — for code-level UI bugs, see `ui-implementation.md`.

## Hover-Only Affordances

**Problem:** Interactive elements only reveal themselves on hover (e.g., action buttons, edit icons). Touch devices and keyboard users never discover them.

**Why it happens:** Developers test exclusively with a mouse and mistake hover states for progressive disclosure.

**Fix:** Make all interactive elements visible by default. Use hover to *enhance* (e.g., highlight), not to *reveal*. If space is constrained, use a persistent overflow menu icon instead of hidden actions.

## Missing Loading, Empty, and Error States

**Problem:** A feature works for the happy path but shows a blank screen when data is loading, empty, or when the request fails. Users see a flash of nothing or assume the app is broken.

**Why it happens:** Developers work with pre-seeded data and fast local networks. The empty/error paths never appear during development.

**Fix:** Design all three states before building:
- **Loading:** Skeleton screen or spinner (prefer skeletons for content areas)
- **Empty:** Explanatory message with a call to action ("No results yet. Create your first item.")
- **Error:** Describe what failed and offer a retry action

## Unclear Clickable Areas

**Problem:** Users don't realize an element is interactive. Text links without underlines, icon-only buttons without labels, cards that are clickable but look static.

**Why it happens:** Minimal design trends strip away affordance cues. The developer knows it's clickable because they built it.

**Fix:** Ensure clickable elements have at least two affordance signals: color change, underline, cursor pointer, border/shadow, or hover effect. For icon-only buttons, add a tooltip at minimum.

## Cognitive Overload

**Problem:** A page presents too many options, settings, or data points at once. Users freeze or miss important actions.

**Why it happens:** Features accumulate over time. Each individual addition seems small, but the aggregate overwhelms.

**Fix:** Apply progressive disclosure. Show the primary action and 2-3 most common options. Move advanced settings behind an expandable section or secondary page. Audit pages periodically for option count — more than 7 visible actions is a red flag.

## Hidden Critical Actions

**Problem:** Destructive or important actions (delete, export, submit) are buried in submenus, overflow menus, or require multiple clicks to reach.

**Why it happens:** Placing dangerous actions in hard-to-reach locations feels like a safety measure, but it frustrates power users without actually preventing mistakes.

**Fix:** Keep critical actions visible but protected. Use inline confirmation ("Are you sure?") or undo patterns instead of hiding. The prominence of an action should match its frequency of use, not its danger level.

## Color-Only Information

**Problem:** Status indicators, form validation, or data categories are communicated only through color. Users with color vision deficiency miss the information entirely.

**Why it happens:** Color is the easiest visual differentiator to implement.

**Fix:** Always pair color with a second signal: icon, label, pattern, or position. For form validation, show an error icon and text message alongside the red border.

```html
<!-- WRONG - color only -->
<input style="border-color: red" />

<!-- CORRECT - color + icon + message -->
<input style="border-color: red" aria-invalid="true" />
<span role="alert">Email is required</span>
```

## Missing Keyboard Navigation

**Problem:** Custom components (dropdowns, modals, tabs) are not keyboard-accessible. Focus gets trapped or lost entirely.

**Why it happens:** Native HTML elements handle keyboard behavior for free. Custom components need explicit focus management that developers skip.

**Fix:** Use native semantic elements where possible (`<button>`, `<select>`, `<dialog>`). For custom components, implement arrow key navigation, Escape to close, and Tab to move between groups. Test every feature by navigating with Tab and Enter only.

## ARIA Overuse

**Problem:** Adding excessive ARIA attributes that duplicate native semantics or conflict with each other. Screen readers announce elements incorrectly or redundantly.

**Why it happens:** Developers add ARIA "just in case" without understanding that incorrect ARIA is worse than no ARIA.

**Fix:** First rule of ARIA: don't use ARIA if a native HTML element provides the semantics. A `<button>` does not need `role="button"`. Only add ARIA when no native element fits. Test with an actual screen reader.

```html
<!-- WRONG - redundant and noisy -->
<button role="button" aria-label="Submit button">Submit</button>

<!-- CORRECT - native semantics are sufficient -->
<button>Submit</button>
```

## Silent Failures

**Problem:** An action fails (save, delete, upload) but the UI shows no feedback. The user assumes it worked.

**Why it happens:** Error handling is added to the API call but the UI layer swallows the error — the catch block logs to console but never updates the UI.

**Fix:** Every user-initiated action must produce visible feedback: success toast, error message, or state change. If the operation is async, show a progress indicator. Never rely on console.log as user feedback.

## No Undo for Destructive Actions

**Problem:** Clicking "Delete" immediately and permanently removes data. There is no confirmation, no undo, and no recovery path.

**Why it happens:** Implementing soft-delete or undo is seen as extra work that can be added later. It never gets added.

**Fix:** Choose one: (1) confirmation dialog before destructive actions, (2) soft-delete with an undo toast (preferred — faster workflow, fewer interrupts), or (3) a trash/archive that retains items for a recovery period. Never silently destroy data on a single click.

## Form Validation Timing

**Problem:** Validation fires on every keystroke (annoying while typing) or only on submit (user fills out a long form, then gets a wall of errors).

**Why it happens:** The default behavior of most form libraries is either onChange or onSubmit, and developers don't customize it.

**Fix:** Validate on blur (when the user leaves a field) for the first error. After the first error is shown, switch to onChange for that field so the user sees their fix take effect immediately. This is the "validate on blur, re-validate on change" pattern.

## Touch Target Sizes

**Problem:** Buttons and links are too small for touch interaction. Users on mobile tap the wrong element or cannot tap at all.

**Why it happens:** Designs are created and tested on desktop where a mouse cursor provides pixel-level precision.

**Fix:** Minimum touch target: 44x44px (Apple HIG) or 48x48dp (Material). Even if the visible element is smaller, extend the tappable area with padding. Ensure at least 8px spacing between adjacent touch targets.

## Optimistic Updates vs. Spinners

**Problem:** Every action shows a loading spinner, making the UI feel sluggish even when the backend responds in 200ms.

**Why it happens:** Developers default to "show spinner, wait for response, update UI" because it is the simplest correct pattern.

**Fix:** For low-risk, easily reversible actions (toggling a favorite, marking as read, reordering a list), apply the change to the UI immediately and sync in the background. Revert on failure with an error message. Reserve spinners for high-stakes operations (payments, data exports) where the user must wait for confirmation.

## Inconsistent Navigation Patterns

**Problem:** Some pages use breadcrumbs, others use back buttons, others have neither. Users lose spatial orientation.

**Why it happens:** Different developers build different pages without a shared navigation convention.

**Fix:** Establish a navigation pattern early and document it. At minimum: (1) a persistent global nav showing the current section, (2) a consistent back/breadcrumb pattern for drill-down pages, and (3) the browser back button must always work (avoid replacing history entries silently).

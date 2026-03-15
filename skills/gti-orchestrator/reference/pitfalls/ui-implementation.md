# UI Implementation Pitfalls

Code-level mistakes when building UI features. For design-level issues, see `ux-design.md`.

## God Components

**Problem:** A single component handles fetching data, managing state, rendering UI, and handling user events. It grows to 300+ lines and becomes untestable.

**Why it happens:** It starts small and grows incrementally. Extracting sub-components feels like premature abstraction.

**Fix:** Split by responsibility: a container component handles data/state, presentational components handle rendering. Extract when a component exceeds ~150 lines or when you find yourself scrolling to understand the render output.

## Key Prop Misuse

**Problem:** Using array index as key, or an unstable key, causes React (or similar frameworks) to reuse the wrong component instance. Form inputs retain stale values, animations glitch, or state leaks between list items.

**Why it happens:** `key={index}` silences the console warning and appears to work in simple cases.

**Fix:** Use a stable, unique identifier from the data. If no ID exists, generate one when the data is created — not during render.

```tsx
// WRONG - index key causes state bugs on reorder/delete
{items.map((item, i) => <ItemRow key={i} item={item} />)}

// CORRECT - stable unique ID
{items.map(item => <ItemRow key={item.id} item={item} />)}
```

## Controlled vs. Uncontrolled Input Confusion

**Problem:** Switching an input between controlled (`value={state}`) and uncontrolled (`defaultValue`) during its lifecycle causes warnings and broken behavior. Common when initializing with undefined then setting a value.

**Why it happens:** The initial state is undefined before data loads, making the input uncontrolled. When data arrives and state populates, it switches to controlled.

**Fix:** Always initialize form state to empty strings (not undefined) for controlled inputs. Or use `defaultValue` and refs for truly uncontrolled forms.

```tsx
// WRONG - starts uncontrolled, switches to controlled
const [name, setName] = useState(); // undefined initially

// CORRECT - always controlled
const [name, setName] = useState('');
```

## Z-Index Wars

**Problem:** Components compete with escalating z-index values (100, 999, 9999, 99999). New features break old overlays. Dropdowns appear behind modals.

**Why it happens:** Each developer picks a "high enough" number without a system. Stacking contexts are poorly understood.

**Fix:** Define a z-index scale with named layers:

```css
:root {
  --z-dropdown: 100;
  --z-sticky: 200;
  --z-modal-backdrop: 300;
  --z-modal: 400;
  --z-toast: 500;
  --z-tooltip: 600;
}
```

Use only these values. If something overlaps incorrectly, fix the stacking context (often caused by `transform`, `opacity`, or `will-change` creating new contexts) rather than increasing the number.

## Derived State Duplication

**Problem:** A value that can be computed from existing state is stored as separate state. The two get out of sync, causing subtle display bugs.

**Why it happens:** Computing a value in render feels "wrong" or "expensive," so the developer caches it in state.

**Fix:** Derive the value during render (or use a memoization hook for expensive computations). If `fullName` can be computed from `firstName + lastName`, do not store `fullName` in state.

```tsx
// WRONG - derived state stored separately
const [items, setItems] = useState([]);
const [itemCount, setItemCount] = useState(0); // out of sync risk

// CORRECT - derive from source of truth
const [items, setItems] = useState([]);
const itemCount = items.length;
```

## State That Should Be URL Params

**Problem:** Filter selections, search queries, pagination, and tab selections are stored in component state. Refreshing the page loses the user's context. URLs cannot be shared or bookmarked.

**Why it happens:** Component state is the path of least resistance. URL sync requires router integration.

**Fix:** If a user would reasonably want to bookmark, share, or return to a specific view, that state belongs in the URL. Use search params for filters/pagination, path segments for resource identity.

## Re-Render Cascades

**Problem:** A state change at the top of the tree re-renders every child, even those that don't use the changed value.

**Why it happens:** State is placed too high in the tree or a single context provides many unrelated values.

**Fix:** Push state down to the lowest component that needs it. Split large contexts into focused ones. Use memoization as a last resort after restructuring.

## Animating Expensive Properties

**Problem:** Animating `width`, `height`, `top`, `left`, or `margin` triggers layout recalculation on every frame. The animation stutters at 15-30fps instead of 60fps.

**Why it happens:** These properties feel like the natural way to move/resize elements.

**Fix:** Animate only `transform` and `opacity` — these run on the compositor thread and skip layout/paint. Use `transform: translateX()` instead of `left`, `transform: scale()` instead of `width`.

```css
/* WRONG - triggers layout every frame */
.slide-in { animation: slide 300ms; }
@keyframes slide { from { left: -100%; } to { left: 0; } }

/* CORRECT - compositor only */
.slide-in { animation: slide 300ms; }
@keyframes slide { from { transform: translateX(-100%); } to { transform: translateX(0); } }
```

## Missing Reduced Motion Support

**Problem:** Users who have enabled "prefers-reduced-motion" in their OS settings still see full animations, causing discomfort or accessibility issues.

**Why it happens:** Developers don't test with this setting enabled and forget to add the media query.

**Fix:** Wrap non-essential animations in a reduced-motion media query:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Hardcoded Colors in Dark Mode

**Problem:** Switching to dark mode reveals text that's invisible (dark on dark), borders that vanish, or shadows that look like glowing rectangles.

**Why it happens:** Colors are set as hex values in component styles rather than referencing theme tokens. Dark mode is added after initial development.

**Fix:** Use CSS custom properties (or theme tokens) for all colors from the start. Never hardcode color values in component CSS. Audit both modes by toggling the theme and checking every page.

```css
/* WRONG - hardcoded, breaks in dark mode */
.card { background: #ffffff; color: #333333; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }

/* CORRECT - theme-aware */
.card { background: var(--surface); color: var(--text-primary); box-shadow: var(--shadow-sm); }
```

## Testing Implementation Instead of Behavior

**Problem:** Tests assert on CSS classes, internal state, or implementation details (snapshot tests on full component trees are the worst offender). They break on every trivial refactor while missing actual behavior bugs.

**Why it happens:** It's easier to assert `expect(wrapper.state('isOpen')).toBe(true)` than to verify what the user actually sees. Snapshot tests feel comprehensive but capture noise.

**Fix:** Query by role, text, or test ID. Assert on visible output and user-observable behavior. Avoid full-component snapshots — if you must snapshot, snapshot a small stable portion.

```tsx
// WRONG - tests implementation
expect(component.state('isModalOpen')).toBe(true);

// CORRECT - tests behavior
await user.click(screen.getByRole('button', { name: 'Settings' }));
expect(screen.getByRole('dialog')).toBeVisible();
```

## Missing Icon Accessibility

**Problem:** Icon-only buttons have no accessible label. Screen readers announce "button" with no description of what the button does.

**Why it happens:** The icon is "obviously" a trash can or a pencil — to sighted users. The developer forgets that icons carry no semantic meaning.

**Fix:** Add `aria-label` to icon-only buttons. For decorative icons next to text, use `aria-hidden="true"` on the icon.

```html
<!-- WRONG -->  <button><svg>...</svg></button>
<!-- CORRECT --> <button aria-label="Delete item"><svg aria-hidden="true">...</svg></button>
```

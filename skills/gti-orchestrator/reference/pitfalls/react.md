# React Pitfalls

Common issues when using React in GTI-managed projects.

## WebSocket Handler Dependencies

**Problem:** Putting state in useCallback dependencies for WebSocket handlers causes reconnection loops.

**Solution:** Use refs for state access in stable callbacks:

```typescript
// WRONG - reconnects on every message
const handleMessage = useCallback(() => {
  setMessages([...messages, msg]);
}, [messages]); // messages changes -> callback recreates -> effect reruns

// CORRECT - use refs
const messagesRef = useRef(messages);
useEffect(() => { messagesRef.current = messages }, [messages]);
const handleMessage = useCallback(() => {
  setMessages([...messagesRef.current, msg]);
}, []); // stable callback
```

**Why it matters:** Creates infinite reconnection loops that degrade performance and may cause rate limiting.

## State Array Null Safety

**Problem:** Operating on potentially undefined state arrays crashes the component.

**Solution:** Always initialize and check state arrays before operations:

```typescript
// WRONG
state.notes.map(...) // crashes if notes is undefined

// CORRECT - defensive programming
(state.notes || []).map(...)

// OR initialize in store definition
const initialState = {
  notes: [], // Always initialized
};
```

## Infinite Loop in useEffect

**Problem:** State management bugs can cause infinite loops that pass tests but crash immediately in production.

**Solution:** Check if update is actually needed:

```typescript
// WRONG - can cause infinite updates
useEffect(() => {
  setItems(fetchData());
}, [items]); // items changes -> effect runs -> setItems -> items changes

// CORRECT - check if update is needed
useEffect(() => {
  const data = fetchData();
  if (!isEqual(data, items)) {
    setItems(data);
  }
}, [dependency]);
```

## Stale Closure in Event Handlers

**Problem:** Event handlers capture stale state from when they were created.

**Solution:** Use functional updates or refs:

```typescript
// WRONG - captures stale count
const increment = () => setCount(count + 1);

// CORRECT - functional update
const increment = () => setCount(prev => prev + 1);

// OR use ref for complex state
const stateRef = useRef(complexState);
useEffect(() => { stateRef.current = complexState }, [complexState]);
```

## Authenticated Downloads

**Problem:** `window.open()` doesn't include JWT tokens for authenticated downloads.

**Solution:** Use fetch + blob pattern:

```typescript
// WRONG - no auth headers
window.open(getDownloadUrl(id));

// CORRECT - includes auth
const response = await fetch(url, {
  headers: { Authorization: `Bearer ${token}` }
});
const blob = await response.blob();
const blobUrl = URL.createObjectURL(blob);
const link = document.createElement('a');
link.href = blobUrl;
link.download = filename;
link.click();
URL.revokeObjectURL(blobUrl);
```

## Memory Leaks in useEffect

**Problem:** Async operations completing after component unmount cause state updates on unmounted components.

**Solution:** Use cleanup function or AbortController:

```typescript
useEffect(() => {
  let isMounted = true;

  fetchData().then(data => {
    if (isMounted) setData(data);
  });

  return () => { isMounted = false };
}, []);

// OR with AbortController
useEffect(() => {
  const controller = new AbortController();

  fetch(url, { signal: controller.signal })
    .then(res => res.json())
    .then(setData)
    .catch(err => {
      if (err.name !== 'AbortError') throw err;
    });

  return () => controller.abort();
}, [url]);
```

## Context Provider Placement

**Problem:** Components outside provider tree cannot access context.

**Solution:** Ensure providers wrap all consuming components, typically at app root.

# Express.js Pitfalls

Common issues when using Express.js in AIDA-managed projects.

## Query Parameter Type Ambiguity

**Problem:** Express can return query params as string OR array depending on the request.

**Solution:** Always handle both cases:

```typescript
// WRONG - assumes string
const type = req.query.type as string;

// CORRECT - handle both
const type = Array.isArray(req.query.type)
  ? req.query.type[0]
  : req.query.type;
```

**Why it matters:** `?type=foo&type=bar` will return an array, causing string operations to fail.

## Response Wrapper Inconsistency

**Problem:** Different endpoints may use different response wrappers, leading to frontend confusion.

**Solution:** Standardize on a consistent response format:

```typescript
// Standardize across all endpoints
interface ApiResponse<T> {
  success: boolean;
  data: T;
  error?: string;
}

// For paginated responses
interface PaginatedResponse<T> {
  data: T[];
  meta: {
    page: number;
    limit: number;
    total: number;
  };
}
```

**Why it matters:** Frontend code expecting `.data` fails when endpoint returns different structure.

## Error Handler Middleware Order

**Problem:** Express middleware order matters - error handlers must come last.

**Solution:** Register error handling middleware after all routes:

```typescript
// Routes first
app.use('/api', routes);

// Error handler LAST
app.use((err, req, res, next) => {
  res.status(err.status || 500).json({ error: err.message });
});
```

## HTTP Status Code Semantics

**Problem:** Using 500 for all errors, including "not found" scenarios.

**Solution:** Use appropriate status codes:

```typescript
// WRONG - returns 500 for missing resource
const doc = await db.get(id); // throws generic error

// CORRECT - explicit 404
const doc = await db.get(id);
if (!doc) {
  return res.status(404).json({ error: `Resource ${id} not found` });
}
```

- **404**: Resource doesn't exist
- **400**: Bad request / validation error
- **401**: Not authenticated
- **403**: Not authorized
- **500**: Actual server error

## Body Parser Limits

**Problem:** Default body size limits may reject large uploads or JSON payloads.

**Solution:** Configure appropriate limits per route:

```typescript
// Global default
app.use(express.json({ limit: '1mb' }));

// Per-route override for file uploads
app.post('/upload', express.json({ limit: '50mb' }), uploadHandler);
```

## Async Error Handling

**Problem:** Async route handlers don't automatically catch errors in Express 4.x.

**Solution:** Wrap async handlers or use express-async-errors:

```typescript
// Manual wrapper
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

app.get('/api/data', asyncHandler(async (req, res) => {
  const data = await fetchData();
  res.json(data);
}));
```

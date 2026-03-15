# ArangoDB Pitfalls

Common issues when using ArangoDB in GTI-managed projects.

## Document Key to ID Mapping

**Problem:** ArangoDB returns documents with `_key` field, but frontend code typically expects `id`.

**Solution:** Always transform in the API layer or store:

```typescript
// In frontend API or store
const mapped = response.data.map(item => ({
  ...item,
  id: item._key || item.id
}));
```

**Why it matters:** Missing this mapping causes undefined ID errors throughout the frontend, breaking edit/delete operations.

## AQL Bind Parameters in Strings

**Problem:** Bind parameters don't work inside string literals in AQL queries.

**Solution:** Use CONCAT to build document references:

```aql
// WRONG - @noteId is literal text inside string
DOCUMENT("notes/@noteId")

// CORRECT - use CONCAT
DOCUMENT(CONCAT("notes/", @noteId))
```

**Why it matters:** The query will silently fail to find the document, returning null instead of the expected data.

## Collection Name Assumptions

**Problem:** ArangoDB document handles include the collection name prefix (`collection/key`), which may need stripping.

**Solution:** Be consistent about where you strip collection prefixes:

```typescript
// If API returns full handle: "notes/12345"
const id = handle.split('/')[1]; // Extract just the key

// Or configure backend to return only _key
```

## Graph Traversal Edge Cases

**Problem:** Graph traversals can return unexpected results when edges are missing or orphan nodes exist.

**Solution:** Always validate traversal results and handle empty paths:

```aql
// Handle potential empty results
FOR v, e, p IN 1..3 OUTBOUND @startNode GRAPH 'myGraph'
  FILTER v != null
  RETURN v
```

## Transaction Isolation

**Problem:** ArangoDB single-server mode has different transaction guarantees than cluster mode.

**Solution:** Design with eventual consistency in mind, especially for cross-collection operations.

---
name: search-filter-skill
description: Use when implementing search functionality, filters (price, category, rating, technique), autocomplete suggestions, sorting options, and design discovery features for the Shree Krishna marketplace.
argument-hint: [feature type: search, filter, or discovery]
disable-model-invocation: true
---

## What This Skill Does

Generates complete search and filtering system for Shree Krishna marketplace with full-text search, advanced filters, autocomplete, sorting, and efficient Firestore querying.

**Features:**
- ✅ Full-text search on design titles & descriptions
- ✅ Filter by price, category, rating, technique
- ✅ Autocomplete search suggestions
- ✅ Sorting (newest, popular, price, rating)
- ✅ Advanced filter combinations
- ✅ Search history & saved searches
- ✅ Real-time filter updates
- ✅ Efficient Firestore queries
- ✅ Pagination for large result sets
- ✅ No-results suggestions

## Workflow Highlights

### 1. Search Strategy
- **Firestore text search:** Use `where` clause on indexed fields
- **Complex queries:** Composite indexes for combined filters
- **Performance:** Limit results, use pagination

### 2. Firestore Indexes

Required indexes:
- `category + createdAt`
- `technique + createdAt`
- `rating + createdAt`
- `price + createdAt`
- `isActive + createdAt`

### 3. Search Service

**Path:** `lib/domain/repositories/search_repository.dart`

Functions:
- `searchDesigns(query, filters)`
- `filterByPrice(minPrice, maxPrice)`
- `filterByCategory(categories)`
- `filterByRating(minRating)`
- `filterByTechnique(techniques)`
- `sortResults(sortBy)`
- `getSearchSuggestions(query)`
- `getSearchHistory(userId)`
- `saveSearch(userId, query)`

### 4. Filter Models

```dart
class SearchFilter {
  String? query;
  double? minPrice;
  double? maxPrice;
  List<String>? categories;
  double? minRating;
  List<String>? techniques;
  String sortBy; // newest, popular, price_asc, price_desc, rating
}
```

### 5. Generate Search BLoC

**Path:** `lib/bloc/search/search_bloc.dart`

Events:
- `SearchEvent(query)`
- `FilterEvent(filters)`
- `SortEvent(sortBy)`
- `LoadMoreEvent()`
- `ClearFiltersEvent()`
- `SaveSearchEvent(query)`

States:
- `SearchInitial`
- `SearchLoading`
- `SearchLoaded(results)`
- `SearchEmpty`
- `SearchError(message)`
- `FiltersUpdated(results)`

### 6. Generate Search UI

**Screens:**
- `lib/screens/search/search_screen.dart`
- `lib/screens/search/filter_drawer_screen.dart`
- `lib/screens/search/results_screen.dart`

**Features:**
- Search bar with autocomplete
- Filter drawer (expandable, chip selection)
- Sort dropdown
- Results grid with pagination
- "No results found" with suggestions
- Search history

### 7. Autocomplete Implementation

**Path:** `lib/domain/usecases/search_suggestions_usecase.dart`

- Get top search queries from Firestore
- Get trending designs
- Get category suggestions
- Real-time as user types

### 8. Performance Optimization

- Use virtual scrolling for large lists
- Cache search results in BLoC
- Limit queries to 20-50 results per page
- Debounce search input (300ms)
- Use Firestore snapshots for real-time updates

### 9. Security

- Sanitize search queries
- Only search on public/published designs
- Check user permissions
- Rate limit search requests (prevent abuse)

---

**Phase 1 MVP:** Search + basic filters (price, category)  
**Phase 2+:** Advanced filters, autocomplete, saved searches

---

**Ready! Implement search for your marketplace.**

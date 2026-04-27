---
name: performance-optimization-skill
description: Use when optimizing Flutter app performance: BLoC caching, Firestore queries, lazy loading, virtual scrolling, bundle size, memory management, network efficiency, and profiling bottlenecks.
argument-hint: [optimization type: caching, queries, rendering, or bundle]
disable-model-invocation: true
---

## What This Skill Does

Generates complete performance optimization: BLoC/Hive caching, Firestore query optimization, image compression, lazy loading, virtual scrolling, memory leak fixes, bundle size reduction, and DevTools profiling.

**Features:**
- ✅ BLoC caching (avoid redundant API calls)
- ✅ Firestore query optimization (indexes, limits, pagination)
- ✅ Lazy loading & pagination
- ✅ Virtual scrolling (large lists)
- ✅ Image optimization & caching
- ✅ Memory leak detection
- ✅ Bundle size reduction
- ✅ Network efficiency (compression, offline)
- ✅ Profiling with DevTools
- ✅ Performance monitoring

## Performance Checklist

```
Before Optimization:
- [ ] Identify bottlenecks (use DevTools)
- [ ] Measure baseline performance
- [ ] Check Firestore read/write costs
- [ ] Profile memory usage
- [ ] Check bundle size

Optimization:
- [ ] Add BLoC caching for frequently used data
- [ ] Optimize Firestore queries (indexes, limits)
- [ ] Implement lazy loading for lists
- [ ] Compress images
- [ ] Remove unused dependencies
- [ ] Profile again to verify improvements

Monitoring:
- [ ] Set up Firebase Performance Monitoring
- [ ] Track frame rate on devices
- [ ] Monitor API response times
```

## Step-by-Step Workflow

### 1. Identify Performance Bottlenecks with DevTools

**Run Flutter DevTools:**
```bash
flutter pub global activate devtools
flutter pub global run devtools

# Then in your app:
flutter run --profile
# Open DevTools URL in browser
```

**Key metrics to check:**
- **Frame rate:** Should be 60+ FPS (mobile), 120+ (web)
- **CPU usage:** Should be < 50% at rest
- **Memory:** Should not grow over time (check for leaks)
- **Janky frames:** Should be < 5%

### 2. BLoC Caching (Avoid Redundant API Calls)

**Problem:** Every widget rebuild triggers a new API call.

**Solution: Cache in BLoC state**

```dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProduct;
  
  // Cache products in memory
  final Map<String, ProductModel> _productCache = {};
  DateTime? _lastFetch;
  
  ProductBloc(this.getProduct) : super(ProductInitial()) {
    on<GetProductEvent>(_onGetProduct);
  }
  
  Future<void> _onGetProduct(
    GetProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    // Check cache first
    if (_productCache.containsKey(event.productId)) {
      final cached = _productCache[event.productId]!;
      
      // Return cached if fresh (< 5 minutes old)
      if (_lastFetch != null &&
          DateTime.now().difference(_lastFetch!).inMinutes < 5) {
        emit(ProductLoaded(cached));
        return;
      }
    }
    
    emit(ProductLoading());
    
    final result = await getProduct(event.productId);
    
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) {
        // Cache it
        _productCache[event.productId] = product;
        _lastFetch = DateTime.now();
        emit(ProductLoaded(product));
      },
    );
  }
}
```

### 3. Persistent Caching with Hive

**For data that should persist across app sessions:**

```dart
// Model with Hive serialization
@HiveType(typeId: 0)
class ProductModel extends ProductEntity {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final double price;
  
  ProductModel({
    required this.id,
    required this.name,
    required this.price,
  });
}

// Cache repository
class HiveCacheRepository {
  late final Box<ProductModel> _productBox;
  
  Future<void> init() async {
    Hive.registerAdapter(ProductModelAdapter());
    _productBox = await Hive.openBox<ProductModel>('products');
  }
  
  // Save to cache
  Future<void> cacheProduct(ProductModel product) async {
    await _productBox.put(product.id, product);
  }
  
  // Get from cache
  ProductModel? getProduct(String id) {
    return _productBox.get(id);
  }
  
  // Clear old cache (>7 days)
  Future<void> clearOldCache() async {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    final keysToDelete = <String>[];
    
    for (var key in _productBox.keys) {
      final product = _productBox.get(key);
      if (product!.createdAt.isBefore(sevenDaysAgo)) {
        keysToDelete.add(key);
      }
    }
    
    await _productBox.deleteAll(keysToDelete);
  }
}
```

### 4. Firestore Query Optimization

**Problem: Firestore charges per read operation**

**Solution: Use composite indexes and pagination**

**Required indexes (set in Firebase Console):**
```
- category + createdAt
- rating + createdAt
- price + createdAt
- isActive + createdAt
```

**Optimized queries:**
```dart
// ❌ Bad: Gets all documents (costs money!)
final docs = await firestore.collection('designs').get();

// ✅ Good: Limit + pagination
Query<DesignModel> createQuery(SearchFilter filter) {
  Query<DesignModel> query = firestore
      .collection('designs')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(20); // Always limit
  
  // Add filters
  if (filter.categories != null && filter.categories!.isNotEmpty) {
    query = query.where('category', whereIn: filter.categories);
  }
  
  if (filter.minPrice != null && filter.maxPrice != null) {
    query = query
        .where('price', isGreaterThanOrEqualTo: filter.minPrice)
        .where('price', isLessThanOrEqualTo: filter.maxPrice);
  }
  
  return query;
}

// Pagination
Query<DesignModel> getNextPage(
  SearchFilter filter,
  DocumentSnapshot lastDoc,
) {
  return createQuery(filter)
      .startAfterDocument(lastDoc)
      .limit(20);
}
```

**BLoC with pagination:**
```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepo;
  
  DocumentSnapshot? _lastDocument;
  List<DesignModel> _results = [];
  
  SearchBloc(this.searchRepo) : super(SearchInitial()) {
    on<SearchEvent>(_onSearch);
    on<LoadMoreEvent>(_onLoadMore);
  }
  
  Future<void> _onSearch(SearchEvent event, Emitter emit) async {
    emit(SearchLoading());
    
    final results = await searchRepo.search(event.filter);
    _results = results;
    _lastDocument = null; // Reset pagination
    
    emit(SearchLoaded(_results));
  }
  
  Future<void> _onLoadMore(LoadMoreEvent event, Emitter emit) async {
    if (_lastDocument == null) return;
    
    final moreResults = await searchRepo.searchNextPage(
      event.filter,
      _lastDocument!,
    );
    
    _results.addAll(moreResults);
    emit(SearchLoaded(_results));
  }
}
```

### 5. Lazy Loading & Virtual Scrolling

**Problem: Loading 1000 items into ListView = memory spike + janky scrolling**

**Solution: Virtual scrolling (only render visible items)**

```dart
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ProductList extends StatefulWidget {
  final List<ProductModel> products;
  
  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late ItemScrollController _itemScrollController;
  
  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        // Lazy load: trigger load more when near end
        if (index == widget.products.length - 5) {
          context.read<SearchBloc>().add(LoadMoreEvent());
        }
        
        return ProductCard(widget.products[index]);
      },
    );
  }
}
```

### 6. Image Optimization & Caching

**Problem: Large images = slow loads, high network usage**

**Solution: Compress + cache locally**

```dart
// lib/core/utils/image_cache_manager.dart
import 'package:cached_network_image/cached_network_image.dart';

class ImageCacheManager {
  // Image compression
  static Future<File> compressImage(File imageFile) async {
    final originalSize = imageFile.lengthSync();
    
    final img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) return imageFile;
    
    // Resize if too large
    img.Image resized = image.width > 1000
        ? img.copyResize(image, width: 1000)
        : image;
    
    // Compress to JPEG 80% quality
    final compressed = File('${imageFile.path}_compressed.jpg')
        ..writeAsBytesSync(img.encodeJpg(resized, quality: 80));
    
    final compressedSize = compressed.lengthSync();
    print('Compressed: ${originalSize / 1024}KB → ${compressedSize / 1024}KB');
    
    return compressed;
  }
  
  // Cached network image with placeholder
  static Widget cachedImage(String imageUrl, {double? width, double? height}) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      ),
    );
  }
}

// Use in UI
ImageCacheManager.cachedImage(
  design.imageUrl,
  width: 200,
  height: 200,
)
```

### 7. Memory Leak Prevention

**Common cause: Uncancelled streams in BLoC**

```dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProduct;
  
  // ❌ Bad: Stream subscription never cancelled
  late StreamSubscription _productStream;
  
  ProductBloc(this.getProduct) : super(ProductInitial()) {
    _productStream = getProduct.watchProduct().listen((product) {
      add(ProductUpdatedEvent(product));
    });
  }
  
  // ✅ Good: Cancel streams in close()
  @override
  Future<void> close() {
    _productStream.cancel(); // Cancel before closing
    return super.close();
  }
}
```

**Check for memory leaks:**
```bash
# Run with memory profiling
flutter run --profile

# In DevTools Memory tab:
# 1. Heap snapshot
# 2. Navigate app screens
# 3. Take heap snapshot again
# 4. Compare - memory should not grow
```

### 8. Bundle Size Reduction

**Problem: Large app size = slower downloads, more storage**

**Solution: Remove unused dependencies, use tree-shaking**

```bash
# Analyze bundle size
flutter build apk --analyze-size --release

# View in browser
# build/app/outputs/apk-analysis.html

# Remove unused dependencies
flutter pub deps --no-dev | grep "transitive"
```

**In pubspec.yaml:**
```yaml
# Good: Only necessary packages
dependencies:
  flutter: sdk: flutter
  firebase_core: ^4.7.0
  flutter_bloc: ^8.1.0

# Bad: Avoid bloat
# - Multiple packages for same functionality
# - Packages with many unnecessary dependencies
# - Old/unmaintained packages
```

### 9. Network Efficiency

**Compress API responses:**

```dart
// Use gzip compression
final response = await http.get(
  Uri.parse(url),
  headers: {
    'Accept-Encoding': 'gzip',
  },
);

// Firebase: Enable compression in Cloud Functions
const functions = require('firebase-functions');
const compress = require('compression');
const express = require('express');

const app = express();
app.use(compress());

exports.api = functions.https.onRequest(app);
```

### 10. Firestore Cost Optimization

**Track costs:**

```
- Read: $0.06 per 100K reads/month
- Write: $0.18 per 100K writes/month
- Delete: $0.02 per 100K deletes/month
```

**Optimize:**
```dart
// ❌ Bad: Reads entire user document on every check
final user = await firestore.collection('users').doc(userId).get();
bool isAdmin = user.data()!['role'] == 'admin';

// ✅ Good: Cache in app state
// Set BLoC state when user logs in, check local state after
final bool isAdmin = authBloc.state.userRole == UserRole.admin;
```

### 11. Firebase Performance Monitoring

**Enable in app:**

```dart
import 'package:firebase_performance/firebase_performance.dart';

class FirebasePerformanceHelper {
  static Future<void> logNetworkRequest(
    String url,
    Duration duration,
    int responseCode,
    int bytesSent,
    int bytesReceived,
  ) async {
    final hp = FirebasePerformance.instance;
    final metric = hp.newHttpMetric(url, HttpMethod.Get);
    
    metric.responseCode = responseCode;
    metric.requestPayloadSize = bytesSent;
    metric.responsePayloadSize = bytesReceived;
    metric.duration = duration;
    
    await metric.stop();
  }
  
  static Future<void> logCustomTrace(
    String traceName,
    Future Function() operation,
  ) async {
    final hp = FirebasePerformance.instance;
    final trace = hp.newTrace(traceName);
    
    await trace.start();
    try {
      await operation();
    } finally {
      await trace.stop();
    }
  }
}
```

### 12. DevTools Profiling

**Profile frame rendering:**
```bash
flutter run --profile

# In DevTools → Performance tab:
# 1. Click "Record"
# 2. Interact with app
# 3. Click "Stop"
# 4. View frame chart - look for drops below 60 FPS
```

**Common issues & fixes:**

| Issue | Fix |
|-------|-----|
| Janky list scrolling | Use lazy loading, virtual scrolling |
| Memory grows over time | Cancel streams, check for circular refs |
| Slow image loading | Compress, cache, use thumbnails |
| Slow API calls | Paginate, cache, reduce data size |
| Large bundle size | Remove unused deps, code split |

### 13. Runtime Performance Monitoring

**Send performance data to Firebase:**

```dart
class PerformanceMonitor {
  static final _analytics = FirebaseAnalytics.instance;
  
  static void logScreenLoadTime(
    String screenName,
    Duration duration,
  ) {
    _analytics.logEvent(
      name: 'screen_load_time',
      parameters: {
        'screen': screenName,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }
  
  static void logApiCall(
    String endpoint,
    Duration duration,
    bool success,
  ) {
    _analytics.logEvent(
      name: 'api_call',
      parameters: {
        'endpoint': endpoint,
        'duration_ms': duration.inMilliseconds,
        'success': success,
      },
    );
  }
}
```

### 14. Performance Targets

**Mobile (Android/iOS):**
- App startup: < 2 seconds
- Screen transition: < 500ms
- List scroll: 60 FPS
- Memory: < 500MB
- Bundle size: < 100MB (Android), < 150MB (iOS)

**Web (Admin):**
- Initial load: < 3 seconds
- Page transition: < 300ms
- Memory: < 1GB
- Bundle size: < 500KB (gzip)

---

**Phase 1 MVP:** BLoC caching, Firestore optimization, lazy loading  
**Phase 2+:** Virtual scrolling, bundle reduction, performance monitoring

---

**Ready to ship a fast app!**

/// Shree Krishna Core Package
/// Shared models, entities, and utilities for all Shree Krishna Embroidery apps

// Errors & Failures
export 'errors/exceptions.dart';
export 'errors/failures.dart';

// Constants (Firestore/Storage contract — docs/integration/FIRESTORE_SCHEMA.md)
export 'constants/firestore_collections.dart';
export 'constants/storage_paths.dart';
export 'constants/design_techniques.dart';

// Enums
export 'enums/user_role.dart';
export 'enums/order_status.dart';
export 'enums/design_status.dart';
export 'enums/category_status.dart';
export 'enums/activity_type.dart';

// Utilities
export 'utils/either.dart';
export 'utils/money.dart';
export 'utils/keyword_builder.dart';

// Models (Data Layer)
export 'models/user_model.dart';
export 'models/category_model.dart';
export 'models/design_model.dart';
export 'models/banner_model.dart';

// Entities (Domain Layer)
// Add entity exports here as needed

// Cache & Configuration
export 'cache/cached_data.dart';
export 'cache/cache_config.dart';
export 'cache/local_datasource_base.dart';
export 'config/app_theme_config.dart';

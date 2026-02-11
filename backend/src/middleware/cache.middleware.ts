import NodeCache from 'node-cache';
import { Request, Response, NextFunction } from 'express';

// Create cache instance
const cache = new NodeCache({
  stdTTL: 600, // 10 minutes default TTL
  checkperiod: 120, // Check for expired keys every 2 minutes
  useClones: false,
  maxKeys: 1000,
});

interface CacheOptions {
  ttl?: number; // Time to live in seconds
  key?: string; // Custom cache key
  condition?: (req: Request) => boolean; // Condition to cache
  varyBy?: string[]; // Request properties to vary cache by (e.g., ['user.id', 'query.limit'])
}

// Cache middleware factory
export const cacheMiddleware = (options: CacheOptions = {}) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    // Skip caching for non-GET requests
    if (req.method !== 'GET') {
      return next();
    }

    // Check condition if provided
    if (options.condition && !options.condition(req)) {
      return next();
    }

    // Generate cache key
    const cacheKey = generateCacheKey(req, options);

    // Try to get from cache
    const cachedData = cache.get(cacheKey);
    
    if (cachedData) {
      console.log(`✅ Cache HIT: ${cacheKey}`);
      return res.json(cachedData);
    }

    console.log(`❌ Cache MISS: ${cacheKey}`);

    // Store original json method
    const originalJson = res.json.bind(res);

    // Override json method to cache response
    res.json = (body: any) => {
      // Only cache successful responses
      if (res.statusCode === 200 && body.success !== false) {
        const ttl = options.ttl || 600;
        cache.set(cacheKey, body, ttl);
        console.log(`💾 Cached: ${cacheKey} (TTL: ${ttl}s)`);
      }
      
      return originalJson(body);
    };

    next();
  };
};

// Generate cache key based on request
function generateCacheKey(req: Request, options: CacheOptions): string {
  if (options.key) {
    return options.key;
  }

  const parts: string[] = [
    req.originalUrl || req.url,
  ];

  // Add user-specific caching
  const user = (req as any).user;
  if (user) {
    parts.push(`user:${user.id}`);
  }

  // Add vary-by parameters
  if (options.varyBy) {
    for (const path of options.varyBy) {
      const value = getNestedProperty(req, path);
      if (value !== undefined) {
        parts.push(`${path}:${value}`);
      }
    }
  }

  return parts.join('|');
}

// Get nested property from object
function getNestedProperty(obj: any, path: string): any {
  return path.split('.').reduce((current, prop) => current?.[prop], obj);
}

// Invalidate cache by pattern
export const invalidateCache = (pattern: string | RegExp) => {
  const keys = cache.keys();
  let invalidatedCount = 0;

  for (const key of keys) {
    const shouldInvalidate = typeof pattern === 'string'
      ? key.includes(pattern)
      : pattern.test(key);

    if (shouldInvalidate) {
      cache.del(key);
      invalidatedCount++;
    }
  }

  console.log(`🗑️ Invalidated ${invalidatedCount} cache entries matching: ${pattern}`);
  return invalidatedCount;
};

// Invalidate specific key
export const deleteCacheKey = (key: string) => {
  return cache.del(key);
};

// Clear all cache
export const clearAllCache = () => {
  cache.flushAll();
  console.log('🗑️ All cache cleared');
};

// Get cache stats
export const getCacheStats = () => {
  return cache.getStats();
};

// Preset cache configurations
export const cacheConfigs = {
  // Short cache for frequently changing data
  short: { ttl: 60 }, // 1 minute
  
  // Medium cache for moderate changing data
  medium: { ttl: 600 }, // 10 minutes
  
  // Long cache for rarely changing data
  long: { ttl: 3600 }, // 1 hour
  
  // User-specific cache
  userSpecific: {
    ttl: 600,
    varyBy: ['user.id'],
  },
  
  // Class-specific cache
  classSpecific: {
    ttl: 1800, // 30 minutes
    varyBy: ['params.classId'],
  },
  
  // Paginated cache
  paginated: {
    ttl: 300, // 5 minutes
    varyBy: ['query.page', 'query.limit'],
  },
};

// Export cache instance for direct access
export { cache };
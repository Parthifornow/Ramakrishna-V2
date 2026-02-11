import { Request } from 'express';

export interface PaginationParams {
  page: number;
  limit: number;
  skip: number;
}

export interface PaginationMeta {
  currentPage: number;
  totalPages: number;
  totalItems: number;
  itemsPerPage: number;
  hasNextPage: boolean;
  hasPrevPage: boolean;
}

export interface PaginatedResponse<T> {
  success: true;
  data: T[];
  pagination: PaginationMeta;
}

const DEFAULT_PAGE = 1;
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = parseInt(process.env.MAX_PAGE_SIZE || '100');

/**
 * Extract pagination parameters from request
 */
export const getPaginationParams = (req: Request): PaginationParams => {
  const page = Math.max(1, parseInt(req.query.page as string) || DEFAULT_PAGE);
  const limit = Math.min(
    MAX_LIMIT,
    Math.max(1, parseInt(req.query.limit as string) || DEFAULT_LIMIT)
  );
  const skip = (page - 1) * limit;

  return { page, limit, skip };
};

/**
 * Create pagination metadata
 */
export const createPaginationMeta = (
  page: number,
  limit: number,
  totalItems: number
): PaginationMeta => {
  const totalPages = Math.ceil(totalItems / limit);

  return {
    currentPage: page,
    totalPages,
    totalItems,
    itemsPerPage: limit,
    hasNextPage: page < totalPages,
    hasPrevPage: page > 1,
  };
};

/**
 * Create paginated response
 */
export const createPaginatedResponse = <T>(
  data: T[],
  page: number,
  limit: number,
  totalItems: number
): PaginatedResponse<T> => {
  return {
    success: true,
    data,
    pagination: createPaginationMeta(page, limit, totalItems),
  };
};

/**
 * Paginate Firestore query results
 */
export const paginateFirestoreQuery = async <T>(
  query: any,
  page: number,
  limit: number,
  mapFunction?: (doc: any) => T
): Promise<{ items: T[]; total: number }> => {
  // Get total count
  const countSnapshot = await query.count().get();
  const total = countSnapshot.data().count;

  // Get paginated results
  const skip = (page - 1) * limit;
  const snapshot = await query.offset(skip).limit(limit).get();

  const items = mapFunction
    ? snapshot.docs.map((doc: any) => mapFunction(doc))
    : snapshot.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));

  return { items, total };
};

/**
 * Cursor-based pagination for better performance on large datasets
 */
export interface CursorPaginationParams {
  limit: number;
  cursor?: string;
  direction?: 'next' | 'prev';
}

export interface CursorPaginationMeta {
  hasNextPage: boolean;
  hasPrevPage: boolean;
  nextCursor?: string;
  prevCursor?: string;
  itemsPerPage: number;
}

export const getCursorPaginationParams = (req: Request): CursorPaginationParams => {
  const limit = Math.min(
    MAX_LIMIT,
    Math.max(1, parseInt(req.query.limit as string) || DEFAULT_LIMIT)
  );
  const cursor = req.query.cursor as string | undefined;
  const direction = (req.query.direction as 'next' | 'prev') || 'next';

  return { limit, cursor, direction };
};
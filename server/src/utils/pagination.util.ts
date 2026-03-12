import { PaginationParams, PaginatedResult } from '../types';

export function parsePaginationParams(query: Record<string, any>): PaginationParams {
  const limit = Math.min(Math.max(parseInt(query.limit, 10) || 20, 1), 100);
  const cursor = query.cursor || undefined;
  const direction = query.direction === 'backward' ? 'backward' : 'forward';
  return { cursor, limit, direction };
}

export function buildCursorQuery(params: {
  baseQuery: string;
  baseParams: any[];
  cursor: string | undefined;
  cursorColumn: string;
  direction: 'forward' | 'backward';
  limit: number;
}): { query: string; params: any[] } {
  const { baseQuery, baseParams, cursor, cursorColumn, direction, limit } = params;

  let query = baseQuery;
  const queryParams = [...baseParams];

  if (cursor) {
    const decodedCursor = decodeCursor(cursor);
    const operator = direction === 'forward' ? '<' : '>';
    queryParams.push(decodedCursor.value);
    query += ` AND ${cursorColumn} ${operator} $${queryParams.length}`;
  }

  const sortOrder = direction === 'forward' ? 'DESC' : 'ASC';
  query += ` ORDER BY ${cursorColumn} ${sortOrder}`;
  query += ` LIMIT $${queryParams.length + 1}`;
  queryParams.push(limit + 1);

  return { query, params: queryParams };
}

export function buildPaginatedResult<T extends Record<string, any>>(
  rows: T[],
  limit: number,
  cursorField: string
): PaginatedResult<T> {
  const hasMore = rows.length > limit;
  const data = hasMore ? rows.slice(0, limit) : rows;

  const nextCursor = hasMore && data.length > 0
    ? encodeCursor(data[data.length - 1][cursorField])
    : null;

  const prevCursor = data.length > 0
    ? encodeCursor(data[0][cursorField])
    : null;

  return { data, nextCursor, prevCursor, hasMore };
}

export function encodeCursor(value: any): string {
  const str = value instanceof Date ? value.toISOString() : String(value);
  return Buffer.from(str).toString('base64url');
}

export function decodeCursor(cursor: string): { value: string } {
  const value = Buffer.from(cursor, 'base64url').toString('utf-8');
  return { value };
}

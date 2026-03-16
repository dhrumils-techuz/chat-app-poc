import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { logger } from '../utils/logger';
import { ValidationMsg, ErrorCode, ErrorMsg } from '../constants/messages';

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number, code: string, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, AppError.prototype);
  }

  static badRequest(message: string, code = 'BAD_REQUEST') {
    return new AppError(message, 400, code);
  }

  static unauthorized(message: string, code = 'UNAUTHORIZED') {
    return new AppError(message, 401, code);
  }

  static forbidden(message: string, code = 'FORBIDDEN') {
    return new AppError(message, 403, code);
  }

  static notFound(message: string, code = 'NOT_FOUND') {
    return new AppError(message, 404, code);
  }

  static conflict(message: string, code = 'CONFLICT') {
    return new AppError(message, 409, code);
  }

  static tooMany(message: string, code = 'TOO_MANY_REQUESTS') {
    return new AppError(message, 429, code);
  }

  static internal(message: string, code = 'INTERNAL_ERROR') {
    return new AppError(message, 500, code, false);
  }
}

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction): void {
  const requestId = req.headers['x-request-id'] as string;

  if (err instanceof ZodError) {
    const errors = err.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }));
    res.status(400).json({
      error: ValidationMsg.VALIDATION_FAILED,
      code: ErrorCode.VALIDATION_ERROR,
      details: errors,
      requestId,
    });
    return;
  }

  if (err instanceof AppError) {
    if (!err.isOperational) {
      logger.error('Non-operational error', {
        error: err.message,
        code: err.code,
        stack: err.stack,
        requestId,
      });
    }

    res.status(err.statusCode).json({
      error: err.message,
      code: err.code,
      requestId,
    });
    return;
  }

  // Unexpected errors
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    requestId,
    path: req.path,
    method: req.method,
  });

  res.status(500).json({
    error: ErrorMsg.INTERNAL_SERVER_ERROR,
    code: ErrorCode.INTERNAL_ERROR,
    requestId,
  });
}

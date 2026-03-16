import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { corsOptions } from './config/cors';
import { requestIdMiddleware } from './middleware/request-id.middleware';
import { auditMiddleware } from './middleware/audit.middleware';
import { globalRateLimit } from './middleware/rate-limit.middleware';
import { errorHandler } from './middleware/error-handler.middleware';
import routes from './routes';

const app = express();

// Trust proxy (must be set before rate limiting middleware)
app.set('trust proxy', 1);

// Security headers
app.use(helmet());

// CORS
app.use(cors(corsOptions));

// Compression
app.use(compression());

// Body parsing
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Request ID
app.use(requestIdMiddleware);

// Rate limiting
app.use(globalRateLimit);

// Audit logging
app.use(auditMiddleware);

// API routes
app.use('/api', routes);

// 404 handler
app.use((_req, res) => {
  res.status(404).json({
    error: 'Not found',
    code: 'NOT_FOUND',
  });
});

// Global error handler
app.use(errorHandler);

export default app;

import winston from 'winston';

const sanitizeValue = (value: any): any => {
  if (typeof value === 'string') {
    // Remove potential PHI patterns (SSN, phone, email in log messages)
    return value
      .replace(/\b\d{3}-\d{2}-\d{4}\b/g, '[REDACTED-SSN]')
      .replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[REDACTED-EMAIL]');
  }
  if (typeof value === 'object' && value !== null) {
    const sanitized: Record<string, any> = {};
    for (const [k, v] of Object.entries(value)) {
      const sensitiveKeys = ['password', 'token', 'secret', 'authorization', 'cookie', 'ssn', 'dob', 'diagnosis'];
      if (sensitiveKeys.some((sk) => k.toLowerCase().includes(sk))) {
        sanitized[k] = '[REDACTED]';
      } else {
        sanitized[k] = sanitizeValue(v);
      }
    }
    return sanitized;
  }
  return value;
};

const sanitizeFormat = winston.format((info) => {
  const sanitized = { ...info };
  if (sanitized.metadata) {
    sanitized.metadata = sanitizeValue(sanitized.metadata);
  }
  return sanitized;
});

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DDTHH:mm:ss.SSSZ' }),
  sanitizeFormat(),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

const consoleFormat = winston.format.combine(
  winston.format.timestamp({ format: 'HH:mm:ss.SSS' }),
  sanitizeFormat(),
  winston.format.colorize(),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    const metaStr = Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : '';
    return `${timestamp} ${level}: ${message}${metaStr}`;
  })
);

const isProduction = process.env.NODE_ENV === 'production';

export const logger = winston.createLogger({
  level: isProduction ? 'info' : 'debug',
  defaultMeta: { service: 'medical-chat' },
  transports: [
    new winston.transports.Console({
      format: isProduction ? logFormat : consoleFormat,
    }),
  ],
  exitOnError: false,
});

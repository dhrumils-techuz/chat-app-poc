import { Router, Request, Response } from 'express';
import { healthCheck as dbHealthCheck } from '../config/database';
import { redisHealthCheck } from '../config/redis';
import { HealthStatus } from '../constants/messages';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
  const [dbHealthy, redisHealthy] = await Promise.all([
    dbHealthCheck(),
    redisHealthCheck(),
  ]);

  const healthy = dbHealthy && redisHealthy;

  res.status(healthy ? 200 : 503).json({
    status: healthy ? HealthStatus.HEALTHY : HealthStatus.DEGRADED,
    timestamp: new Date().toISOString(),
    services: {
      database: dbHealthy ? HealthStatus.UP : HealthStatus.DOWN,
      redis: redisHealthy ? HealthStatus.UP : HealthStatus.DOWN,
    },
  });
});

router.get('/ready', async (_req: Request, res: Response) => {
  const [dbHealthy, redisHealthy] = await Promise.all([
    dbHealthCheck(),
    redisHealthCheck(),
  ]);

  if (dbHealthy && redisHealthy) {
    res.status(200).json({ status: HealthStatus.READY });
  } else {
    res.status(503).json({ status: HealthStatus.NOT_READY });
  }
});

router.get('/live', (_req: Request, res: Response) => {
  res.status(200).json({ status: HealthStatus.ALIVE });
});

export default router;

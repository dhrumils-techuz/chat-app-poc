import { Router, Request, Response } from 'express';
import { healthCheck as dbHealthCheck } from '../config/database';
import { redisHealthCheck } from '../config/redis';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
  const [dbHealthy, redisHealthy] = await Promise.all([
    dbHealthCheck(),
    redisHealthCheck(),
  ]);

  const healthy = dbHealthy && redisHealthy;

  res.status(healthy ? 200 : 503).json({
    status: healthy ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    services: {
      database: dbHealthy ? 'up' : 'down',
      redis: redisHealthy ? 'up' : 'down',
    },
  });
});

router.get('/ready', async (_req: Request, res: Response) => {
  const [dbHealthy, redisHealthy] = await Promise.all([
    dbHealthCheck(),
    redisHealthCheck(),
  ]);

  if (dbHealthy && redisHealthy) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ status: 'not ready' });
  }
});

router.get('/live', (_req: Request, res: Response) => {
  res.status(200).json({ status: 'alive' });
});

export default router;

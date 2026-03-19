import { Request, Response, NextFunction } from 'express';
import { query } from '../config/database';
import { logger } from '../utils/logger';

export class DeviceController {
  /**
   * POST /devices/fcm-token
   * Body: { fcmToken: string, deviceName?: string, platform?: string }
   *
   * Updates the FCM token for the current user's device.
   * Uses the deviceId from the JWT payload to upsert the device record.
   */
  async saveFcmToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const auth = req.auth!;
      const { fcmToken, deviceName, platform } = req.body;

      if (!fcmToken) {
        res.status(400).json({ error: 'FCM token is required' });
        return;
      }

      await query(
        `INSERT INTO devices (id, user_id, device_name, platform, fcm_token, is_active, last_active_at)
         VALUES ($1, $2, $3, $4, $5, true, NOW())
         ON CONFLICT (id) DO UPDATE SET
           fcm_token = $5,
           device_name = COALESCE($3, devices.device_name),
           platform = COALESCE($4, devices.platform),
           is_active = true,
           last_active_at = NOW()`,
        [auth.deviceId, auth.userId, deviceName || null, platform || null, fcmToken]
      );

      logger.info('FCM token updated', { userId: auth.userId, deviceId: auth.deviceId });

      res.status(200).json({
        success: true,
        message: 'FCM token updated',
      });
    } catch (error) {
      next(error);
    }
  }
}

export const deviceController = new DeviceController();

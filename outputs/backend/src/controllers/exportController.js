import exportService from '../services/exportService.js';

export const exportController = {
  async requestExport(req, res, next) {
    try {
      const { format } = req.body;
      const hostUrl = `${req.protocol}://${req.get('host')}`;
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

      const result = await exportService.requestExport(
        req.user.userId,
        format,
        hostUrl,
        clientIp
      );

      res.status(202).json(result);
    } catch (err) {
      next(err);
    }
  },

  async getExportStatus(req, res, next) {
    try {
      const { exportId } = req.params;
      const result = await exportService.getExportStatus(req.user.userId, exportId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  async getUserExports(req, res, next) {
    try {
      const result = await exportService.getUserExports(req.user.userId);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  async retryExport(req, res, next) {
    try {
      const { exportId } = req.params;
      const hostUrl = `${req.protocol}://${req.get('host')}`;
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

      const result = await exportService.retryExport(
        req.user.userId,
        exportId,
        hostUrl,
        clientIp
      );

      res.status(202).json(result);
    } catch (err) {
      next(err);
    }
  }
};

export default exportController;

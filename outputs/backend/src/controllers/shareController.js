import shareService from '../services/shareService.js';

export const shareController = {
  async generateShareLink(req, res, next) {
    try {
      const { journalId } = req.params;
      const hostUrl = `${req.protocol}://${req.get('host')}`;
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

      const result = await shareService.generateShareLink(
        req.user.userId,
        journalId,
        hostUrl,
        clientIp
      );

      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  },

  async revokeShareLink(req, res, next) {
    try {
      const { journalId } = req.params;
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;

      const result = await shareService.revokeShareLink(
        req.user.userId,
        journalId,
        clientIp
      );

      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  },

  async getPublicEntry(req, res, next) {
    try {
      const { shareToken } = req.params;
      const result = await shareService.getPublicEntry(shareToken);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
};

export default shareController;

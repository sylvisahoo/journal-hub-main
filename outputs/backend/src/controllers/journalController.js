import journalService from '../services/journalService.js';

export const journalController = {
  async createJournal(req, res, next) {
    try {
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const journal = await journalService.createJournal(req.user.userId, req.body, clientIp);
      res.status(201).json(journal);
    } catch (err) {
      next(err);
    }
  },

  async getJournal(req, res, next) {
    try {
      const journal = await journalService.getJournal(req.user.userId, req.params.journalId);
      res.status(200).json(journal);
    } catch (err) {
      next(err);
    }
  },

  async listJournals(req, res, next) {
    try {
      const { startDate, endDate, tag, category, keyword, page, limit } = req.query;
      
      const filters = {
        startDate,
        endDate,
        tagId: tag,
        categoryId: category,
        keyword,
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 100
      };

      const journals = await journalService.listJournals(req.user.userId, filters);
      res.status(200).json(journals);
    } catch (err) {
      next(err);
    }
  },

  async updateJournal(req, res, next) {
    try {
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const journal = await journalService.updateJournal(
        req.user.userId,
        req.params.journalId,
        req.body,
        clientIp
      );
      res.status(200).json(journal);
    } catch (err) {
      next(err);
    }
  },

  async deleteJournal(req, res, next) {
    try {
      const permanent = req.query.permanent === 'true';
      const clientIp = req.ip || req.headers['x-forwarded-for'] || req.socket.remoteAddress;
      const result = await journalService.deleteJournal(
        req.user.userId,
        req.params.journalId,
        permanent,
        clientIp
      );
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  }
};

export default journalController;

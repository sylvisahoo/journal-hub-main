import draftService from '../services/draftService.js';

export const draftController = {
  async saveDraft(req, res, next) {
    try {
      const { draftId, journalId, title, content, deviceIdentifier = 'mobile' } = req.body;
      const userId = req.user.userId;

      const result = await draftService.saveDraft({
        draftId,
        userId,
        journalId,
        title,
        content,
        deviceIdentifier
      });

      res.status(200).json({
        draftId: result.draft_id,
        syncStatus: result.sync_status
      });
    } catch (error) {
      next(error);
    }
  },

  async getDraft(req, res, next) {
    try {
      const { draftId } = req.params;
      const userId = req.user.userId;

      const result = await draftService.getDraft(draftId, userId);

      res.status(200).json({
        draftId: result.draft_id,
        userId: result.user_id,
        journalId: result.journal_id,
        title: result.title,
        content: result.content,
        deviceIdentifier: result.device_identifier,
        syncStatus: result.sync_status,
        savedAt: result.saved_at
      });
    } catch (error) {
      next(error);
    }
  }
};

export default draftController;

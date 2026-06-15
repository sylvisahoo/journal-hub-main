import { v4 as uuidv4 } from 'uuid';
import draftRepository from '../repositories/draftRepository.js';
import { ApiError } from '../middleware/errorHandler.js';

export const draftService = {
  async saveDraft({ draftId, userId, journalId = null, title = '', content = '', deviceIdentifier = 'mobile', syncStatus = 'Synced' }) {
    const activeDraftId = draftId || `d-${uuidv4()}`;

    // If draftId is provided, perform ownership check first
    if (draftId) {
      const existing = await draftRepository.findById(draftId);
      if (existing && existing.user_id !== userId) {
        throw new ApiError(403, 'ACCESS_DENIED', 'You do not have permission to modify this draft');
      }
    }

    const draftRecord = {
      draftId: activeDraftId,
      userId,
      journalId,
      title,
      content,
      deviceIdentifier,
      syncStatus
    };

    return draftRepository.upsertDraft(draftRecord);
  },

  async getDraft(draftId, userId) {
    const draft = await draftRepository.findById(draftId);
    if (!draft) {
      throw new ApiError(404, 'DRAFT_NOT_FOUND', 'Draft not found');
    }
    if (draft.user_id !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have permission to access this draft');
    }
    return draft;
  }
};

export default draftService;

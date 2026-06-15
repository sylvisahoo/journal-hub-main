import { v4 as uuidv4 } from 'uuid';
import shareRepository from '../repositories/shareRepository.js';
import journalRepository from '../repositories/journalRepository.js';
import auditRepository from '../repositories/auditRepository.js';
import { ApiError } from '../middleware/errorHandler.js';

export const shareService = {
  async generateShareLink(userId, journalId, hostUrl, clientIp = null) {
    const journal = await journalRepository.findById(journalId);
    if (!journal || journal.deletedAt) {
      throw new ApiError(404, 'ENTRY_NOT_FOUND', 'Journal entry not found');
    }

    if (journal.userId !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have access to this journal entry');
    }

    // Deactivate existing active share(s) for security
    await shareRepository.deactivateSharesByJournalId(journalId);

    const shareToken = uuidv4();
    const shareId = `s-${uuidv4()}`;

    await shareRepository.createShare(shareId, journalId, shareToken);

    // Audit Log for sharing action
    await auditRepository.log(userId, 'JournalEntry', journalId, 'Share', clientIp, { shareToken });

    const shareUrl = `${hostUrl}/api/v1/share/${shareToken}`;

    return {
      shareUrl,
      shareToken
    };
  },

  async revokeShareLink(userId, journalId, clientIp = null) {
    const journal = await journalRepository.findById(journalId);
    if (!journal || journal.deletedAt) {
      throw new ApiError(404, 'ENTRY_NOT_FOUND', 'Journal entry not found');
    }

    if (journal.userId !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have access to this journal entry');
    }

    const activeShare = await shareRepository.findActiveByJournalId(journalId);
    if (!activeShare) {
      throw new ApiError(404, 'SHARE_NOT_FOUND', 'No active share link found for this journal');
    }

    await shareRepository.deactivateSharesByJournalId(journalId);

    // Audit Log for revocation action
    await auditRepository.log(userId, 'JournalEntry', journalId, 'RevokeShare', clientIp);

    return {
      message: 'Share link successfully revoked'
    };
  },

  async getPublicEntry(shareToken) {
    const share = await shareRepository.findByToken(shareToken);
    if (!share) {
      throw new ApiError(404, 'INVALID_SHARE_TOKEN', 'Invalid share token');
    }

    if (!share.isActive) {
      throw new ApiError(404, 'SHARE_REVOKED', 'This share link has been revoked');
    }

    const journal = await journalRepository.findById(share.journalId);
    if (!journal || journal.deletedAt) {
      throw new ApiError(404, 'ENTRY_NOT_FOUND', 'Journal entry not found');
    }

    // Return view-only fields of the journal entry
    return {
      journalId: journal.journalId,
      title: journal.title,
      content: journal.content,
      entryDate: journal.entryDate,
      wordCount: journal.wordCount,
      createdAt: journal.createdAt,
      updatedAt: journal.updatedAt,
      categoryId: journal.categoryId,
      tags: journal.tags
    };
  }
};

export default shareService;

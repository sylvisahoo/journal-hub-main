import { v4 as uuidv4 } from 'uuid';
import journalRepository from '../repositories/journalRepository.js';
import categoryRepository from '../repositories/categoryRepository.js';
import tagRepository from '../repositories/tagRepository.js';
import auditRepository from '../repositories/auditRepository.js';
import { ApiError } from '../middleware/errorHandler.js';

export const journalService = {
  // Helper to compute word count from markdown or plain text
  _calculateWordCount(content) {
    if (!content) return 0;
    return content.trim().split(/\s+/).filter(Boolean).length;
  },

  async _validateCategoryAndTags(userId, categoryId, tags) {
    if (categoryId) {
      const category = await categoryRepository.findById(categoryId);
      if (!category || category.userId !== userId) {
        throw new ApiError(400, 'INVALID_CATEGORY', 'The selected category is invalid');
      }
    }

    if (tags && tags.length > 0) {
      for (const tagId of tags) {
        const tag = await tagRepository.findById(tagId);
        if (!tag || tag.userId !== userId) {
          throw new ApiError(400, 'INVALID_TAG', 'One or more selected tags are invalid');
        }
      }
    }
  },

  async createJournal(userId, data, clientIp = null) {
    const { title, content, entryDate, categoryId, tags = [], isPrivate = true } = data;

    // Validate relationships
    await this._validateCategoryAndTags(userId, categoryId, tags);

    const journalId = `j-${uuidv4()}`;
    const wordCount = this._calculateWordCount(content);

    const entryRecord = {
      journalId,
      userId,
      categoryId,
      title: title.trim(),
      content: content.trim(),
      entryDate: typeof entryDate === 'string' ? entryDate : (entryDate instanceof Date ? entryDate.toISOString() : String(entryDate)),
      wordCount,
      isPrivate
    };

    const result = await journalRepository.createEntry(entryRecord, tags);
    await auditRepository.log(userId, 'JournalEntry', journalId, 'Create', clientIp);
    return result;
  },

  async getJournal(userId, journalId) {
    const entry = await journalRepository.findById(journalId);
    if (!entry || entry.deletedAt) {
      throw new ApiError(404, 'ENTRY_NOT_FOUND', 'Journal entry not found');
    }

    if (entry.userId !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have access to this journal entry');
    }

    return entry;
  },

  async listJournals(userId, filters) {
    return journalRepository.findByUser(userId, filters);
  },

  async updateJournal(userId, journalId, data, clientIp = null) {
    const { title, content, entryDate, categoryId, tags, isPrivate, versionNumber } = data;

    const entry = await journalRepository.findById(journalId);
    if (!entry || entry.deletedAt) {
      throw new ApiError(404, 'ENTRY_NOT_FOUND', 'Journal entry not found');
    }

    if (entry.userId !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have permission to edit this journal entry');
    }

    // Optimistic Concurrency Control Check
    if (versionNumber !== entry.versionNumber) {
      throw new ApiError(409, 'VERSION_CONFLICT', 'Simultaneous editing conflict detected. Please reload.');
    }

    // Validate relationships
    await this._validateCategoryAndTags(userId, categoryId || entry.categoryId, tags);

    const updatedTitle = title !== undefined ? title.trim() : entry.title;
    const updatedContent = content !== undefined ? content.trim() : entry.content;
    const updatedEntryDate = entryDate !== undefined 
      ? (typeof entryDate === 'string' ? entryDate : (entryDate instanceof Date ? entryDate.toISOString() : String(entryDate))) 
      : entry.entryDate;
    const updatedCategoryId = categoryId !== undefined ? categoryId : entry.categoryId;
    const updatedIsPrivate = isPrivate !== undefined ? isPrivate : entry.isPrivate;
    const updatedTags = tags !== undefined ? tags : entry.tags;

    const wordCount = this._calculateWordCount(updatedContent);

    const entryRecord = {
      journalId,
      userId,
      categoryId: updatedCategoryId,
      title: updatedTitle,
      content: updatedContent,
      entryDate: updatedEntryDate,
      wordCount,
      isPrivate: updatedIsPrivate
    };

    const result = await journalRepository.updateEntry(entryRecord, updatedTags);
    await auditRepository.log(userId, 'JournalEntry', journalId, 'Update', clientIp);
    return result;
  },

  async deleteJournal(userId, journalId, permanent = false, clientIp = null) {
    const entry = await journalRepository.findById(journalId);
    
    // Note: If hard-deleting, it's allowed even if already soft-deleted. If soft-deleting, must not be already soft-deleted.
    if (!entry || (!permanent && entry.deletedAt)) {
      throw new ApiError(404, 'ENTRY_NOT_FOUND', 'Journal entry not found');
    }

    if (entry.userId !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have permission to delete this journal entry');
    }

    if (permanent) {
      await journalRepository.hardDeleteEntry(journalId);
    } else {
      await journalRepository.softDeleteEntry(journalId);
    }

    // Log audit for deletion
    await auditRepository.log(userId, 'JournalEntry', journalId, 'Delete', clientIp);

    return {
      message: permanent ? 'Journal entry permanently deleted' : 'Journal entry soft deleted'
    };
  }
};

export default journalService;

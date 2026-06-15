import { v4 as uuidv4 } from 'uuid';
import tagRepository from '../repositories/tagRepository.js';
import { ApiError } from '../middleware/errorHandler.js';

export const tagService = {
  async createTag(userId, tagName) {
    const trimmedName = tagName.trim();
    if (!trimmedName) {
      throw new ApiError(400, 'TAG_NAME_REQUIRED', 'Tag name cannot be empty');
    }

    const existing = await tagRepository.findByNameAndUser(trimmedName, userId);
    if (existing) {
      throw new ApiError(409, 'DUPLICATE_TAG', 'Tag name already exists');
    }

    const tagId = `t-${uuidv4()}`;
    return tagRepository.create({ tagId, userId, tagName: trimmedName });
  },

  async getTags(userId) {
    return tagRepository.findByUser(userId);
  }
};

export default tagService;

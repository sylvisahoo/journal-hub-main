import express from 'express';
import shareController from '../controllers/shareController.js';

const router = express.Router();

router.get('/:shareToken', shareController.getPublicEntry);

export default router;

import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import path from 'path';
import PDFDocument from 'pdfkit';
import { Document, Packer, Paragraph, HeadingLevel } from 'docx';
import exportRepository from '../repositories/exportRepository.js';
import journalRepository from '../repositories/journalRepository.js';
import auditRepository from '../repositories/auditRepository.js';
import db from '../config/db.js';
import { ApiError } from '../middleware/errorHandler.js';

export const exportService = {
  async requestExport(userId, format, hostUrl, clientIp = null) {
    if (!format || (format !== 'PDF' && format !== 'DOCX' && format !== 'JSON')) {
      throw new ApiError(400, 'INVALID_EXPORT_FORMAT', 'Format must be PDF, DOCX, or JSON');
    }

    const exportId = `exp-${uuidv4()}`;

    // Create request in DB
    const requestJob = await exportRepository.createExportRequest(exportId, userId, format);

    // Audit Log for export action
    await auditRepository.log(userId, 'ExportRequest', exportId, 'Export', clientIp, { format });

    // Trigger background process (non-blocking)
    setImmediate(() => {
      this.processExportBackground(exportId, userId, format, hostUrl).catch((err) => {
        console.error(`Background export processing error for ID ${exportId}:`, err);
      });
    });

    return {
      exportId: requestJob.exportId,
      status: requestJob.status
    };
  },

  async getExportStatus(userId, exportId) {
    const job = await exportRepository.getExportRequest(exportId);
    if (!job) {
      throw new ApiError(404, 'EXPORT_NOT_FOUND', 'Export job not found');
    }

    if (job.userId !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have permission to access this export job');
    }

    let downloadUrl = null;
    if (job.status === 'Completed') {
      const file = await exportRepository.getExportFileByExportId(exportId);
      if (file) {
        downloadUrl = file.downloadUrl;
      }
    }

    return {
      exportId: job.exportId,
      format: job.format,
      status: job.status,
      requestedAt: job.requestedAt,
      completedAt: job.completedAt,
      downloadUrl
    };
  },

  async getUserExports(userId) {
    return await exportRepository.getUserExportRequests(userId);
  },

  async retryExport(userId, exportId, hostUrl, clientIp = null) {
    const job = await exportRepository.getExportRequest(exportId);
    if (!job) {
      throw new ApiError(404, 'EXPORT_NOT_FOUND', 'Export job not found');
    }

    if (job.userId !== userId) {
      throw new ApiError(403, 'ACCESS_DENIED', 'You do not have permission to access this export job');
    }

    if (job.status !== 'Failed') {
      throw new ApiError(400, 'INVALID_RETRY', 'Only failed export jobs can be retried');
    }

    // Reset status to Pending
    const updatedJob = await exportRepository.updateExportRequestStatus(exportId, 'Pending', null);

    // Audit Log for retry action
    await auditRepository.log(userId, 'ExportRequest', exportId, 'ExportRetry', clientIp);

    // Trigger background process (non-blocking)
    setImmediate(() => {
      this.processExportBackground(exportId, userId, job.format, hostUrl).catch((err) => {
        console.error(`Background export retry error for ID ${exportId}:`, err);
      });
    });

    return {
      exportId: updatedJob.exportId,
      status: updatedJob.status
    };
  },

  async processExportBackground(exportId, userId, format, hostUrl) {
    try {
      // 1. Transition to Processing
      await exportRepository.updateExportRequestStatus(exportId, 'Processing');

      // Fetch user details for the report
      const user = await db.get('SELECT full_name, email FROM User WHERE user_id = ?;', [userId]);
      const fullName = user ? user.full_name : 'Journal Hub User';

      // Fetch active entries
      const entries = await journalRepository.findByUser(userId, { limit: 10000 });

      // Check for simulated failure trigger (for testing the retry flow)
      const shouldFail = entries.some(e => e.content && e.content.includes('trigger-export-failure'));
      if (shouldFail) {
        throw new Error('Simulated export generation failure');
      }

      // Ensure output directory exists
      const exportsDir = path.join(process.cwd(), 'public/exports');
      if (!fs.existsSync(exportsDir)) {
        fs.mkdirSync(exportsDir, { recursive: true });
      }

      const fileName = `journal_export_${exportId}.${format.toLowerCase()}`;
      const filePath = path.join(exportsDir, fileName);

      if (format === 'JSON') {
        const jsonContent = entries.map(entry => ({
          title: entry.title,
          date: entry.entryDate,
          categoryId: entry.categoryId || null,
          wordCount: entry.wordCount,
          isPrivate: !!entry.isPrivate,
          content: entry.content
        }));
        fs.writeFileSync(filePath, JSON.stringify(jsonContent, null, 2), 'utf8');
      } else if (format === 'PDF') {
        const doc = new PDFDocument({ compress: false });
        const stream = fs.createWriteStream(filePath);
        doc.pipe(stream);

        doc.fontSize(20).text(`JOURNAL ARCHIVE EXPORT (PDF)`, { align: 'center' });
        doc.moveDown();
        doc.fontSize(12).text(`User Name: ${fullName}`);
        doc.text(`Export ID: ${exportId}`);
        doc.text(`Generated At: ${new Date().toISOString()}`);
        doc.text(`Total Entries: ${entries.length}`);
        doc.moveDown();
        doc.text(`==================================================`);
        doc.moveDown();

        for (let i = 0; i < entries.length; i++) {
          const entry = entries[i];
          doc.fontSize(14).text(`Entry #${i + 1}: ${entry.title}`, { underline: true });
          doc.fontSize(10).text(`Date: ${entry.entryDate} | Category ID: ${entry.categoryId || 'None'} | Word Count: ${entry.wordCount} | Privacy: ${entry.isPrivate ? 'Private' : 'Publicly Shared'}`);
          doc.moveDown();
          doc.fontSize(11).text(entry.content);
          doc.moveDown();
          doc.fontSize(10).text(`--------------------------------------------------`);
          doc.moveDown();
        }

        doc.end();

        await new Promise((resolve, reject) => {
          stream.on('finish', resolve);
          stream.on('error', reject);
        });
      } else if (format === 'DOCX') {
        const children = [
          new Paragraph({
            text: `JOURNAL ARCHIVE EXPORT (DOCX)`,
            heading: HeadingLevel.HEADING_1,
          }),
          new Paragraph({ text: `User Name: ${fullName}` }),
          new Paragraph({ text: `Export ID: ${exportId}` }),
          new Paragraph({ text: `Generated At: ${new Date().toISOString()}` }),
          new Paragraph({ text: `Total Entries: ${entries.length}` }),
          new Paragraph({ text: `==================================================` }),
        ];

        for (let i = 0; i < entries.length; i++) {
          const entry = entries[i];
          children.push(
            new Paragraph({
              text: `Entry #${i + 1}: ${entry.title}`,
              heading: HeadingLevel.HEADING_2,
              spacing: { before: 200 },
            })
          );
          children.push(
            new Paragraph({
              text: `Date: ${entry.entryDate} | Category ID: ${entry.categoryId || 'None'} | Word Count: ${entry.wordCount} | Privacy: ${entry.isPrivate ? 'Private' : 'Publicly Shared'}`,
            })
          );
          children.push(
            new Paragraph({
              text: entry.content || '',
              spacing: { before: 100, after: 100 },
            })
          );
          children.push(
            new Paragraph({ text: `--------------------------------------------------` })
          );
        }

        const docxDoc = new Document({
          sections: [{
            children
          }]
        });

        const docxBuffer = await Packer.toBuffer(docxDoc);
        fs.writeFileSync(filePath, docxBuffer);
      }

      // Create completed file entry in DB
      const fileId = `f-${uuidv4()}`;
      const downloadUrl = `${hostUrl}/exports/${fileName}`;
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(); // 24-hour expiration

      await exportRepository.createExportFile(fileId, exportId, fileName, downloadUrl, expiresAt);

      // Mark request as Completed
      await exportRepository.updateExportRequestStatus(exportId, 'Completed', new Date().toISOString());

      // Create Success Notification
      const notificationId = `n-${uuidv4()}`;
      const notificationMsg = `Your journal export (ID: ${exportId.substring(exportId.length - 5)}) is ready for download.`;
      await db.run(
        `INSERT INTO Notification (notification_id, user_id, title, message, is_read, created_at)
         VALUES (?, ?, ?, ?, 0, CURRENT_TIMESTAMP);`,
        [notificationId, userId, 'Export Completed', notificationMsg]
      );

    } catch (err) {
      console.error(`Export background processing failed: ${err.message}`);

      // Mark request as Failed
      await exportRepository.updateExportRequestStatus(exportId, 'Failed');

      // Create Failure Notification
      const notificationId = `n-${uuidv4()}`;
      const notificationMsg = `Your journal export (ID: ${exportId.substring(exportId.length - 5)}) failed to generate.`;
      await db.run(
        `INSERT INTO Notification (notification_id, user_id, title, message, is_read, created_at)
         VALUES (?, ?, ?, ?, 0, CURRENT_TIMESTAMP);`,
        [notificationId, userId, 'Export Failed', notificationMsg]
      );
    }
  }
};

export default exportService;

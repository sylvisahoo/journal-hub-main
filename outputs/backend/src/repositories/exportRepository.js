import db from '../config/db.js';

export const exportRepository = {
  _mapRequestRow(row) {
    if (!row) return null;
    return {
      exportId: row.export_id,
      userId: row.user_id,
      format: row.export_format,
      status: row.export_status,
      requestedAt: row.requested_at,
      completedAt: row.completed_at
    };
  },

  _mapFileRow(row) {
    if (!row) return null;
    return {
      fileId: row.file_id,
      exportId: row.export_id,
      fileName: row.file_name,
      downloadUrl: row.download_url,
      expiresAt: row.expires_at,
      createdAt: row.created_at
    };
  },

  async createExportRequest(exportId, userId, format) {
    const sql = `
      INSERT INTO ExportRequest (export_id, user_id, export_format, export_status, requested_at)
      VALUES (?, ?, ?, 'Pending', CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [exportId, userId, format]);
    return this.getExportRequest(exportId);
  },

  async getExportRequest(exportId) {
    const row = await db.get('SELECT * FROM ExportRequest WHERE export_id = ?;', [exportId]);
    return this._mapRequestRow(row);
  },

  async updateExportRequestStatus(exportId, status, completedAt = null) {
    const sql = `
      UPDATE ExportRequest
      SET export_status = ?, completed_at = ?
      WHERE export_id = ?;
    `;
    await db.run(sql, [status, completedAt, exportId]);
    return this.getExportRequest(exportId);
  },

  async createExportFile(fileId, exportId, fileName, downloadUrl, expiresAt) {
    const sql = `
      INSERT INTO ExportFile (file_id, export_id, file_name, download_url, expires_at, created_at)
      VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP);
    `;
    await db.run(sql, [fileId, exportId, fileName, downloadUrl, expiresAt]);
    return this.getExportFileByExportId(exportId);
  },

  async getExportFileByExportId(exportId) {
    const row = await db.get('SELECT * FROM ExportFile WHERE export_id = ?;', [exportId]);
    return this._mapFileRow(row);
  },

  async getUserExportRequests(userId) {
    const sql = `
      SELECT r.*, f.download_url
      FROM ExportRequest r
      LEFT JOIN ExportFile f ON r.export_id = f.export_id
      WHERE r.user_id = ?
      ORDER BY r.requested_at DESC;
    `;
    const rows = await db.all(sql, [userId]);
    return rows.map((row) => {
      const mapped = this._mapRequestRow(row);
      if (mapped && row.download_url) {
        mapped.downloadUrl = row.download_url;
      }
      return mapped;
    }).filter(Boolean);
  }
};

export default exportRepository;

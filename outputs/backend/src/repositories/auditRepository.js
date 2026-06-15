import db from '../config/db.js';
import { v4 as uuidv4 } from 'uuid';

export const auditRepository = {
  async log(userId, entityType, entityId, actionType, ipAddress = null, metadata = null) {
    const auditId = `audit-${uuidv4()}`;
    const sql = `
      INSERT INTO AuditLog (audit_id, user_id, entity_type, entity_id, action_type, ip_address, metadata)
      VALUES (?, ?, ?, ?, ?, ?, ?);
    `;
    const metadataStr = metadata ? JSON.stringify(metadata) : null;
    await db.run(sql, [auditId, userId, entityType, entityId || null, actionType, ipAddress, metadataStr]);
  }
};

export default auditRepository;

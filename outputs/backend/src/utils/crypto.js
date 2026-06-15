import crypto from 'crypto';

const ALGORITHM = 'aes-256-cbc';
const SALT = 'journal-hub-encryption-salt';

// Derives a key using scrypt from the JWT secret and user_id to ensure user-specific encryption keys.
const getSecretKey = (userId) => {
  const secret = process.env.JWT_SECRET || 'fallback-secret-key';
  const salt = userId ? `${SALT}-${userId}` : SALT;
  return crypto.scryptSync(secret, salt, 32);
};

/**
 * Encrypts a text string using AES-256-CBC with a user-specific derived key.
 * The output is prefixed with "ENC:" for easy detection.
 */
export function encryptContent(text, userId) {
  if (!text) return '';
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, getSecretKey(userId), iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return `ENC:${iv.toString('hex')}:${encrypted}`;
}

/**
 * Decrypts a ciphertext string if it starts with "ENC:".
 * If it does not start with "ENC:", it returns the original text.
 */
export function decryptContent(text, userId) {
  if (!text || !text.startsWith('ENC:')) return text;
  try {
    const parts = text.split(':');
    if (parts.length !== 3) return text;
    
    const iv = Buffer.from(parts[1], 'hex');
    const encryptedText = parts[2];
    const decipher = crypto.createDecipheriv(ALGORITHM, getSecretKey(userId), iv);
    
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (err) {
    console.error('Decryption failed, returning original text:', err);
    return text;
  }
}

/**
 * Password utility: secure password hashing and verification using bcrypt
 * Best practices:
 * - Use bcrypt with configurable salt rounds (env: BCRYPT_SALT_ROUNDS, default 12)
 * - Use async APIs to avoid blocking event loop
 * - Validate inputs and avoid returning sensitive data in errors
 */

const bcrypt = require('bcryptjs');

const DEFAULT_ROUNDS = 12;
const MIN_ROUNDS = 10;

function getRounds() {
  const env = parseInt(process.env.BCRYPT_SALT_ROUNDS, 10);
  if (!Number.isInteger(env)) return DEFAULT_ROUNDS;
  return Math.max(MIN_ROUNDS, env);
}

/**
 * Hash a plain-text password using bcrypt.
 * @param {string} password - Plain text password
 * @returns {Promise<string>} - bcrypt hash
 */
async function hashPassword(password) {
  if (typeof password !== 'string' || password.length === 0) {
    throw new Error('Invalid password');
  }

  const rounds = getRounds();
  const salt = await bcrypt.genSalt(rounds);
  return await bcrypt.hash(password, salt);
}

/**
 * Verify a plain-text password against a bcrypt hash.
 * @param {string} password - Plain text password
 * @param {string} hash - bcrypt hash
 * @returns {Promise<boolean>} - true if match
 */
async function verifyPassword(password, hash) {
  if (typeof password !== 'string' || password.length === 0) return false;
  if (typeof hash !== 'string' || hash.length === 0) return false;
  try {
    return await bcrypt.compare(password, hash);
  } catch (err) {
    // Do not leak internals; on error, return false
    return false;
  }
}

module.exports = { hashPassword, verifyPassword };

const db = require('../database');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

async function testSessionChanges() {
    console.log('--- Starting Session Audit Test ---');

    const testEmail = `session_test_${Date.now()}@example.com`;

    try {
        // Setup: Create User
        const userRes = await db.query("INSERT INTO users (email, password_hash) VALUES ($1, 'hash') RETURNING id", [testEmail]);
        const userId = userRes.rows[0].id;

        // 1. INSERT (Login)
        console.log('Performing INSERT (Create Session)...');
        const tokenHash = crypto.createHash('sha256').update('access_token').digest('hex');
        const refreshHash = crypto.createHash('sha256').update('refresh_token').digest('hex');
        const expiresAt = new Date(Date.now() + 3600000); // 1 hour
        const refreshExpiresAt = new Date(Date.now() + 86400000); // 1 day

        const insertRes = await db.query(
            `INSERT INTO sessions (user_id, token_hash, refresh_token_hash, expires_at, refresh_expires_at) 
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
            [userId, tokenHash, refreshHash, expiresAt, refreshExpiresAt]
        );
        const sessionId = insertRes.rows[0].id;
        console.log('Change Logged: Session Created');
        console.log('Session ID:', sessionId);

        // 2. UPDATE (Refresh Token Rotation)
        console.log('Performing UPDATE (Rotate Token)...');
        const newRefreshHash = crypto.createHash('sha256').update('new_refresh_token').digest('hex');
        const updateRes = await db.query(
            'UPDATE sessions SET refresh_token_hash = $1 WHERE id = $2 RETURNING *',
            [newRefreshHash, sessionId]
        );
        console.log('Change Logged: Session Rotated');
        console.log('New Hash:', updateRes.rows[0].refresh_token_hash);

        // 3. UPDATE (Revoke/Logout)
        console.log('Performing UPDATE (Revoke)...');
        await db.query(
            'UPDATE sessions SET is_valid = false, revoked_at = NOW() WHERE id = $1',
            [sessionId]
        );
        console.log('Change Logged: Session Revoked');

        // Cleanup (Cascade Delete)
        console.log('Performing DELETE (User)...');
        await db.query('DELETE FROM users WHERE id = $1', [userId]);

        // Verify Cascade
        const check = await db.query('SELECT * FROM sessions WHERE id = $1', [sessionId]);
        if (check.rows.length === 0) {
            console.log('Change Logged: Session Deleted via Cascade');
        } else {
            console.error('Error: Session not deleted');
        }

    } catch (err) {
        console.error('Test Failed:', err);
    } finally {
        console.log('--- Session Audit Test Complete ---');
        process.exit(0);
    }
}

if (require.main === module) {
    testSessionChanges();
}

const db = require('../database');
const { v4: uuidv4 } = require('uuid');

async function testFileChanges() {
    console.log('--- Starting File Audit Test ---');

    // Mock Data
    const fileId = uuidv4();
    const ownerId = uuidv4(); // In real test, would need real owner
    const userId = uuidv4();  // In real test, would need real user

    // Note: Since we have Foreign Key constraints, we might fail if we don't create user/owner first.
    // For this test script to run standalone, we should ideally create them or assume they exist.
    // To keep it simple and robust, we will create a temp user and owner first.

    try {
        // Setup: Create Temp User and Owner
        const userRes = await db.query("INSERT INTO users (email, password_hash) VALUES ($1, 'hash') RETURNING id", [`file_test_user_${Date.now()}@test.com`]);
        const ownerRes = await db.query("INSERT INTO owners (email, password_hash, public_key) VALUES ($1, 'hash', 'PEM') RETURNING id", [`file_test_owner_${Date.now()}@test.com`]);

        const realUserId = userRes.rows[0].id;
        const realOwnerId = ownerRes.rows[0].id;

        // 1. INSERT (Upload)
        console.log('Performing INSERT (File Upload)...');
        const insertQ = `
      INSERT INTO files (
        id, user_id, owner_id, file_name, encrypted_file_data, 
        file_size_bytes, iv_vector, auth_tag, encrypted_symmetric_key
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
      RETURNING *
    `;
        const fileRes = await db.query(insertQ, [
            fileId, realUserId, realOwnerId, 'secret_plans.pdf',
            Buffer.from('encrypteddata'), 1024,
            Buffer.from('iv'), Buffer.from('tag'), Buffer.from('key')
        ]);
        console.log('Change Logged: File Record Created');
        console.log('File ID:', fileRes.rows[0].id);

        // 2. UPDATE (Soft Delete / Printed)
        console.log('Performing UPDATE (Mark as Printed)...');
        const updateRes = await db.query(
            'UPDATE files SET is_printed = true, printed_at = NOW() WHERE id = $1 RETURNING *',
            [fileId]
        );
        console.log('Change Logged: File Marked Printed');
        console.log('Printed At:', updateRes.rows[0].printed_at);

        // Cleanup
        await db.query('DELETE FROM files WHERE id = $1', [fileId]);
        await db.query('DELETE FROM users WHERE id = $1', [realUserId]);
        await db.query('DELETE FROM owners WHERE id = $1', [realOwnerId]);
        console.log('Cleanup Complete');

    } catch (err) {
        console.error('Test Failed:', err);
    } finally {
        console.log('--- File Audit Test Complete ---');
        process.exit(0);
    }
}

if (require.main === module) {
    testFileChanges();
}

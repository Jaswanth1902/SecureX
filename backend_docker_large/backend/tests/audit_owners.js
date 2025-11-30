const db = require('../database');

async function testOwnerChanges() {
    console.log('--- Starting Owner Audit Test ---');

    const testEmail = `owner_audit_${Date.now()}@example.com`;

    try {
        // 1. INSERT
        console.log('Performing INSERT (Owner Registration)...');
        const insertRes = await db.query(
            'INSERT INTO owners (email, password_hash, full_name, public_key) VALUES ($1, $2, $3, $4) RETURNING *',
            [testEmail, 'hash_123', 'Test Owner Shop', '-----BEGIN PUBLIC KEY-----\nMOCK_KEY\n-----END PUBLIC KEY-----']
        );
        const newOwner = insertRes.rows[0];
        console.log('Change Logged: Owner Registered');
        console.log('Owner ID:', newOwner.id);

        // 2. UPDATE (Change Public Key - rare but possible)
        console.log('Performing UPDATE (Rotate Key)...');
        const updateRes = await db.query(
            'UPDATE owners SET public_key = $1 WHERE id = $2 RETURNING *',
            ['-----BEGIN PUBLIC KEY-----\nNEW_MOCK_KEY\n-----END PUBLIC KEY-----', newOwner.id]
        );
        console.log('Change Logged: Public Key Rotated');
        console.log('New Key:', updateRes.rows[0].public_key);

        // Cleanup
        await db.query('DELETE FROM owners WHERE id = $1', [newOwner.id]);
        console.log('Cleanup Complete');

    } catch (err) {
        console.error('Test Failed:', err);
    } finally {
        console.log('--- Owner Audit Test Complete ---');
        process.exit(0);
    }
}

if (require.main === module) {
    testOwnerChanges();
}

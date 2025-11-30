const db = require('../database');
const { v4: uuidv4 } = require('uuid');

async function testUserChanges() {
  console.log('--- Starting User Audit Test ---');
  
  const testEmail = `audit_test_${Date.now()}@example.com`;
  const testPasswordHash = 'hashed_secret';
  
  try {
    // 1. Initial State
    console.log(`Checking if user ${testEmail} exists...`);
    const check1 = await db.query('SELECT * FROM users WHERE email = $1', [testEmail]);
    console.log('Initial State:', check1.rows.length ? 'User exists' : 'User does not exist');

    // 2. INSERT (Change 1)
    console.log('Performing INSERT...');
    const insertRes = await db.query(
      'INSERT INTO users (email, password_hash, full_name) VALUES ($1, $2, $3) RETURNING *',
      [testEmail, testPasswordHash, 'Audit Test User']
    );
    const newUser = insertRes.rows[0];
    console.log('Change Logged: User Created');
    console.log('New Record:', JSON.stringify(newUser, null, 2));

    // 3. UPDATE (Change 2)
    console.log('Performing UPDATE (Changing name)...');
    const updateRes = await db.query(
      'UPDATE users SET full_name = $1 WHERE email = $2 RETURNING *',
      ['Updated Audit Name', testEmail]
    );
    const updatedUser = updateRes.rows[0];
    console.log('Change Logged: User Updated');
    console.log('Old Name:', newUser.full_name);
    console.log('New Name:', updatedUser.full_name);

    // 4. DELETE (Change 3) - Cleanup
    console.log('Performing DELETE...');
    await db.query('DELETE FROM users WHERE email = $1', [testEmail]);
    console.log('Change Logged: User Deleted');

  } catch (err) {
    console.error('Test Failed:', err);
  } finally {
    // Close pool if running standalone, or let the main process handle it
    // db.pool.end(); 
    console.log('--- User Audit Test Complete ---');
    process.exit(0);
  }
}

if (require.main === module) {
  testUserChanges();
}

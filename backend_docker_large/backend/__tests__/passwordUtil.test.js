const { hashPassword, verifyPassword } = require('../utils/passwordUtil');

describe('passwordUtil', () => {
  test('hash and verify password', async () => {
    const pw = 'Str0ng!Passw0rd';
    const hash = await hashPassword(pw);
    expect(typeof hash).toBe('string');
    expect(hash.length).toBeGreaterThan(0);

    const ok = await verifyPassword(pw, hash);
    expect(ok).toBe(true);

    const bad = await verifyPassword('wrong', hash);
    expect(bad).toBe(false);
  });

  test('different hashes for same password due to salt', async () => {
    const pw = 'Repeat1!';
    const h1 = await hashPassword(pw);
    const h2 = await hashPassword(pw);
    expect(h1).not.toEqual(h2);
    expect(await verifyPassword(pw, h1)).toBe(true);
    expect(await verifyPassword(pw, h2)).toBe(true);
  });

  test('reject invalid inputs', async () => {
    await expect(hashPassword('')).rejects.toThrow();
    await expect(hashPassword(null)).rejects.toThrow();
    expect(await verifyPassword('', '$2a$10$something')).toBe(false);
    expect(await verifyPassword('pw', '')).toBe(false);
  });
});

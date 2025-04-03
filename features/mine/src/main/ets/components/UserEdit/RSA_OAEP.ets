import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer, util } from '@kit.ArkTS';

const public_key_str: string = `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvDRwhDp6AjGilP37XRmU
p4V7KVFhwcNL80VokzW9CK9jGCC/+UTPi75MN26cY+sRAujnU+ilqmd/c9LOVjSw
6JlqONZgwFwCewbHsiiDSbUpQ0HlEYxYQ/mOb3PNVPz3BZWYV+KiesN07jVttyad
+T4tCFW/ArSDlhAir8bjDNPKm4VZBAIr8cEf//wxBcnoheww4zAvdbsQydUch7qb
nnizcR06ifBTQSeDV9uskfKP6pwzWIvNEo0gbUpTU4W1jkRtzPqY9MKxVqupE4uu
fW5ZafC2+dxQ64LneL1GIwzHnl5uQILxbnSFBcVb0x/Dbm6/ijOqYjkpgtXhmTWk
LQIDAQAB
-----END PUBLIC KEY-----
`

export function RSA_OAEP_ENCRYPT(plan: string): string {
  try {
    const asyKeyGenerator = cryptoFramework.createAsyKeyGenerator('RSA1024')
    const keyPairData = asyKeyGenerator.convertPemKeySync(public_key_str, null)
    if (keyPairData === null) {
      throw new Error('convert pem key pair result fail!')
    }
    const cipher = cryptoFramework.createCipher("RSA|PKCS1_OAEP|SHA256|MGF1_SHA256");
    cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, keyPairData.pubKey, null)
    const input: cryptoFramework.DataBlob = { data: new Uint8Array(buffer.from(plan, 'utf-8').buffer) }
    const cipherDataBlob = cipher.doFinalSync(input)
    return new util.Base64Helper().encodeToStringSync(cipherDataBlob.data)
  } catch (e) {
    console.error(`Sync error, ${e.code}, ${e.message}`)
    return ''
  }
}
class window.Crypto
  @RANDOM_STRING = "WNHx8qMKqooe6L796Dsm"

  @PBKDF2 = (pass, convert_to_string = false) ->
      [0..2000].forEach(=> pass = sjcl.hash.sha256.hash(pass + @RANDOM_STRING))
      return "" + pass if convert_to_string
      pass

  # encrypts the plaintext with the master data key
  @encrypt = (plaintext, nakedPass, salt) =>
    key = @PBKDF2(nakedPass + @RANDOM_STRING + salt)
    p = {}
    p.adata = ""
    p.iter = 1000
    p.ks = 128
    p.mode = "ccm"
    p.ts = 64
    rp = {}
    sjcl.encrypt(key, plaintext, p,rp)

  # decrypts the ciphertext with the master data key
  @decrypt = (ciphertext, nakedPass, salt, iv) ->
    key = @PBKDF2(nakedPass + @RANDOM_STRING + salt)
    data = JSON.stringify( ct: ciphertext, iv: iv )
    sjcl.decrypt(key, data, {}, {})

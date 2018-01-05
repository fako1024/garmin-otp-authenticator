using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;

// Implementation of TOTP: Time-Based One-Time Password Algorithm
// rfc6238 https://tools.ietf.org/html/rfc6238

// Notes:
//  * T0 is defaulted to Unix Epoch

function totp(key, x, digit) {
  var t = Time.now().value() / x;
  return hotp(key, t, digit);
}

// Implementation of HOTP: An HMAC-Based One-Time Password Algorithm
// rfc2104 https://tools.ietf.org/html/rfc4226

// Notes:
// * Max digit is 9 to stay in range of signed 32bit Number where 6 digits is common.

function hotp(key, counter, digit) {
  if (digit > 9) {
    digit = 9;
  }
  var data = new [8];
  for (var i = data.size() - 1; i >= 0; i--) {
    data[i] = counter & 0xff;
    counter = counter >> 8;
  }
  var h = hmacSHA1(key, data);
  var t = truncate(h);
  var n = t % DIGITS[digit];
  var code = n.toString();
  while (code.length() < digit) {
    code = "0" + code;
  }
  return code;
}

const DIGITS = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000];

function truncate(bytes) {
  if (bytes.size() != 20) {
    throw new Lang.UnexpectedTypeException();
  }
  // Offset is the low-order 4 bits of the byte at 19
  var offset = bytes[19] & 0xf;
  // Return the last 31 bits of the 4-byte word at offset
  return (bytes[offset] & 0x7f) << 24
    | (bytes[offset+1] & 0xff) << 16
    | (bytes[offset+2] & 0xff) << 8
    | (bytes[offset+3] & 0xff);

}
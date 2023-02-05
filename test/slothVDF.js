const bexmod = (base, exponent, modulus) => {
    let result = 1n;
    for (; exponent > 0n; exponent >>= 1n) {
      if (exponent & 1n) {
        result = (result * base) % modulus;
      }
      base = (base * base) % modulus;
    }
    return result;
  };
   
  const sloth = {
    compute(seed, prime, iterations) {
      const exponent = (prime + 1n) >> 2n;
      let beacon = seed % prime;
      for (let i = 0n; i < iterations; ++i) {
        beacon = bexmod(beacon, exponent, prime);
      }
      return beacon;
    },
    verify(beacon, seed, prime, iterations) {
      for (let i = 0n; i < iterations; ++i) {
        beacon = (beacon * beacon) % prime;
      }
      seed %= prime;
      if (seed == beacon) return true;
      if (prime - seed === beacon) return true;
      return false;
    },
  };
   
 module.exports.sloth = sloth;
with Interfaces;

package Hash_Functions is

   -- Strong typing for algorithm-specific data
   type Hash_32 is mod 2**32;
   type Hash_8  is mod 2**8;

   -- Exception for invalid inputs
   Hash_Error : exception;

   -- ==========================================
   -- Integer Hashing Variants
   -- ==========================================
   
   -- 1. Trivial / Identity Hash: Maps a key to itself (useful for small, unique integers)
   function Identity_Hash (Key : Hash_32) return Hash_32;

   -- 2. Division Hash (Modulo): Maps a key into a fixed range [0, M-1]
   function Division_Hash (Key : Hash_32; M : Hash_32) return Hash_32;

   -- 3. Mid-Square Hash: Squares the key and extracts the middle digits
   function Mid_Square_Hash (Key : Hash_32) return Hash_32;

   -- ==========================================
   -- String Hashing Variants
   -- ==========================================

   -- 4. DJB2 Hash: A fast string hashing algorithm by Dan Bernstein
   function DJB2_Hash (Key : String) return Hash_32;

   -- 5. FNV-1a Hash: Fowler–Noll–Vo non-cryptographic hash function
   function FNV_1A_Hash (Key : String) return Hash_32;

   -- 6. Pearson Hash: 8-bit hash utilizing a permutation table (good for small microcontrollers)
   function Pearson_Hash (Key : String) return Hash_8;

   -- 7. Folding Hash: Divides strings into 4-byte chunks and adds them together
   function Folding_Hash (Key : String) return Hash_32;

private
   -- Permutation table for Pearson Hash (0..255 randomized)
   Pearson_Table : constant array (Hash_8) of Hash_8 :=
     ( 98,  6, 85,150, 36, 23,112,164,135,207,169,  5, 26, 64,165,219,
       61, 20, 68, 89,130, 63, 52,102, 24,229,132,245, 80,216,195,115,
       90,168,156,203,177,120, 71,215,208, 27,166,174,227, 46,233,111,
      144, 99,  2,176,143,214,244, 22,104,189,253, 51,145,211,146, 55,
      138,206, 92,222, 19, 78,210,133,230,173,153,101,235,251,200, 11,
       41, 75,178,237, 50,225, 43, 76,231,185,108,187,249, 13, 86,113,
      158,197, 66,220, 21, 58,247, 56,128, 48,157, 10,192, 16, 73,121,
      242, 70,224,196,117,148,228,103,190, 83, 30, 47,159, 15,246, 17,
      109,232,201,167,110,199,209,254,186, 31, 25, 33,239,122,179,152,
      198,140, 53,  0,154, 42, 60,118,226,105, 35, 77, 65, 84, 88,100,
       18,212, 12,240, 40,250, 74, 95, 39,191,127,243, 38, 14, 57,170,
       44,213,248, 82, 94, 69, 72,139,183, 81,180, 29,184, 79,252,147,
       37, 93, 28,151,202,234,181,114,136,172,125,238, 34,221,123, 91,
       67,163, 62,236,131,217, 87, 49,204,116, 32, 97, 45, 96,119,161,
      126,205, 59,188,149,162, 54,134,171,194,155,255,223,175,142,  4,
      193,124,137,218,  3,  1,141,129,  9,  7,160, 8, 107,241,106,182 );
end Hash_Functions;

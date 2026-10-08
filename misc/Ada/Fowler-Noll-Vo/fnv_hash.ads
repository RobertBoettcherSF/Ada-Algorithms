-- fnv_hash.ads
with Interfaces; use Interfaces;

package FNV_Hash is
   -- FNV-1 32-bit constants
   FNV_Offset_Basis_32 : constant Unsigned_32 := 16#811c9dc5#;
   FNV_Prime_32        : constant Unsigned_32 := 16#01000193#;

   -- FNV-1 64-bit constants
   FNV_Offset_Basis_64 : constant Unsigned_64 := 16#cbf29ce484222325#;
   FNV_Prime_64        : constant Unsigned_64 := 16#100000001b3#;

   -- Function declarations
   function Hash_FNV1_32 (Data : String) return Unsigned_32;
   function Hash_FNV1a_32 (Data : String) return Unsigned_32;
   function Hash_FNV1_64 (Data : String) return Unsigned_64;
   function Hash_FNV1a_64 (Data : String) return Unsigned_64;

end FNV_Hash;

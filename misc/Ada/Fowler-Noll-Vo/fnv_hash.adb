-- fnv_hash.adb
with Ada.Characters.Latin_1;

package body FNV_Hash is

   function Hash_FNV1_32 (Data : String) return Unsigned_32 is
      Hash : Unsigned_32 := FNV_Offset_Basis_32;
   begin
      for C of Data loop
         Hash := Hash * FNV_Prime_32;
         Hash := Hash xor Unsigned_32(Character'Pos(C));
      end loop;
      return Hash;
   end Hash_FNV1_32;

   function Hash_FNV1a_32 (Data : String) return Unsigned_32 is
      Hash : Unsigned_32 := FNV_Offset_Basis_32;
   begin
      for C of Data loop
         Hash := Hash xor Unsigned_32(Character'Pos(C));
         Hash := Hash * FNV_Prime_32;
      end loop;
      return Hash;
   end Hash_FNV1a_32;

   function Hash_FNV1_64 (Data : String) return Unsigned_64 is
      Hash : Unsigned_64 := FNV_Offset_Basis_64;
   begin
      for C of Data loop
         Hash := Hash * FNV_Prime_64;
         Hash := Hash xor Unsigned_64(Character'Pos(C));
      end loop;
      return Hash;
   end Hash_FNV1_64;

   function Hash_FNV1a_64 (Data : String) return Unsigned_64 is
      Hash : Unsigned_64 := FNV_Offset_Basis_64;
   begin
      for C of Data loop
         Hash := Hash xor Unsigned_64(Character'Pos(C));
         Hash := Hash * FNV_Prime_64;
      end loop;
      return Hash;
   end Hash_FNV1a_64;

end FNV_Hash;

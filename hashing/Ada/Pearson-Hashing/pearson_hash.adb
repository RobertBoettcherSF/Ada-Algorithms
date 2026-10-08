-- pearson_hash.adb
package body Pearson_Hash is

   function Hash (Input : String; Table : Permutation_Table := Default_Table) return Unsigned_8 is
      H : Unsigned_8 := 0;
   begin
      -- Standard Pearson Hashing Algorithm
      -- h := T[h XOR c]
      for I in Input'Range loop
         H := Table(H xor Unsigned_8(Character'Pos(Input(I))));
      end loop;
      return H;
   end Hash;

   function Hash (Input : Byte_Array; Table : Permutation_Table := Default_Table) return Unsigned_8 is
      H : Unsigned_8 := 0;
   begin
      for I in Input'Range loop
         H := Table(H xor Input(I));
      end loop;
      return H;
   end Hash;

end Pearson_Hash;

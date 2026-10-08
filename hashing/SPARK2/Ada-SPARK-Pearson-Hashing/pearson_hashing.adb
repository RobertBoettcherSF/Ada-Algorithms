pragma Ada_2022;
package body Pearson_Hashing
  with SPARK_Mode => On
is
   type Table is array (Hash_Value) of Hash_Value;
   Permutation : constant Table :=
     [0 => 9, 1 => 4, 2 => 14, 3 => 1, 4 => 12, 5 => 7, 6 => 0, 7 => 10,
      8 => 3, 9 => 15, 10 => 6, 11 => 13, 12 => 5, 13 => 2, 14 => 11, 15 => 8];

   function Hash (Text : Char_Array) return Hash_Value is
      H : Hash_Value := 0;
   begin
      for I in Text'Range loop
         H := Permutation ((H + Character'Pos (Text (I))) mod Table_Size);
      end loop;
      return H;
   end Hash;
end Pearson_Hashing;

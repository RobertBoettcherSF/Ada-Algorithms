pragma Ada_2022;
package body Zobrist_Hashing
  with SPARK_Mode => On
is
   subtype Pos_Index is Natural range 0 .. Max_Len - 1;

   function Key (Position : Pos_Index; C : Character) return Hash_Value
     with Global => null
   is
   begin
      return Hash_Value (Position + 1) * 16#9E3779B1#
        + Hash_Value (Character'Pos (C) + 1) * 16#85EBCA6B#;
   end Key;

   function Hash (Text : Char_Array) return Hash_Value is
      H : Hash_Value := 0;
   begin
      for I in Text'Range loop
         H := H xor Key (Pos_Index (I - 1), Text (I));
      end loop;
      return H;
   end Hash;
end Zobrist_Hashing;

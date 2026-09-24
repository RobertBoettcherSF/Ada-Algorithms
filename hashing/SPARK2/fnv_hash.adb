pragma Ada_2022;
package body FNV_Hash
  with SPARK_Mode => On
is
   Offset_Basis : constant Hash_Value := 2_166_136_261;
   FNV_Prime : constant Hash_Value := 16_777_619;

   function Hash (Text : Char_Array) return Hash_Value is
      H : Hash_Value := Offset_Basis;
   begin
      for I in Text'Range loop
         H := (H xor Hash_Value (Character'Pos (Text (I)))) * FNV_Prime;
      end loop;
      return H;
   end Hash;
end FNV_Hash;

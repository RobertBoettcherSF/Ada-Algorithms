pragma Ada_2022;
package body Hamming_Code with SPARK_Mode => On is
   use type Interfaces.Unsigned_8;

   function Encode (Data : Nibble) return Codeword is
      D1 : constant Interfaces.Unsigned_8 := Data and 1;
      D2 : constant Interfaces.Unsigned_8 := Interfaces.Shift_Right (Data, 1) and 1;
      D3 : constant Interfaces.Unsigned_8 := Interfaces.Shift_Right (Data, 2) and 1;
      D4 : constant Interfaces.Unsigned_8 := Interfaces.Shift_Right (Data, 3) and 1;
      P1 : constant Interfaces.Unsigned_8 := D1 xor D2 xor D4;
      P2 : constant Interfaces.Unsigned_8 := D1 xor D3 xor D4;
      P4 : constant Interfaces.Unsigned_8 := D2 xor D3 xor D4;
   begin
      return P1 or Interfaces.Shift_Left (P2, 1) or
        Interfaces.Shift_Left (D1, 2) or Interfaces.Shift_Left (P4, 3) or
        Interfaces.Shift_Left (D2, 4) or Interfaces.Shift_Left (D3, 5) or
        Interfaces.Shift_Left (D4, 6);
   end Encode;

   function Decode (Code : Codeword) return Nibble is
      D1 : constant Interfaces.Unsigned_8 := Interfaces.Shift_Right (Code, 2) and 1;
      D2 : constant Interfaces.Unsigned_8 := Interfaces.Shift_Right (Code, 4) and 1;
      D3 : constant Interfaces.Unsigned_8 := Interfaces.Shift_Right (Code, 5) and 1;
      D4 : constant Interfaces.Unsigned_8 := Interfaces.Shift_Right (Code, 6) and 1;
   begin
      return D1 or Interfaces.Shift_Left (D2, 1) or
        Interfaces.Shift_Left (D3, 2) or Interfaces.Shift_Left (D4, 3);
   end Decode;
end Hamming_Code;

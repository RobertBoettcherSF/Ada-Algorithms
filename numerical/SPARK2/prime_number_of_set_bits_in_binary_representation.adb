pragma Ada_2022;
with Interfaces;
package body Prime_Number_Of_Set_Bits_In_Binary_Representation with SPARK_Mode => On is
   use type Word;
   function Count_Bits (Value : Word) return Word is
      V : Word := Value;
   begin
      V := V - (Interfaces.Shift_Right (V, 1) and 16#5555_5555#);
      V := (V and 16#3333_3333#) + (Interfaces.Shift_Right (V, 2) and 16#3333_3333#);
      V := (V + Interfaces.Shift_Right (V, 4)) and 16#0F0F_0F0F#;
      V := V + Interfaces.Shift_Right (V, 8);
      V := V + Interfaces.Shift_Right (V, 16);
      return V and 16#3F#;
   end Count_Bits;

   function Has_Prime_Set_Bit_Count (Value : Word) return Boolean is
      Count : constant Word := Count_Bits (Value);
   begin
      return Count = 2 or else Count = 3 or else Count = 5 or else Count = 7
        or else Count = 11 or else Count = 13 or else Count = 17
        or else Count = 19 or else Count = 23 or else Count = 29
        or else Count = 31;
   end Has_Prime_Set_Bit_Count;
end Prime_Number_Of_Set_Bits_In_Binary_Representation;

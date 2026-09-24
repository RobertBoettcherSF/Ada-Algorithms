pragma Ada_2022;
with Interfaces;
package body Sort_Integers_By_The_Number_Of_1_Bits with SPARK_Mode => On is
   use type Word;
   function Bit_Count (Value : Word) return Word is
      V : Word := Value;
   begin
      V := V - (Interfaces.Shift_Right (V, 1) and 16#5555_5555#);
      V := (V and 16#3333_3333#) + (Interfaces.Shift_Right (V, 2) and 16#3333_3333#);
      V := (V + Interfaces.Shift_Right (V, 4)) and 16#0F0F_0F0F#;
      V := V + Interfaces.Shift_Right (V, 8);
      V := V + Interfaces.Shift_Right (V, 16);
      return V and 16#3F#;
   end Bit_Count;
end Sort_Integers_By_The_Number_Of_1_Bits;

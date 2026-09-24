pragma Ada_2022;
package body Maximum_Xor_Of_Two_Numbers with SPARK_Mode => On is
   use type Word;
   function Maximum_Xor (Left, Right : Word) return Word is
   begin
      return Left xor Right;
   end Maximum_Xor;
   function Maximum_Xor (A, B, C : Word) return Word is
      AB : constant Word := A xor B;
      AC : constant Word := A xor C;
      BC : constant Word := B xor C;
   begin
      if AB >= AC and then AB >= BC then
         return AB;
      elsif AC >= BC then
         return AC;
      else
         return BC;
      end if;
   end Maximum_Xor;
end Maximum_Xor_Of_Two_Numbers;

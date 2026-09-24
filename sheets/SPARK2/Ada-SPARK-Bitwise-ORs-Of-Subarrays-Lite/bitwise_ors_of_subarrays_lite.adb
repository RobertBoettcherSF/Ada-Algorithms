pragma Ada_2022;
package body Bitwise_Ors_Of_Subarrays_Lite with SPARK_Mode => On is
   use type Word;
   function Or_Of_Two (Left, Right : Word) return Word is
   begin
      return Left or Right;
   end Or_Of_Two;
   function Or_Of_Three (A, B, C : Word) return Word is
   begin
      return A or B or C;
   end Or_Of_Three;
end Bitwise_Ors_Of_Subarrays_Lite;

pragma Ada_2022;
package body Sum_Of_Two_Integers with SPARK_Mode => On is
   function Add (Left, Right : Input) return Sum is
   begin
      return Left + Right;
   end Add;
end Sum_Of_Two_Integers;

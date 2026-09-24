pragma SPARK_Mode (On);

package Edit_Distance is
   subtype Length is Natural range 0 .. 4;
   subtype Symbol is Natural range 0 .. 25;
   type Word is array (Positive range 1 .. 4) of Symbol;

   function Distance
     (Left, Right : Word;
      Left_Length, Right_Length : Length) return Length
     with Global => null;
end Edit_Distance;

pragma Ada_2022;

package body Count_And_Say with SPARK_Mode => On is
   function First_Run (Input : Digit_Array) return Run is
   begin
      if Input (2) /= Input (1) then
         return (Count => 1, Value => Input (1));
      elsif Input (3) /= Input (1) then
         return (Count => 2, Value => Input (1));
      elsif Input (4) /= Input (1) then
         return (Count => 3, Value => Input (1));
      elsif Input (5) /= Input (1) then
         return (Count => 4, Value => Input (1));
      elsif Input (6) /= Input (1) then
         return (Count => 5, Value => Input (1));
      else
         return (Count => 6, Value => Input (1));
      end if;
   end First_Run;
end Count_And_Say;

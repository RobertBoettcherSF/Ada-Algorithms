pragma Ada_2022;

package body Single_Number with SPARK_Mode => On is
   function Find (Input : Input_Array) return Value is
   begin
      if Input (1) /= Input (2) and then Input (1) /= Input (3)
        and then Input (1) /= Input (4) and then Input (1) /= Input (5)
      then
         return Input (1);
      elsif Input (2) /= Input (1) and then Input (2) /= Input (3)
        and then Input (2) /= Input (4) and then Input (2) /= Input (5)
      then
         return Input (2);
      elsif Input (3) /= Input (1) and then Input (3) /= Input (2)
        and then Input (3) /= Input (4) and then Input (3) /= Input (5)
      then
         return Input (3);
      elsif Input (4) /= Input (1) and then Input (4) /= Input (2)
        and then Input (4) /= Input (3) and then Input (4) /= Input (5)
      then
         return Input (4);
      else
         return Input (5);
      end if;
   end Find;
end Single_Number;

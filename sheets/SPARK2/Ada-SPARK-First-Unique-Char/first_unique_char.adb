pragma Ada_2022;

package body First_Unique_Char with SPARK_Mode => On is
   function Find (Input : Text_Array) return Result_Index is
   begin
      if Input (1) /= Input (2) and then Input (1) /= Input (3)
        and then Input (1) /= Input (4) and then Input (1) /= Input (5)
        and then Input (1) /= Input (6)
      then
         return 1;
      elsif Input (2) /= Input (1) and then Input (2) /= Input (3)
        and then Input (2) /= Input (4) and then Input (2) /= Input (5)
        and then Input (2) /= Input (6)
      then
         return 2;
      elsif Input (3) /= Input (1) and then Input (3) /= Input (2)
        and then Input (3) /= Input (4) and then Input (3) /= Input (5)
        and then Input (3) /= Input (6)
      then
         return 3;
      elsif Input (4) /= Input (1) and then Input (4) /= Input (2)
        and then Input (4) /= Input (3) and then Input (4) /= Input (5)
        and then Input (4) /= Input (6)
      then
         return 4;
      elsif Input (5) /= Input (1) and then Input (5) /= Input (2)
        and then Input (5) /= Input (3) and then Input (5) /= Input (4)
        and then Input (5) /= Input (6)
      then
         return 5;
      elsif Input (6) /= Input (1) and then Input (6) /= Input (2)
        and then Input (6) /= Input (3) and then Input (6) /= Input (4)
        and then Input (6) /= Input (5)
      then
         return 6;
      else
         return 0;
      end if;
   end Find;
end First_Unique_Char;

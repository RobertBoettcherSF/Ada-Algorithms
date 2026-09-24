pragma Ada_2022;

package body Longest_Palindromic_Substring with SPARK_Mode => On is
   function Is_Pal_2 (Input : Text_Array; Start : Start_2) return Boolean is
   begin
      return Input (Start) = Input (Start + 1);
   end Is_Pal_2;

   function Is_Pal_3 (Input : Text_Array; Start : Start_3) return Boolean is
   begin
      return Input (Start) = Input (Start + 2);
   end Is_Pal_3;

   function Is_Pal_4 (Input : Text_Array; Start : Start_4) return Boolean is
   begin
      return Input (Start) = Input (Start + 3)
        and then Input (Start + 1) = Input (Start + 2);
   end Is_Pal_4;

   function Is_Pal_5 (Input : Text_Array; Start : Start_5) return Boolean is
   begin
      return Input (Start) = Input (Start + 4)
        and then Input (Start + 1) = Input (Start + 3);
   end Is_Pal_5;

   function Is_Pal_6 (Input : Text_Array; Start : Start_6) return Boolean is
   begin
      return Input (Start) = Input (Start + 5)
        and then Input (Start + 1) = Input (Start + 4)
        and then Input (Start + 2) = Input (Start + 3);
   end Is_Pal_6;

   function Longest_Length (Input : Text_Array) return Answer_Length is
   begin
      if Input (1) = Input (7)
        and then Input (2) = Input (6)
        and then Input (3) = Input (5)
      then
         return 7;
      elsif Is_Pal_6 (Input, 1) or else Is_Pal_6 (Input, 2) then
         return 6;
      elsif Is_Pal_5 (Input, 1) or else Is_Pal_5 (Input, 2)
        or else Is_Pal_5 (Input, 3)
      then
         return 5;
      elsif Is_Pal_4 (Input, 1) or else Is_Pal_4 (Input, 2)
        or else Is_Pal_4 (Input, 3) or else Is_Pal_4 (Input, 4)
      then
         return 4;
      elsif Is_Pal_3 (Input, 1) or else Is_Pal_3 (Input, 2)
        or else Is_Pal_3 (Input, 3) or else Is_Pal_3 (Input, 4)
        or else Is_Pal_3 (Input, 5)
      then
         return 3;
      elsif Is_Pal_2 (Input, 1) or else Is_Pal_2 (Input, 2)
        or else Is_Pal_2 (Input, 3) or else Is_Pal_2 (Input, 4)
        or else Is_Pal_2 (Input, 5) or else Is_Pal_2 (Input, 6)
      then
         return 2;
      else
         return 1;
      end if;
   end Longest_Length;
end Longest_Palindromic_Substring;

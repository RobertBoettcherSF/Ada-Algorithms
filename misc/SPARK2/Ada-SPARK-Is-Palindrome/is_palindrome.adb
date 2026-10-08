pragma Ada_2022;

package body Is_Palindrome with SPARK_Mode => On is
   function Check (Input : Text_Array) return Boolean is
   begin
      return Input (1) = Input (7)
        and then Input (2) = Input (6)
        and then Input (3) = Input (5);
   end Check;
end Is_Palindrome;

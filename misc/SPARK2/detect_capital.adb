pragma Ada_2022;

package body Detect_Capital with SPARK_Mode => On is
   function Is_Correct (Input : Text_Array) return Boolean is
      All_Upper : constant Boolean :=
        Input (1) in 'A' .. 'Z' and then Input (2) in 'A' .. 'Z'
        and then Input (3) in 'A' .. 'Z' and then Input (4) in 'A' .. 'Z'
        and then Input (5) in 'A' .. 'Z' and then Input (6) in 'A' .. 'Z';
      All_Lower : constant Boolean :=
        Input (1) in 'a' .. 'z' and then Input (2) in 'a' .. 'z'
        and then Input (3) in 'a' .. 'z' and then Input (4) in 'a' .. 'z'
        and then Input (5) in 'a' .. 'z' and then Input (6) in 'a' .. 'z';
      Title_Case : constant Boolean :=
        Input (1) in 'A' .. 'Z' and then Input (2) in 'a' .. 'z'
        and then Input (3) in 'a' .. 'z' and then Input (4) in 'a' .. 'z'
        and then Input (5) in 'a' .. 'z' and then Input (6) in 'a' .. 'z';
   begin
      return All_Upper or else All_Lower or else Title_Case;
   end Is_Correct;
end Detect_Capital;

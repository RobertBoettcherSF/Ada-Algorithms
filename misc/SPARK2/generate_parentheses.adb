pragma Ada_2022;

package body Generate_Parentheses with SPARK_Mode => On is
   function Generate_First return Paren_Array is
   begin
      return "((()))";
   end Generate_First;
end Generate_Parentheses;

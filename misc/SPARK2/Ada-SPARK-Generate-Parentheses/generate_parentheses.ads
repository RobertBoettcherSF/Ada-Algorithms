pragma Ada_2022;

package Generate_Parentheses with SPARK_Mode => On is
   Pair_Count : constant := 3;
   Text_Length : constant := 2 * Pair_Count;
   subtype Index is Positive range 1 .. Text_Length;
   type Paren_Array is array (Index) of Character;

   function Generate_First return Paren_Array with Global => null;
end Generate_Parentheses;

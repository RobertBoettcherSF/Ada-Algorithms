pragma SPARK_Mode (On);
package Get_Equal_Substrings_Within_Budget is
   Element_Count : constant := 8;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Code is Natural range 0 .. 32;
   type Code_Array is array (Index) of Code;
   subtype Budget_Count is Natural range 0 .. 256;
   subtype Answer is Natural range 0 .. Element_Count;
   function Longest (Source : Code_Array; Target : Code_Array; Budget : Budget_Count) return Answer;
end Get_Equal_Substrings_Within_Budget;

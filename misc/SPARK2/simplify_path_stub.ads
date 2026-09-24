pragma SPARK_Mode (On);

package Simplify_Path_Stub is
   Max_Tokens : constant := 8;
   subtype Depth is Natural range 0 .. Max_Tokens;
   type Token is (Root, Current, Parent, Name);
   subtype Token_Index is Positive range 1 .. Max_Tokens;
   type Token_Array is array (Token_Index) of Token;

   function Simplified_Depth (Tokens : Token_Array) return Depth
     with Global => null;
end Simplify_Path_Stub;

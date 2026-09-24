pragma SPARK_Mode (On);

package Reorganize_String is
   Symbol_Count : constant := 8;
   subtype Symbol is Natural range 0 .. 3;
   type Symbol_Array is array (Positive range 1 .. Symbol_Count) of Symbol;

   function Can_Reorganize (Symbols : Symbol_Array) return Boolean;
end Reorganize_String;

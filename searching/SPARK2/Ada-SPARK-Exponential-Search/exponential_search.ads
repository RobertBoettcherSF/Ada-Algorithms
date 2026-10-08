pragma Ada_2022;
package Exponential_Search with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Index is Positive range 1 .. Capacity;
   subtype Search_Result is Natural range 0 .. Capacity;
   subtype Element is Integer range 0 .. 1_000;
   type Data is array (Index) of Element;

   function Search (A : Data; Target : Element) return Search_Result;
end Exponential_Search;

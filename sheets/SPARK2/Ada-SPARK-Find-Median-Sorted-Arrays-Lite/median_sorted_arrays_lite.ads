pragma Ada_2022;
package Median_Sorted_Arrays_Lite with SPARK_Mode => On is
   Capacity : constant := 32;
   subtype Length is Natural range 0 .. Capacity;
   subtype Index is Positive range 1 .. Capacity;
   subtype Value is Integer range -1000 .. 1000;
   type Values is array (Index) of Value;
   function Median (A : Values; NA : Length; B : Values; NB : Length) return Integer
     with Pre => NA + NB > 0;
end Median_Sorted_Arrays_Lite;

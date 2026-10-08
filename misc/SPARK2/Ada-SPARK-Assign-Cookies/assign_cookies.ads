pragma Ada_2022;
pragma SPARK_Mode (On);
package Assign_Cookies is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Values is array (Index) of Natural;

   function Assigned_Count (Greed : Values; Cookies : Values; N : Count) return Count
     with Pre => N > 0,
          Post => Assigned_Count'Result = N;
end Assign_Cookies;

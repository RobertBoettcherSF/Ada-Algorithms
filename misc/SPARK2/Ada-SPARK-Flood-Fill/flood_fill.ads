pragma Ada_2022;
package Flood_Fill with SPARK_Mode => On is
   Capacity : constant := 2;
   subtype Index is Positive range 1 .. Capacity;
   subtype Value is Integer range 0 .. 9;
   type Grid is array (Index, Index) of Value;
   procedure Fill (G : in out Grid; Row, Col : Index; New_Value : Value);
end Flood_Fill;

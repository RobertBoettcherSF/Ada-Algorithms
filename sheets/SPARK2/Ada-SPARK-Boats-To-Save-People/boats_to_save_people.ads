pragma Ada_2022;
package Boats_To_Save_People with SPARK_Mode => On is
   subtype People_Count is Natural range 0 .. 32;
   subtype Boat_Capacity is People_Count range 1 .. 32;
   subtype Boat_Count is Natural range 0 .. 33;

   function Boats_Needed
     (People : People_Count; Capacity : Boat_Capacity) return Boat_Count
     with Global => null;
end Boats_To_Save_People;

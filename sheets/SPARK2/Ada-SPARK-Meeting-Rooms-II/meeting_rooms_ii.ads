pragma Ada_2022;
package Meeting_Rooms_II with SPARK_Mode => On is
   subtype Room_Count is Natural range 0 .. 32;

   function Required_Rooms (First_Group, Second_Group : Room_Count)
     return Room_Count
     with Global => null;
end Meeting_Rooms_II;

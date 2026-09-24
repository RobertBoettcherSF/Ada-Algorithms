pragma Ada_2022;
package body Meeting_Rooms_II with SPARK_Mode => On is
   function Required_Rooms (First_Group, Second_Group : Room_Count)
     return Room_Count is
   begin
      if First_Group >= Second_Group then
         return First_Group;
      else
         return Second_Group;
      end if;
   end Required_Rooms;
end Meeting_Rooms_II;

pragma Ada_2022;
package body Meeting_Rooms with SPARK_Mode => On is
   function Non_Overlapping
     (First_Start, First_End, Second_Start, Second_End : Time) return Boolean is
   begin
      return First_End <= Second_Start or else Second_End <= First_Start;
   end Non_Overlapping;
end Meeting_Rooms;

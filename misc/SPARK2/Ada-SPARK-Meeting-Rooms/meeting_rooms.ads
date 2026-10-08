pragma Ada_2022;
package Meeting_Rooms with SPARK_Mode => On is
   subtype Time is Natural range 0 .. 32;

   function Non_Overlapping
     (First_Start, First_End, Second_Start, Second_End : Time) return Boolean
     with Global => null,
          Pre => First_Start <= First_End and then Second_Start <= Second_End;
end Meeting_Rooms;

pragma Ada_2022;
package Partition_Labels with SPARK_Mode => On is
   subtype Position is Natural range 0 .. 32;
   subtype Partition_Length is Natural range 0 .. 33;

   function Length_Of (First_Position, Last_Position : Position)
     return Partition_Length
     with Global => null,
          Pre => First_Position <= Last_Position;
end Partition_Labels;

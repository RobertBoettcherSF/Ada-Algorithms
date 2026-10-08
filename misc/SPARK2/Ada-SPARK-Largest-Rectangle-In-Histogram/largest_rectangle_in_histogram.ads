pragma Ada_2022;

package Largest_Rectangle_In_Histogram with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Height is Natural range 0 .. 32;
   subtype Area is Natural range 0 .. 1_024;
   type Heights is array (Index) of Height;

   function Max_Area (H : Heights; Length : Length_Type) return Area
     with Global => null;
end Largest_Rectangle_In_Histogram;

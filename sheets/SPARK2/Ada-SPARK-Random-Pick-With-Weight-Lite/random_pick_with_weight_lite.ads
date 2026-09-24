pragma Ada_2022;

package Random_Pick_With_Weight_Lite with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Weight is Positive range 1 .. 100;
   subtype Ticket is Positive range 1 .. 800;
   type Weight_Array is array (Index) of Weight;

   function Pick (Weights : Weight_Array; Draw : Ticket) return Index
     with Global => null;
end Random_Pick_With_Weight_Lite;

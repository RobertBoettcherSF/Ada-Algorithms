pragma SPARK_Mode (On);

package Redundant_Connection_II with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Edge_Index is Positive range 1 .. Capacity;
   type Edge is record
      From : Edge_Index;
      To : Edge_Index;
   end record;
   type Edge_List is array (Edge_Index) of Edge;

   function Has_Redundant_Edge
     (Edges : Edge_List; N : Edge_Index) return Boolean
     with Global => null;
end Redundant_Connection_II;

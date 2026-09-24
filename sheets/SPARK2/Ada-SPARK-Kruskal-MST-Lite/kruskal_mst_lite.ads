pragma SPARK_Mode (On);

package Kruskal_MST_Lite with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Edge_Count is Natural range 0 .. Capacity;
   subtype Weight is Natural range 0 .. Capacity;
   type Edge is record
      From, To : Positive range 1 .. Capacity;
      Cost : Weight;
   end record;
   type Edge_List is array (Positive range 1 .. Capacity) of Edge;

   function Forest_Cost (Edges : Edge_List; Count : Edge_Count) return Natural
     with Global => null;
end Kruskal_MST_Lite;

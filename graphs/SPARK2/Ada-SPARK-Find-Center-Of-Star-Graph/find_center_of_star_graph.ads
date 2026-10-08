pragma Ada_2022;
package Find_Center_Of_Star_Graph with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Vertex is Positive range 1 .. Capacity;
   subtype Answer is Integer range 0 .. Capacity;
   type Edge is record
      From : Vertex;
      To   : Vertex;
   end record;
   type Edge_List is array (Positive range 1 .. Capacity - 1) of Edge;

   function Find_Center (Edges : Edge_List) return Answer with Global => null;
end Find_Center_Of_Star_Graph;

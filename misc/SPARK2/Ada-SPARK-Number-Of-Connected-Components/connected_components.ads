pragma Ada_2022;
package Connected_Components with SPARK_Mode => On is
   Max_Vertices : constant := 32;
   Max_Edges : constant := 64;
   subtype Vertex is Positive range 1 .. Max_Vertices;
   subtype Edge_Index is Positive range 1 .. Max_Edges;
   subtype Edge_Count is Natural range 0 .. Max_Edges;
   subtype Component_Count is Natural range 0 .. Max_Vertices;
   type Edge is record A, B : Vertex; end record;
   type Edge_Array is array (Edge_Index) of Edge;
   function Count (N : Vertex; Edges : Edge_Array; M : Edge_Count)
     return Component_Count;
end Connected_Components;

pragma Ada_2022;
package body Find_Center_Of_Star_Graph with SPARK_Mode => On is
   subtype Degree is Natural range 0 .. 2 * Capacity;
   type Degree_Array is array (Vertex) of Degree;

   function Find_Center (Edges : Edge_List) return Answer is
      Degrees : Degree_Array := (others => 0);
   begin
      for E in Edges'Range loop
         if Degrees (Edges (E).From) < Degree'Last then
            Degrees (Edges (E).From) := Degrees (Edges (E).From) + 1;
         end if;
         if Degrees (Edges (E).To) < Degree'Last then
            Degrees (Edges (E).To) := Degrees (Edges (E).To) + 1;
         end if;
      end loop;
      for V in Vertex loop
         if Degrees (V) = Edges'Length then
            return V;
         end if;
      end loop;
      return 0;
   end Find_Center;
end Find_Center_Of_Star_Graph;

pragma SPARK_Mode (On);

package body Minimum_Height_Trees with SPARK_Mode => On is
   function Degree (Edges : Graph; V : Vertex) return Natural is
      subtype Degree_Count is Natural range 0 .. Capacity;
      Result : Degree_Count := 0;
   begin
      for Other in Vertex loop
         pragma Loop_Invariant (Result <= Capacity);
         if Edges (V, Other) and then Result < Capacity then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Degree;

   function Center (Edges : Graph) return Vertex is
      Best : Vertex := Vertex'First;
      Best_Degree : Natural := Degree (Edges, Best);
      D : Natural;
   begin
      for V in Vertex range 2 .. Vertex'Last loop
         D := Degree (Edges, V);
         if D > Best_Degree then
            Best := V;
            Best_Degree := D;
         end if;
      end loop;
      return Best;
   end Center;
end Minimum_Height_Trees;

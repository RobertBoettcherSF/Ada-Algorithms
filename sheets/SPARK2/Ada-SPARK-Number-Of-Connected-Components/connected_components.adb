pragma Ada_2022;
package body Connected_Components with SPARK_Mode => On is
   type Parent_Array is array (Vertex) of Vertex;
   function Root (P : Parent_Array; V : Vertex) return Vertex is
      C : Vertex := V;
   begin
      for Step in Vertex loop
         exit when P (C) = C;
         C := P (C);
      end loop;
      return C;
   end Root;
   function Count (N : Vertex; Edges : Edge_Array; M : Edge_Count)
     return Component_Count is
      P : Parent_Array;
      Result : Natural range 0 .. Max_Vertices := 0;
      A, B : Vertex;
   begin
      for V in Vertex loop
         P (V) := V;
      end loop;
      for I in Edge_Index loop
         exit when I > M;
         A := Root (P, Edges (I).A);
         B := Root (P, Edges (I).B);
         if A /= B then
            P (B) := A;
         end if;
      end loop;
      for V in Vertex loop
         pragma Loop_Invariant (Result < V);
         if V <= N and then Root (P, V) = V then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count;
end Connected_Components;

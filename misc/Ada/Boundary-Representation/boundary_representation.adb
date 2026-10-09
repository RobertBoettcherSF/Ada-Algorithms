package body Boundary_Representation is

   procedure Initialize (Model : out B_Rep_Model) is
      Empty_Model : constant B_Rep_Model :=
        (Num_Vertices => 0, Num_Edges => 0, Num_Faces => 0, others => <>);
   begin
      Model := Empty_Model;
   end Initialize;

   function Active_Vertices (Model : B_Rep_Model) return Natural is
   begin
      return Model.Num_Vertices;
   end Active_Vertices;

   function Active_Edges (Model : B_Rep_Model) return Natural is
   begin
      return Model.Num_Edges;
   end Active_Edges;

   function Active_Faces (Model : B_Rep_Model) return Natural is
   begin
      return Model.Num_Faces;
   end Active_Faces;

   function Make_Vertex (Model : in out B_Rep_Model; P : Point_3D) return Vertex_ID is
   begin
      for I in Vertex_ID range 1 .. Max_Items loop
         if Model.Vertices (I).State = Free then
            Model.Vertices (I).State := Active;
            Model.Vertices (I).Point := P;
            Model.Num_Vertices := Model.Num_Vertices + 1;
            return I;
         end if;
      end loop;
      raise Capacity_Error;
   end Make_Vertex;

   function Make_Edge (Model : in out B_Rep_Model; V1, V2 : Vertex_ID) return Edge_ID is
   begin
      if V1 = Invalid_Vertex or else V2 = Invalid_Vertex then
         raise Invalid_ID_Error;
      end if;
      
      if Model.Vertices (V1).State = Free or else Model.Vertices (V2).State = Free then
         raise Invalid_ID_Error;
      end if;

      for I in Edge_ID range 1 .. Max_Items loop
         if Model.Edges (I).State = Free then
            Model.Edges (I).State := Active;
            Model.Edges (I).V1 := V1;
            Model.Edges (I).V2 := V2;
            Model.Num_Edges := Model.Num_Edges + 1;
            Model.Edge_High := Edge_ID'Max (Model.Edge_High, I);
            return I;
         end if;
      end loop;
      raise Capacity_Error;
   end Make_Edge;

   -- Records the oriented vertex loop of face F when its edges, in the
   -- given order, form one closed loop through distinct vertices.
   procedure Derive_Cycle (Model : in out B_Rep_Model; F : Face_ID) is
      N      : constant Natural := Model.Faces (F).Edges.Count;
      Tmp    : Vertex_Array (1 .. Max_Face_Edges) := [others => Invalid_Vertex];
      Start, Cur, Next : Vertex_ID;
   begin
      Model.Faces (F).Cycle_Len := 0;
      if N < 3 then
         return;
      end if;
      for K in 1 .. N loop
         declare
            E : constant Edge_ID := Model.Faces (F).Edges.Elements (K);
         begin
            if E = Invalid_Edge or else Model.Edges (E).State = Free then
               return;
            end if;
         end;
      end loop;
      declare
         E1 : constant Edge_Rec := Model.Edges (Model.Faces (F).Edges.Elements (1));
         E2 : constant Edge_Rec := Model.Edges (Model.Faces (F).Edges.Elements (2));
      begin
         if E1.V1 /= E2.V1 and then E1.V1 /= E2.V2 then
            Start := E1.V1;
         elsif E1.V2 /= E2.V1 and then E1.V2 /= E2.V2 then
            Start := E1.V2;
         else
            return;
         end if;
      end;
      Cur := Start;
      for K in 1 .. N loop
         declare
            E : constant Edge_Rec := Model.Edges (Model.Faces (F).Edges.Elements (K));
         begin
            if E.V1 = Cur then
               Next := E.V2;
            elsif E.V2 = Cur then
               Next := E.V1;
            else
               return;
            end if;
         end;
         Tmp (K) := Cur;
         Cur := Next;
      end loop;
      if Cur /= Start then
         return;
      end if;
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            if Tmp (I) = Tmp (J) then
               return;
            end if;
         end loop;
      end loop;
      Model.Faces (F).Cycle := Tmp;
      Model.Faces (F).Cycle_Len := N;
   end Derive_Cycle;

   function Make_Face (Model : in out B_Rep_Model; Edges : Edge_Array) return Face_ID is
   begin
      if Edges'Length > Max_Face_Edges then
         raise Capacity_Error;
      end if;

      for I in Face_ID range 1 .. Max_Items loop
         if Model.Faces (I).State = Free then
            Model.Faces (I).State := Active;
            Model.Faces (I).Edges.Count := Edges'Length;
            for J in Edges'Range loop
               Model.Faces (I).Edges.Elements (J - Edges'First + 1) := Edges (J);
            end loop;
            Model.Num_Faces := Model.Num_Faces + 1;
            Derive_Cycle (Model, I);
            return I;
         end if;
      end loop;
      raise Capacity_Error;
   end Make_Face;

   function Make_Polygon_Face (Model : in out B_Rep_Model; Cycle : Vertex_Array) return Face_ID is
      N     : constant Natural := Cycle'Length;
      Edges : Edge_Array (1 .. N);
   begin
      if N > Max_Face_Edges then
         raise Capacity_Error;
      end if;
      for I in Cycle'Range loop
         if Cycle (I) = Invalid_Vertex or else Model.Vertices (Cycle (I)).State = Free then
            raise Invalid_ID_Error;
         end if;
         for J in I + 1 .. Cycle'Last loop
            if Cycle (I) = Cycle (J) then
               raise Topology_Error;
            end if;
         end loop;
      end loop;
      for K in 1 .. N loop
         declare
            A : constant Vertex_ID := Cycle (Cycle'First + K - 1);
            B : constant Vertex_ID := Cycle (if K = N then Cycle'First else Cycle'First + K);
            Found : Edge_ID := Invalid_Edge;
         begin
            for E in Edge_ID range 1 .. Model.Edge_High loop
               if Model.Edges (E).State = Active
                 and then ((Model.Edges (E).V1 = A and then Model.Edges (E).V2 = B)
                           or else (Model.Edges (E).V1 = B and then Model.Edges (E).V2 = A))
               then
                  Found := E;
                  exit;
               end if;
            end loop;
            Edges (K) := (if Found /= Invalid_Edge then Found else Make_Edge (Model, A, B));
         end;
      end loop;
      return Make_Face (Model, Edges);
   end Make_Polygon_Face;

   function Euler_Poincare_Characteristic (Model : B_Rep_Model) return Integer is
   begin
      -- Standard Euler formula for a single shell: V - E + F
      return Model.Num_Vertices - Model.Num_Edges + Model.Num_Faces;
   end Euler_Poincare_Characteristic;

   function Check_Solid (Model : B_Rep_Model) return Solid_Report is
      Max_Corners : constant := Max_Items * Max_Face_Edges;
      subtype Corner_Count is Natural range 0 .. Max_Corners;

      Rep : Solid_Report;

      -- Edge use: number of face loops through each edge, the direction
      -- (+1: V1 -> V2) of the first use, and the faces using it.
      Uses      : array (Edge_ID range 1 .. Max_Items) of Natural := [others => 0];
      First_Dir : array (Edge_ID range 1 .. Max_Items) of Integer := [others => 0];
      Use_Face  : array (Edge_ID range 1 .. Max_Items, 1 .. 2) of Face_ID :=
        [others => [others => Invalid_Face]];
      Same_Way  : Boolean := False;

      -- Corners: (vertex, face, incoming edge, outgoing edge), listed
      -- per vertex.
      N_Corners  : Corner_Count := 0;
      Corner_In, Corner_Out : array (1 .. Max_Corners) of Edge_ID;
      Corner_F   : array (1 .. Max_Corners) of Face_ID;
      Next_C     : array (1 .. Max_Corners) of Corner_Count;
      Head       : array (Vertex_ID range 1 .. Max_Items) of Corner_Count := [others => 0];

      -- Shells: union-find over faces through shared edges.
      Parent : array (Face_ID range 1 .. Max_Items) of Face_ID;
      Shell  : array (Face_ID range 1 .. Max_Items) of Natural := [others => 0];
      V_S, E_S, F_S : array (1 .. Max_Shells) of Natural := [others => 0];

      function Root (F : Face_ID) return Face_ID is
         R : Face_ID := F;
      begin
         while Parent (R) /= R loop
            R := Parent (R);
         end loop;
         return R;
      end Root;

      function Fail (Why : Solid_Failure) return Solid_Report is
        ((Failure => Why, Shells => 0, Genus => [others => 0]));
   begin
      if Model.Num_Faces = 0 then
         return Fail (No_Faces);
      end if;

      -- (1) closed loops of active elements; collect edge uses, corners.
      for F in Face_ID range 1 .. Max_Items loop
         Parent (F) := F;
         if Model.Faces (F).State = Active then
            declare
               R : Face_Rec renames Model.Faces (F);
               N : constant Natural := R.Cycle_Len;
            begin
               if N = 0 then
                  return Fail (Face_Without_Loop);
               end if;
               for K in 1 .. N loop
                  declare
                     E    : constant Edge_ID := R.Edges.Elements (K);
                     A    : constant Vertex_ID := R.Cycle (K);
                     Prev : constant Edge_ID := R.Edges.Elements (if K = 1 then N else K - 1);
                     Dir  : Integer;
                  begin
                     if Model.Edges (E).State = Free or else Model.Vertices (A).State = Free then
                        return Fail (Dead_Reference);
                     end if;
                     Dir := (if Model.Edges (E).V1 = A then 1 else -1);
                     Uses (E) := Uses (E) + 1;
                     if Uses (E) = 1 then
                        First_Dir (E) := Dir;
                        Use_Face (E, 1) := F;
                     elsif Uses (E) = 2 then
                        Same_Way := Same_Way or else Dir = First_Dir (E);
                        Use_Face (E, 2) := F;
                     end if;
                     N_Corners := N_Corners + 1;
                     Corner_In (N_Corners)  := Prev;
                     Corner_Out (N_Corners) := E;
                     Corner_F (N_Corners)   := F;
                     Next_C (N_Corners)     := Head (A);
                     Head (A) := N_Corners;
                  end;
               end loop;
            end;
         end if;
      end loop;

      -- (2) every active edge on exactly two faces.
      for E in Edge_ID range 1 .. Max_Items loop
         if Model.Edges (E).State = Active and then Uses (E) /= 2 then
            return Fail (Edge_Not_Two_Faces);
         end if;
      end loop;

      -- (3) the two faces traverse each edge in opposite directions.
      if Same_Way then
         return Fail (Opposite_Orientation);
      end if;

      -- (4) one ring of faces per vertex: from any corner, step to the
      -- corner whose incoming edge is this one's outgoing edge; the walk
      -- must return to its start after visiting every corner.
      for V in Vertex_ID range 1 .. Max_Items loop
         if Model.Vertices (V).State = Active then
            if Head (V) = 0 then
               return Fail (Isolated_Vertex);
            end if;
            declare
               Total : Natural := 0;
               C     : Corner_Count := Head (V);
               Cur   : Corner_Count := Head (V);
               Steps : Natural := 0;
               Found : Corner_Count;
            begin
               while C /= 0 loop
                  Total := Total + 1;
                  C := Next_C (C);
               end loop;
               loop
                  Found := 0;
                  C := Head (V);
                  while C /= 0 loop
                     if Corner_In (C) = Corner_Out (Cur) then
                        Found := C;
                        exit;
                     end if;
                     C := Next_C (C);
                  end loop;
                  if Found = 0 then
                     return Fail (Vertex_Not_One_Ring);
                  end if;
                  Steps := Steps + 1;
                  Cur := Found;
                  exit when Cur = Head (V) or else Steps > Total;
               end loop;
               if Steps /= Total then
                  return Fail (Vertex_Not_One_Ring);
               end if;
            end;
         end if;
      end loop;

      -- Shells and genus.
      for E in Edge_ID range 1 .. Max_Items loop
         if Model.Edges (E).State = Active then
            declare
               R1 : constant Face_ID := Root (Use_Face (E, 1));
               R2 : constant Face_ID := Root (Use_Face (E, 2));
            begin
               if R1 /= R2 then
                  Parent (Face_ID'Max (R1, R2)) := Face_ID'Min (R1, R2);
               end if;
            end;
         end if;
      end loop;
      for F in Face_ID range 1 .. Max_Items loop
         if Model.Faces (F).State = Active then
            declare
               R : constant Face_ID := Root (F);
            begin
               if Shell (R) = 0 then
                  Rep.Shells := Rep.Shells + 1;
                  Shell (R) := Rep.Shells;
               end if;
               F_S (Shell (R)) := F_S (Shell (R)) + 1;
            end;
         end if;
      end loop;
      for E in Edge_ID range 1 .. Max_Items loop
         if Model.Edges (E).State = Active then
            E_S (Shell (Root (Use_Face (E, 1)))) := E_S (Shell (Root (Use_Face (E, 1)))) + 1;
         end if;
      end loop;
      for V in Vertex_ID range 1 .. Max_Items loop
         if Model.Vertices (V).State = Active then
            V_S (Shell (Root (Corner_F (Head (V))))) := V_S (Shell (Root (Corner_F (Head (V))))) + 1;
         end if;
      end loop;
      for S in 1 .. Rep.Shells loop
         declare
            Chi : constant Integer := V_S (S) - E_S (S) + F_S (S);
         begin
            if Chi > 2 or else (2 - Chi) mod 2 /= 0 then
               return Fail (Odd_Characteristic);
            end if;
            Rep.Genus (S) := (2 - Chi) / 2;
         end;
      end loop;
      Rep.Failure := None;
      return Rep;
   end Check_Solid;

   function Is_Valid_Manifold (Model : B_Rep_Model) return Boolean is
   begin
      return Check_Solid (Model).Failure = None;
   end Is_Valid_Manifold;

   procedure Make_Vertex_Face_Shell 
     (Model : out B_Rep_Model; 
      P     : Point_3D; 
      V     : out Vertex_ID; 
      F     : out Face_ID) 
   is
      Temp     : B_Rep_Model;
      No_Edges : constant Edge_Array (1 .. 0) := [others => Invalid_Edge];
   begin
      -- MVFS creates the initial topology starting point (1 Vertex, 1 Face, 0 Edges)
      Initialize (Temp);
      V := Make_Vertex (Temp, P);
      F := Make_Face (Temp, No_Edges);
      Model := Temp;
   end Make_Vertex_Face_Shell;

   procedure Make_Edge_Vertex 
     (Model   : in out B_Rep_Model; 
      V_Start : Vertex_ID; 
      P_End   : Point_3D;
      V_End   : out Vertex_ID; 
      E       : out Edge_ID) 
   is
   begin
      -- MEV safely extends a single vertex into a wire segment
      V_End := Make_Vertex (Model, P_End);
      E     := Make_Edge (Model, V_Start, V_End);
   end Make_Edge_Vertex;

   procedure Make_Edge_Face 
     (Model : in out B_Rep_Model; 
      V1    : Vertex_ID; 
      V2    : Vertex_ID;
      E     : out Edge_ID; 
      F_New : out Face_ID) 
   is
      New_Edges : Edge_Array (1 .. 1);
   begin
      -- MEF creates a new edge and bounds a new face with it, preserving manifold properties
      E := Make_Edge (Model, V1, V2);
      New_Edges (1) := E;
      F_New := Make_Face (Model, New_Edges);
   end Make_Edge_Face;

   procedure Kill_Edge_Vertex (Model : in out B_Rep_Model; E : Edge_ID; V : Vertex_ID) is
   begin
      if E = Invalid_Edge or else V = Invalid_Vertex then
         raise Invalid_ID_Error;
      end if;

      if Model.Edges (E).State = Free or else Model.Vertices (V).State = Free then
         raise Invalid_ID_Error;
      end if;

      -- Validate that the edge actually connects to the vertex
      if Model.Edges (E).V1 /= V and then Model.Edges (E).V2 /= V then
         raise Topology_Error;
      end if;

      Model.Edges (E).State := Free;
      Model.Num_Edges       := Model.Num_Edges - 1;

      Model.Vertices (V).State := Free;
      Model.Num_Vertices       := Model.Num_Vertices - 1;
   end Kill_Edge_Vertex;

   procedure Kill_Edge_Face (Model : in out B_Rep_Model; E : Edge_ID; F : Face_ID) is
   begin
      if E = Invalid_Edge or else F = Invalid_Face then
         raise Invalid_ID_Error;
      end if;

      if Model.Edges (E).State = Free or else Model.Faces (F).State = Free then
         raise Invalid_ID_Error;
      end if;

      Model.Edges (E).State := Free;
      Model.Num_Edges       := Model.Num_Edges - 1;

      Model.Faces (F).State := Free;
      Model.Num_Faces       := Model.Num_Faces - 1;
   end Kill_Edge_Face;

   function Get_Vertex_Point (Model : B_Rep_Model; V : Vertex_ID) return Point_3D is
   begin
      if V = Invalid_Vertex or else Model.Vertices (V).State = Free then
         raise Invalid_ID_Error;
      end if;
      return Model.Vertices (V).Point;
   end Get_Vertex_Point;

   function Are_Connected (Model : B_Rep_Model; V1, V2 : Vertex_ID) return Boolean is
   begin
      if V1 = Invalid_Vertex or else V2 = Invalid_Vertex then
         return False;
      end if;

      for I in Edge_ID range 1 .. Max_Items loop
         if Model.Edges (I).State = Active then
            if (Model.Edges (I).V1 = V1 and then Model.Edges (I).V2 = V2) or else
               (Model.Edges (I).V1 = V2 and then Model.Edges (I).V2 = V1) 
            then
               return True;
            end if;
         end if;
      end loop;
      
      return False;
   end Are_Connected;

end Boundary_Representation;

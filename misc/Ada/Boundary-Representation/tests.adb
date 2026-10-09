with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Boundary_Representation; use Boundary_Representation;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Model : B_Rep_Model;

   --  Mesh builder for the solid checks: N vertices 1 .. N, faces given
   --  as vertex loops (0 ends a loop early); each consecutive pair gets
   --  one shared edge, and Make_Face receives the loop's edges in
   --  traversal order.
   Max_Mesh_V : constant := 24;
   type Loop_Spec is array (1 .. 4) of Natural;
   type Mesh_Spec is array (Positive range <>) of Loop_Spec;
   type Vertex_Map is array (1 .. Max_Mesh_V) of Vertex_ID;

   procedure Build
     (M : in out B_Rep_Model; N : Positive; Faces : Mesh_Spec;
      Vs : out Vertex_Map)
   is
      Edge_Of : array (1 .. Max_Mesh_V, 1 .. Max_Mesh_V) of Edge_ID :=
        [others => [others => Invalid_Edge]];
      F : Face_ID;
   begin
      Initialize (M);
      Vs := [others => Invalid_Vertex];
      for I in 1 .. N loop
         Vs (I) := Make_Vertex (M, (Coordinate (I), 0.0, 0.0));
      end loop;
      for L of Faces loop
         declare
            Len : Natural := 0;
         begin
            while Len < 4 and then L (Len + 1) /= 0 loop
               Len := Len + 1;
            end loop;
            declare
               Es : Edge_Array (1 .. Len);
            begin
               for K in 1 .. Len loop
                  declare
                     A : constant Positive := L (K);
                     B : constant Positive := L (if K = Len then 1 else K + 1);
                     Lo : constant Positive := Positive'Min (A, B);
                     Hi : constant Positive := Positive'Max (A, B);
                  begin
                     if Edge_Of (Lo, Hi) = Invalid_Edge then
                        Edge_Of (Lo, Hi) := Make_Edge (M, Vs (A), Vs (B));
                     end if;
                     Es (K) := Edge_Of (Lo, Hi);
                  end;
               end loop;
               F := Make_Face (M, Es);
               pragma Assert (F /= Invalid_Face);
            end;
         end;
      end loop;
   end Build;

   --  Cube on vertices 1 .. 8 (vertex 1 + x + 2y + 4z), outward loops.
   Cube : constant Mesh_Spec :=
     [[1, 3, 4, 2], [5, 6, 8, 7], [1, 2, 6, 5],
      [3, 7, 8, 4], [1, 5, 7, 3], [2, 4, 8, 6]];
   --  Tetrahedron on 1 .. 4, outward loops.
   Tetra : constant Mesh_Spec :=
     [[1, 3, 2, 0], [1, 2, 4, 0], [1, 4, 3, 0], [2, 3, 4, 0]];

   function Shift (M : Mesh_Spec; By : Natural) return Mesh_Spec is
      R : Mesh_Spec := M;
   begin
      for L of R loop
         for X of L loop
            if X /= 0 then
               X := X + By;
            end if;
         end loop;
      end loop;
      return R;
   end Shift;

   --  3 x 3 quad torus: vertex 1 + i + 3j, quad (i, j) .. (i+1, j+1) mod 3.
   function Torus return Mesh_Spec is
      R : Mesh_Spec (1 .. 9);
      function V (I, J : Natural) return Positive is
        (1 + I mod 3 + 3 * (J mod 3));
   begin
      for I in 0 .. 2 loop
         for J in 0 .. 2 loop
            R (1 + I + 3 * J) :=
              [V (I, J), V (I + 1, J), V (I + 1, J + 1), V (I, J + 1)];
         end loop;
      end loop;
      return R;
   end Torus;
begin
   -- TEST 1 — Core Initialization
   Put_Line ("TEST 1 — Core Initialization");
   Initialize (Model);
   Check ("1.1 Vertices is 0", Active_Vertices (Model) = 0);
   Check ("1.2 Edges is 0", Active_Edges (Model) = 0);
   Check ("1.3 Faces is 0", Active_Faces (Model) = 0);
   Check ("1.4 Euler is 0", Euler_Poincare_Characteristic (Model) = 0);

   -- TEST 2 — Make Vertex
   Put_Line ("TEST 2 — Make Vertex");
   Initialize (Model);
   declare
      V : Vertex_ID;
      Pt : constant Point_3D := (1.0, 2.0, 3.0);
      Out_Pt : Point_3D;
   begin
      V := Make_Vertex (Model, Pt);
      Check ("2.1 Valid Vertex ID", V /= Invalid_Vertex);
      Check ("2.2 Vertices is 1", Active_Vertices (Model) = 1);
      Out_Pt := Get_Vertex_Point (Model, V);
      Check ("2.3 Correct coordinates X", Out_Pt.X = 1.0);
      Check ("2.4 Correct coordinates Y", Out_Pt.Y = 2.0);
   end;

   -- TEST 3 — Make Edge
   Put_Line ("TEST 3 — Make Edge");
   Initialize (Model);
   declare
      Va, Vb : Vertex_ID;
      E : Edge_ID;
   begin
      Va := Make_Vertex (Model, (0.0, 0.0, 0.0));
      Vb := Make_Vertex (Model, (1.0, 1.0, 1.0));
      E := Make_Edge (Model, Va, Vb);
      Check ("3.1 Valid Edge ID", E /= Invalid_Edge);
      Check ("3.2 Edges is 1", Active_Edges (Model) = 1);
      Check ("3.3 Are_Connected is True", Are_Connected (Model, Va, Vb));
   end;

   -- TEST 4 — Make Face
   Put_Line ("TEST 4 — Make Face");
   Initialize (Model);
   declare
      V1, V2, V3 : Vertex_ID;
      E1, E2, E3 : Edge_ID;
      F : Face_ID;
      Edges : Edge_Array (1 .. 3);
   begin
      V1 := Make_Vertex (Model, (0.0, 0.0, 0.0));
      V2 := Make_Vertex (Model, (1.0, 0.0, 0.0));
      V3 := Make_Vertex (Model, (0.0, 1.0, 0.0));
      E1 := Make_Edge (Model, V1, V2);
      E2 := Make_Edge (Model, V2, V3);
      E3 := Make_Edge (Model, V3, V1);
      Edges := [E1, E2, E3];
      F := Make_Face (Model, Edges);
      Check ("4.1 Valid Face ID", F /= Invalid_Face);
      Check ("4.2 Faces is 1", Active_Faces (Model) = 1);
      Check ("4.3 Edges is 3", Active_Edges (Model) = 3);
   end;

   -- TEST 5 — Make Vertex Face Shell (MVFS)
   Put_Line ("TEST 5 — Make Vertex Face Shell (MVFS)");
   Initialize (Model);
   declare
      V : Vertex_ID;
      F : Face_ID;
   begin
      Make_Vertex_Face_Shell (Model, (0.0, 0.0, 0.0), V, F);
      Check ("5.1 Vertices is 1", Active_Vertices (Model) = 1);
      Check ("5.2 Faces is 1", Active_Faces (Model) = 1);
      Check ("5.3 Edges is 0", Active_Edges (Model) = 0);
      Check ("5.4 Euler is 2", Euler_Poincare_Characteristic (Model) = 2);
      --  A one-vertex skeleton has V - E + F = 2 but is no closed surface.
      Check ("5.5 MVFS skeleton is not a closed manifold", not Is_Valid_Manifold (Model));
   end;

   -- TEST 6 — Make Edge Vertex (MEV)
   Put_Line ("TEST 6 — Make Edge Vertex (MEV)");
   Initialize (Model);
   declare
      V1, V2 : Vertex_ID;
      F1 : Face_ID;
      E1 : Edge_ID;
   begin
      Make_Vertex_Face_Shell (Model, (0.0, 0.0, 0.0), V1, F1);
      Make_Edge_Vertex (Model, V1, (1.0, 0.0, 0.0), V2, E1);
      Check ("6.1 Vertices is 2", Active_Vertices (Model) = 2);
      Check ("6.2 Edges is 1", Active_Edges (Model) = 1);
      Check ("6.3 Euler invariant holds (2)", Euler_Poincare_Characteristic (Model) = 2);
   end;

   -- TEST 7 — Make Edge Face (MEF)
   Put_Line ("TEST 7 — Make Edge Face (MEF)");
   Initialize (Model);
   declare
      V1, V2 : Vertex_ID;
      F1, F2 : Face_ID;
      E1, E2 : Edge_ID;
   begin
      Make_Vertex_Face_Shell (Model, (0.0, 0.0, 0.0), V1, F1);
      Make_Edge_Vertex (Model, V1, (1.0, 0.0, 0.0), V2, E1);
      Make_Edge_Face (Model, V1, V2, E2, F2);
      Check ("7.1 Vertices is 2", Active_Vertices (Model) = 2);
      Check ("7.2 Edges is 2", Active_Edges (Model) = 2);
      Check ("7.3 Faces is 2", Active_Faces (Model) = 2);
      Check ("7.4 Euler invariant holds (2)", Euler_Poincare_Characteristic (Model) = 2);
   end;

   -- TEST 8 — Euler-Poincaré Validation
   Put_Line ("TEST 8 — Euler-Poincaré Validation");
   Initialize (Model);
   declare
      V1, V2, V3 : Vertex_ID;
      E1, E2 : Edge_ID;
   begin
      -- Construct open non-manifold structure
      V1 := Make_Vertex (Model, (0.0, 0.0, 0.0));
      V2 := Make_Vertex (Model, (1.0, 0.0, 0.0));
      V3 := Make_Vertex (Model, (0.0, 1.0, 0.0));
      E1 := Make_Edge (Model, V1, V2);
      E2 := Make_Edge (Model, V2, V3);
      
      Check ("8.0a Assigned E1 is valid", E1 /= Invalid_Edge);
      Check ("8.0b Assigned E2 is valid", E2 /= Invalid_Edge);

      -- V=3, E=2, F=0 => 3 - 2 + 0 = 1
      Check ("8.1 Open structure characteristic is 1", Euler_Poincare_Characteristic (Model) = 1);
      Check ("8.2 Is_Valid_Manifold is False", not Is_Valid_Manifold (Model));
      Check ("8.3 Are_Connected validates E2", Are_Connected (Model, V2, V3));
   end;

   -- TEST 9 — Invalid Edge Creation
   Put_Line ("TEST 9 — Invalid Edge Creation");
   Initialize (Model);
   begin
      if Make_Edge (Model, Invalid_Vertex, Invalid_Vertex) /= Invalid_Edge then
         Check ("9.1 Should not reach here", False);
      end if;
   exception
      when Invalid_ID_Error =>
         Check ("9.1 Raised Invalid_ID_Error", True);
         Check ("9.2 Vertices unchanged", Active_Vertices (Model) = 0);
         Check ("9.3 Edges unchanged", Active_Edges (Model) = 0);
   end;

   -- TEST 10 — Face Capacity Limit
   Put_Line ("TEST 10 — Face Capacity Limit");
   Initialize (Model);
   declare
      Too_Many : constant Edge_Array (1 .. 33) := [others => Invalid_Edge];
   begin
      if Make_Face (Model, Too_Many) /= Invalid_Face then
         Check ("10.1 Should not reach here", False);
      end if;
   exception
      when Capacity_Error =>
         Check ("10.1 Raised Capacity_Error", True);
         Check ("10.2 Faces still 0", Active_Faces (Model) = 0);
         Check ("10.3 Edges still 0", Active_Edges (Model) = 0);
   end;

   -- TEST 11 — Invalid Vertex Operations
   Put_Line ("TEST 11 — Invalid Vertex Operations");
   Initialize (Model);
   declare
      P : Point_3D;
   begin
      P := Get_Vertex_Point (Model, Invalid_Vertex);
      Check ("11.1 Should not reach here", False);
      if P.X = 0.0 then null; end if; -- Suppress unused warning
   exception
      when Invalid_ID_Error => 
         Check ("11.1 Get invalid vertex raises error", True);
         Check ("11.2 Active Vertices unchanged", Active_Vertices (Model) = 0);
         Check ("11.3 Active Edges unchanged", Active_Edges (Model) = 0);
   end;

   -- TEST 12 — Kill Edge Vertex (KEV)
   Put_Line ("TEST 12 — Kill Edge Vertex (KEV)");
   Initialize (Model);
   declare
      V1, V2 : Vertex_ID;
      F1 : Face_ID;
      E1 : Edge_ID;
   begin
      Make_Vertex_Face_Shell (Model, (0.0, 0.0, 0.0), V1, F1);
      Make_Edge_Vertex (Model, V1, (1.0, 0.0, 0.0), V2, E1);
      Check ("12.1 Edges is 1", Active_Edges (Model) = 1);
      Kill_Edge_Vertex (Model, E1, V2);
      Check ("12.2 Edges is 0", Active_Edges (Model) = 0);
      Check ("12.3 Vertices is 1", Active_Vertices (Model) = 1);
   end;

   -- TEST 13 — Kill Edge Face (KEF)
   Put_Line ("TEST 13 — Kill Edge Face (KEF)");
   Initialize (Model);
   declare
      V1, V2 : Vertex_ID;
      F1, F2 : Face_ID;
      E1, E2 : Edge_ID;
   begin
      Make_Vertex_Face_Shell (Model, (0.0, 0.0, 0.0), V1, F1);
      Make_Edge_Vertex (Model, V1, (1.0, 0.0, 0.0), V2, E1);
      Make_Edge_Face (Model, V1, V2, E2, F2);
      Check ("13.1 Faces is 2", Active_Faces (Model) = 2);
      Kill_Edge_Face (Model, E2, F2);
      Check ("13.2 Faces is 1", Active_Faces (Model) = 1);
      Check ("13.3 Euler holds", Euler_Poincare_Characteristic (Model) = 2);
   end;

   -- TEST 14 — Closed manifold solids (agent A3, checker scan)
   --  Is_Valid_Manifold must mean a closed orientable 2-manifold: every
   --  edge on exactly two faces traversed in opposite directions, one
   --  ring of faces around every vertex; any genus, any number of shells.
   Put_Line ("TEST 14 — Closed manifold solids");
   declare
      Vs : Vertex_Map;
      Flipped : Mesh_Spec := Cube;
      E_Extra : Edge_ID;
      V_Extra : Vertex_ID;
   begin
      Build (Model, 8, Cube, Vs);
      Check ("14.1 Cube is a closed manifold", Is_Valid_Manifold (Model));

      Build (Model, 9, Torus, Vs);
      Check ("14.2 Torus (V - E + F = 0) is a closed manifold",
             Euler_Poincare_Characteristic (Model) = 0
             and then Is_Valid_Manifold (Model));

      Flipped (6) := [2, 6, 8, 4];
      Build (Model, 8, Flipped, Vs);
      Check ("14.3 Cube with one flipped face is not (orientation)",
             Euler_Poincare_Characteristic (Model) = 2
             and then not Is_Valid_Manifold (Model));

      Build (Model, 16, Cube & Shift (Cube, 8), Vs);
      Check ("14.4 Two disjoint cubes (V - E + F = 4) are a closed manifold",
             Euler_Poincare_Characteristic (Model) = 4
             and then Is_Valid_Manifold (Model));

      Build (Model, 4, Tetra, Vs);
      Check ("14.5 Tetrahedron is a closed manifold", Is_Valid_Manifold (Model));
      V_Extra := Make_Vertex (Model, (9.0, 9.0, 9.0));
      E_Extra := Make_Edge (Model, Vs (1), V_Extra);
      Check ("14.6 Tetrahedron plus a dangling edge (V - E + F = 2) is not",
             E_Extra /= Invalid_Edge
             and then Euler_Poincare_Characteristic (Model) = 2
             and then not Is_Valid_Manifold (Model));
   end;

   -- TEST 15 — Check_Solid reports (agent A3)
   Put_Line ("TEST 15 — Check_Solid failure kinds, shells and genus");
   declare
      Vs : Vertex_Map;
      Flipped : Mesh_Spec := Cube;
      R : Solid_Report;
      E_Extra : Edge_ID;
      V_Extra : Vertex_ID;
      F : Face_ID;
   begin
      Build (Model, 9, Torus, Vs);
      R := Check_Solid (Model);
      Check ("15.1 Torus: one shell of genus 1",
             R.Failure = None and then R.Shells = 1 and then R.Genus (1) = 1);
      Build (Model, 16, Cube & Shift (Cube, 8), Vs);
      R := Check_Solid (Model);
      Check ("15.2 Two cubes: two shells of genus 0",
             R.Failure = None and then R.Shells = 2
             and then R.Genus (1) = 0 and then R.Genus (2) = 0);
      Build (Model, 17, Cube & Shift (Torus, 8), Vs);
      R := Check_Solid (Model);
      Check ("15.3 Cube and torus: genus 0 then 1",
             R.Failure = None and then R.Shells = 2
             and then R.Genus (1) = 0 and then R.Genus (2) = 1);
      Flipped (6) := [2, 6, 8, 4];
      Build (Model, 8, Flipped, Vs);
      Check ("15.4 Reversed face: Opposite_Orientation",
             Check_Solid (Model).Failure = Opposite_Orientation);
      Build (Model, 4, Tetra, Vs);
      V_Extra := Make_Vertex (Model, (9.0, 9.0, 9.0));
      E_Extra := Make_Edge (Model, Vs (1), V_Extra);
      Check ("15.5 Dangling edge: Edge_Not_Two_Faces",
             E_Extra /= Invalid_Edge
             and then Check_Solid (Model).Failure = Edge_Not_Two_Faces);
      --  Two tetrahedra glued at vertex 1 only: every edge is fine, but
      --  the faces at vertex 1 form two rings.
      Build (Model, 7, Tetra & Mesh_Spec'[[1, 6, 5, 0], [1, 5, 7, 0], [1, 7, 6, 0], [5, 6, 7, 0]], Vs);
      Check ("15.6 Two tetrahedra sharing one vertex: Vertex_Not_One_Ring",
             Check_Solid (Model).Failure = Vertex_Not_One_Ring);
      Build (Model, 4, Tetra, Vs);
      V_Extra := Make_Vertex (Model, (9.0, 9.0, 9.0));
      Check ("15.7 Extra vertex: Isolated_Vertex",
             V_Extra /= Invalid_Vertex
             and then Check_Solid (Model).Failure = Isolated_Vertex);
      Build (Model, 4, Tetra (1 .. 3), Vs);
      Check ("15.8 Tetrahedron without one face: Edge_Not_Two_Faces",
             Check_Solid (Model).Failure = Edge_Not_Two_Faces);
      Initialize (Model);
      Check ("15.9 Empty model: No_Faces", Check_Solid (Model).Failure = No_Faces);
      --  Make_Polygon_Face builds the same tetrahedron from vertex loops.
      Initialize (Model);
      for I in 1 .. 4 loop
         Vs (I) := Make_Vertex (Model, (Coordinate (I), 1.0, 0.0));
      end loop;
      for L of Tetra loop
         F := Make_Polygon_Face (Model, [Vs (L (1)), Vs (L (2)), Vs (L (3))]);
      end loop;
      Check ("15.10 Make_Polygon_Face tetrahedron: 6 shared edges, valid",
             F /= Invalid_Face and then Active_Edges (Model) = 6
             and then Is_Valid_Manifold (Model));
      begin
         F := Make_Polygon_Face (Model, [Vs (1), Vs (2), Vs (1)]);
         Check ("15.11 Repeated vertex raises Topology_Error", False);
      exception
         when Topology_Error =>
            Check ("15.11 Repeated vertex raises Topology_Error", True);
      end;
   end;

   -- TEST 16 — Against an independent reference on every small mesh
   --  5 vertices; each of the 10 triangles absent or present in one of
   --  two orientations (59,049 meshes, built with Make_Polygon_Face).
   --  Reference: directed-edge counts (each undirected edge either unused
   --  or used once in each direction), every vertex used, the link of
   --  every vertex one directed cycle, shells as vertex components through
   --  triangles, genus from V - E + F. Check_Solid must agree on validity,
   --  shell count and genera.
   Put_Line ("TEST 16 — Check_Solid against an independent reference");
   declare
      type Tri is array (1 .. 3) of Positive;
      Tris : array (1 .. 10) of Tri;
      NT : Natural := 0;
      Meshes, Valid, Disagree : Natural := 0;
   begin
      for A in 1 .. 5 loop
         for B in A + 1 .. 5 loop
            for C in B + 1 .. 5 loop
               NT := NT + 1;
               Tris (NT) := [A, B, C];
            end loop;
         end loop;
      end loop;
      for Code in 0 .. 3**10 - 1 loop
         declare
            Chosen : array (1 .. 10) of Natural := [others => 0];  -- 0 absent, 1 as is, 2 reversed
            Faces  : array (1 .. 10) of Tri;
            NF     : Natural := 0;
            D      : array (1 .. 5, 1 .. 5) of Natural := [others => [others => 0]];
            Ref_OK : Boolean := True;
            Ref_Shells : Natural := 0;
            Comp   : array (1 .. 5) of Natural := [others => 0];
            Vs     : array (1 .. 5) of Vertex_ID;
            R      : Solid_Report;
            F      : Face_ID;
         begin
            for T in 1 .. 10 loop
               Chosen (T) := (Code / 3**(T - 1)) mod 3;
               if Chosen (T) /= 0 then
                  NF := NF + 1;
                  Faces (NF) := (if Chosen (T) = 1 then Tris (T)
                                 else [Tris (T) (1), Tris (T) (3), Tris (T) (2)]);
               end if;
            end loop;
            Meshes := Meshes + 1;
            --  Reference
            if NF = 0 then
               Ref_OK := False;
            end if;
            for K in 1 .. NF loop
               for J in 1 .. 3 loop
                  D (Faces (K) (J), Faces (K) (J mod 3 + 1)) :=
                    D (Faces (K) (J), Faces (K) (J mod 3 + 1)) + 1;
               end loop;
            end loop;
            for X in 1 .. 5 loop
               for Y in 1 .. 5 loop
                  if D (X, Y) + D (Y, X) /= 0
                    and then (D (X, Y) /= 1 or else D (Y, X) /= 1)
                  then
                     Ref_OK := False;
                  end if;
               end loop;
            end loop;
            for X in 1 .. 5 loop
               declare
                  Succ : array (1 .. 5) of Natural := [others => 0];
                  In_D : array (1 .. 5) of Natural := [others => 0];
                  Links, Start, Cur, Len : Natural := 0;
               begin
                  for K in 1 .. NF loop
                     for J in 1 .. 3 loop
                        if Faces (K) (J) = X then
                           declare
                              P : constant Positive := Faces (K) (J mod 3 + 1);
                              Q : constant Positive := Faces (K) ((J + 1) mod 3 + 1);
                           begin
                              if Succ (P) /= 0 then
                                 Ref_OK := False;
                              end if;
                              Succ (P) := Q;
                              In_D (Q) := In_D (Q) + 1;
                              Links := Links + 1;
                              Start := P;
                           end;
                        end if;
                     end loop;
                  end loop;
                  if Links = 0 then
                     Ref_OK := False;
                  elsif Ref_OK then
                     Cur := Start;
                     loop
                        Len := Len + 1;
                        Cur := Succ (Cur);
                        exit when Cur = Start or else Cur = 0 or else Len > 5;
                     end loop;
                     if Cur /= Start or else Len /= Links then
                        Ref_OK := False;
                     end if;
                  end if;
               end;
            end loop;
            if Ref_OK then
               --  Shells: label vertex components through triangles.
               for X in 1 .. 5 loop
                  if Comp (X) = 0 then
                     Ref_Shells := Ref_Shells + 1;
                     Comp (X) := Ref_Shells;
                     for Pass in 1 .. 5 loop
                        for K in 1 .. NF loop
                           if (for some J in 1 .. 3 => Comp (Faces (K) (J)) = Ref_Shells) then
                              for J in 1 .. 3 loop
                                 Comp (Faces (K) (J)) := Ref_Shells;
                              end loop;
                           end if;
                        end loop;
                     end loop;
                  end if;
               end loop;
            end if;
            --  Library
            Initialize (Model);
            for X in 1 .. 5 loop
               Vs (X) := Make_Vertex (Model, (Coordinate (X), 2.0, 0.0));
            end loop;
            for K in 1 .. NF loop
               F := Make_Polygon_Face
                 (Model, [Vs (Faces (K) (1)), Vs (Faces (K) (2)), Vs (Faces (K) (3))]);
            end loop;
            R := Check_Solid (Model);
            if Ref_OK then
               Valid := Valid + 1;
            end if;
            if (R.Failure = None) /= Ref_OK
              or else (Ref_OK and then R.Shells /= Ref_Shells)
            then
               Disagree := Disagree + 1;
            elsif Ref_OK then
               --  Genus per shell: V - E + F = 2 - 2g (all genus 0 here,
               --  computed from the reference counts).
               for S in 1 .. Ref_Shells loop
                  declare
                     NV, NE, NFS : Natural := 0;
                  begin
                     for X in 1 .. 5 loop
                        if Comp (X) = S then
                           NV := NV + 1;
                           for Y in X + 1 .. 5 loop
                              if D (X, Y) > 0 then
                                 NE := NE + 1;
                              end if;
                           end loop;
                        end if;
                     end loop;
                     for K in 1 .. NF loop
                        if Comp (Faces (K) (1)) = S then
                           NFS := NFS + 1;
                        end if;
                     end loop;
                     if R.Genus (S) * 2 /= 2 - (NV - NE + NFS) then
                        Disagree := Disagree + 1;
                     end if;
                  end;
               end loop;
            end if;
            pragma Assert (NF = 0 or else F /= Invalid_Face);
         end;
      end loop;
      Put_Line ("    " & Natural'Image (Meshes) & " meshes," & Natural'Image (Valid)
                & " closed manifolds by the reference," & Natural'Image (Disagree)
                & " disagreements");
      Check ("16.1 Check_Solid agrees with the reference on every mesh", Disagree = 0);
      Check ("16.2 both verdicts occur", Valid > 0 and then Valid < Meshes);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   
   if Fail_Count > 0 then
      Put_Line ("FAILED: Tests did not pass completely.");
   end if;

   if Fail_Count /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

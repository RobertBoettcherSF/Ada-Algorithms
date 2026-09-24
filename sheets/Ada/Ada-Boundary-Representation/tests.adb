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
      Check ("5.5 Is_Valid_Manifold", Is_Valid_Manifold (Model));
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

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   
   if Fail_Count > 0 then
      Put_Line ("FAILED: Tests did not pass completely.");
   end if;

   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

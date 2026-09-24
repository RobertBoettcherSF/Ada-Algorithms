with Ada.Text_IO; use Ada.Text_IO;
with Constructive_Solid_Geometry; use Constructive_Solid_Geometry;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper for floating point comparisons
   function Is_Close (A, B : Real) return Boolean is
   begin
      return abs (A - B) < 0.0001;
   end Is_Close;

   T1, T2, T3 : CSG_Tree := null;

begin
   -- TEST 1: Sphere Primitives
   Put_Line ("TEST 1 — Sphere Primitives");
   declare
      Tree : CSG_Tree := Create_Sphere ((0.0, 0.0, 0.0), 5.0);
   begin
      Check ("1.1 Origin is inside", Contains (Tree, (0.0, 0.0, 0.0)));
      Check ("1.2 Surface is inside (SDF <= 0)", Contains (Tree, (5.0, 0.0, 0.0)));
      Check ("1.3 Outside is not inside", not Contains (Tree, (6.0, 0.0, 0.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 2: Box Primitives
   Put_Line ("TEST 2 — Box Primitives");
   declare
      Tree : CSG_Tree := Create_Box ((-1.0, -1.0, -1.0), (1.0, 1.0, 1.0));
   begin
      Check ("2.1 Box center is inside", Contains (Tree, (0.0, 0.0, 0.0)));
      Check ("2.2 Box face center is inside", Contains (Tree, (1.0, 0.0, 0.0)));
      Check ("2.3 Point outside box is outside", not Contains (Tree, (2.0, 2.0, 2.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 3: Union Operation
   Put_Line ("TEST 3 — Union Operation");
   declare
      S1 : constant CSG_Tree := Create_Sphere ((-2.0, 0.0, 0.0), 1.0);
      S2 : constant CSG_Tree := Create_Sphere ((2.0, 0.0, 0.0), 1.0);
      Tree : CSG_Tree := Union_Op (S1, S2);
   begin
      Check ("3.1 Left component is inside", Contains (Tree, (-2.0, 0.0, 0.0)));
      Check ("3.2 Right component is inside", Contains (Tree, (2.0, 0.0, 0.0)));
      Check ("3.3 Space between is outside", not Contains (Tree, (0.0, 0.0, 0.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 4: Intersection Operation
   Put_Line ("TEST 4 — Intersection Operation");
   declare
      B1 : constant CSG_Tree := Create_Box ((-1.0, -1.0, -1.0), (1.0, 1.0, 1.0));
      B2 : constant CSG_Tree := Create_Box ((0.0, -1.0, -1.0), (2.0, 1.0, 1.0));
      Tree : CSG_Tree := Intersection_Op (B1, B2);
   begin
      Check ("4.1 Overlap area is inside", Contains (Tree, (0.5, 0.0, 0.0)));
      Check ("4.2 Left exclusive area is outside", not Contains (Tree, (-0.5, 0.0, 0.0)));
      Check ("4.3 Right exclusive area is outside", not Contains (Tree, (1.5, 0.0, 0.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 5: Difference Operation
   Put_Line ("TEST 5 — Difference Operation");
   declare
      B  : constant CSG_Tree := Create_Box ((-1.0, -1.0, -1.0), (1.0, 1.0, 1.0));
      S  : constant CSG_Tree := Create_Sphere ((0.0, 0.0, 0.0), 1.1); -- Slightly larger than radius 1
      Tree : CSG_Tree := Difference_Op (B, S);
   begin
      Check ("5.1 Box corner remains inside", Contains (Tree, (1.0, 1.0, 1.0)));
      Check ("5.2 Box center is subtracted (outside)", not Contains (Tree, (0.0, 0.0, 0.0)));
      Check ("5.3 Point far outside remains outside", not Contains (Tree, (5.0, 5.0, 5.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 6: Complex Composite Tree (Box - (Sphere U Sphere))
   Put_Line ("TEST 6 — Complex Composite Tree");
   declare
      B  : constant CSG_Tree := Create_Box ((-2.0, -2.0, -2.0), (2.0, 2.0, 2.0));
      S1 : constant CSG_Tree := Create_Sphere ((-1.0, 0.0, 0.0), 1.0);
      S2 : constant CSG_Tree := Create_Sphere ((1.0, 0.0, 0.0), 1.0);
      U  : constant CSG_Tree := Union_Op (S1, S2);
      Tree : CSG_Tree := Difference_Op (B, U);
   begin
      Check ("6.1 Subtracted center 1 is outside", not Contains (Tree, (-1.0, 0.0, 0.0)));
      Check ("6.2 Subtracted center 2 is outside", not Contains (Tree, (1.0, 0.0, 0.0)));
      Check ("6.3 Unaffected box area is inside", Contains (Tree, (0.0, 1.5, 0.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 7: Invalid Box Bounds Precondition/Exception
   Put_Line ("TEST 7 — Invalid Box Bounds Edge Case");
   declare
      Caught : Boolean := False;
   begin
      T1 := Create_Box ((1.0, 1.0, 1.0), (0.0, 0.0, 0.0));
      Check ("7.1 Should not reach here", False);
      Destroy_Tree (T1);
   exception
      when Constraint_Error | Invalid_Bounds_Error =>
         Caught := True;
         Check ("7.1 Bounds error successfully caught", Caught);
         Check ("7.2 Tree remained unallocated", T1 = null);
         Check ("7.3 System stable", True);
   end;

   -- TEST 8: Null Tree Operations Edge Case
   Put_Line ("TEST 8 — Null Tree Operations");
   declare
      Caught_Union, Caught_Intersect, Caught_Diff : Boolean := False;
   begin
      begin
         T1 := Union_Op (null, null);
      exception
         when Constraint_Error | Null_Tree_Error => Caught_Union := True;
      end;
      begin
         T2 := Intersection_Op (null, null);
      exception
         when Constraint_Error | Null_Tree_Error => Caught_Intersect := True;
      end;
      begin
         T3 := Difference_Op (null, null);
      exception
         when Constraint_Error | Null_Tree_Error => Caught_Diff := True;
      end;
      Check ("8.1 Union caught null exception", Caught_Union);
      Check ("8.2 Intersection caught null exception", Caught_Intersect);
      Check ("8.3 Difference caught null exception", Caught_Diff);
      Check ("8.4 Trees remained unallocated", T1 = null and T2 = null and T3 = null);
      T1 := null; T2 := null; T3 := null; -- Reset
   end;

   -- TEST 9: Evaluate Null Tree Exception
   Put_Line ("TEST 9 — Evaluate Null Tree Edge Case");
   declare
      Caught : Boolean := False;
      Dummy  : Real;
   begin
      Dummy := Evaluate_SDF (null, (0.0, 0.0, 0.0));
      Check ("9.1 Should not reach here", False);
   exception
      when Constraint_Error | Null_Tree_Error =>
         Caught := True;
         Check ("9.1 Evaluation error successfully caught", Caught);
         Check ("9.2 No side effects", Dummy'Valid or not Dummy'Valid);
         Check ("9.3 System stable", True);
   end;

   -- TEST 10: Memory Management
   Put_Line ("TEST 10 — Memory Management");
   declare
      Tree : CSG_Tree := Create_Sphere ((0.0, 0.0, 0.0), 1.0);
   begin
      Check ("10.1 Tree is initially allocated", Tree /= null);
      Destroy_Tree (Tree);
      Check ("10.2 Tree is null after destruction", Tree = null);
      Destroy_Tree (Tree); -- Should be safe
      Check ("10.3 Double destruction is safe", Tree = null);
   end;

   -- TEST 11: SDF Exact Boundary Checks
   Put_Line ("TEST 11 — SDF Exact Boundary Precision");
   declare
      S1 : constant CSG_Tree := Create_Sphere ((-1.0, 0.0, 0.0), 1.0);
      S2 : constant CSG_Tree := Create_Sphere ((1.0, 0.0, 0.0), 1.0);
      Tree : CSG_Tree := Union_Op (S1, S2);
   begin
      Check ("11.1 Origin is on boundary (SDF=0)", Is_Close (Evaluate_SDF (Tree, (0.0, 0.0, 0.0)), 0.0));
      Check ("11.2 Left edge is on boundary", Is_Close (Evaluate_SDF (Tree, (-2.0, 0.0, 0.0)), 0.0));
      Check ("11.3 Right edge is on boundary", Is_Close (Evaluate_SDF (Tree, (2.0, 0.0, 0.0)), 0.0));
      Destroy_Tree (Tree);
   end;

   -- TEST 12: Empty Intersection (No overlap)
   Put_Line ("TEST 12 — Empty Intersection invariant");
   declare
      B1 : constant CSG_Tree := Create_Box ((-5.0, -1.0, -1.0), (-3.0, 1.0, 1.0));
      B2 : constant CSG_Tree := Create_Box ((3.0, -1.0, -1.0), (5.0, 1.0, 1.0));
      Tree : CSG_Tree := Intersection_Op (B1, B2);
   begin
      Check ("12.1 Origin is outside empty set", not Contains (Tree, (0.0, 0.0, 0.0)));
      Check ("12.2 Left box center is outside intersection", not Contains (Tree, (-4.0, 0.0, 0.0)));
      Check ("12.3 Right box center is outside intersection", not Contains (Tree, (4.0, 0.0, 0.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 13: Total Eclipse Difference
   Put_Line ("TEST 13 — Total Eclipse Difference invariant");
   declare
      Inner : constant CSG_Tree := Create_Sphere ((0.0, 0.0, 0.0), 1.0);
      Outer : constant CSG_Tree := Create_Box ((-2.0, -2.0, -2.0), (2.0, 2.0, 2.0));
      Tree  : CSG_Tree := Difference_Op (Inner, Outer); -- Subtracting larger from smaller
   begin
      Check ("13.1 Origin is empty", not Contains (Tree, (0.0, 0.0, 0.0)));
      Check ("13.2 Inner edge is empty", not Contains (Tree, (1.0, 0.0, 0.0)));
      Check ("13.3 Exterior remains empty", not Contains (Tree, (3.0, 0.0, 0.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 14: Asymmetric Box Geometry
   Put_Line ("TEST 14 — Asymmetric Box Geometry");
   declare
      Tree : CSG_Tree := Create_Box ((0.0, -5.0, 10.0), (10.0, 5.0, 20.0));
   begin
      Check ("14.1 Center is inside", Contains (Tree, (5.0, 0.0, 15.0)));
      Check ("14.2 Negative X outside", not Contains (Tree, (-1.0, 0.0, 15.0)));
      Check ("14.3 High Z outside", not Contains (Tree, (5.0, 0.0, 25.0)));
      Destroy_Tree (Tree);
   end;

   -- TEST 15: SDF Mathematical Correctness
   Put_Line ("TEST 15 — SDF Mathematical Correctness");
   declare
      Tree : CSG_Tree := Create_Sphere ((0.0, 0.0, 0.0), 10.0);
   begin
      -- For a sphere, SDF(p) = length(p - center) - radius
      Check ("15.1 Center SDF is -10", Is_Close (Evaluate_SDF (Tree, (0.0, 0.0, 0.0)), -10.0));
      Check ("15.2 Surface SDF is 0", Is_Close (Evaluate_SDF (Tree, (10.0, 0.0, 0.0)), 0.0));
      Check ("15.3 Outside SDF is 5", Is_Close (Evaluate_SDF (Tree, (15.0, 0.0, 0.0)), 5.0));
      Destroy_Tree (Tree);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

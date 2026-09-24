--  Standalone test suite for Sweep_And_Prune (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Sweep_And_Prune; use Sweep_And_Prune;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Tiny deterministic LCG for random small worlds (modular wrap).
   type U32 is mod 2**32;
   Seed : U32 := 1;

   function Next_Rand return Natural is
   begin
      Seed := Seed * 1_664_525 + 1_013_904_223;
      return Natural (Seed mod 1_000_000);
   end Next_Rand;

   function Rand_Real (Lo, Hi : Real) return Real is
      T : constant Real := Real (Next_Rand mod 10_000) / 10_000.0;
   begin
      return Lo + T * (Hi - Lo);
   end Rand_Real;

   function Rand_Box (Lo, Hi, Size : Real) return AABB_2D is
      X0 : constant Real := Rand_Real (Lo, Hi);
      Y0 : constant Real := Rand_Real (Lo, Hi);
      SX : constant Real := Rand_Real (0.1, Size);
      SY : constant Real := Rand_Real (0.1, Size);
   begin
      return Make_AABB (X0, X0 + SX, Y0, Y0 + SY);
   end Rand_Box;

begin
   Put_Line ("Sweep_And_Prune test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. AABB validity / Make_AABB / projections");
   ---------------------------------------------------------------------
   declare
      A : constant AABB_2D := Make_AABB (0.0, 1.0, 0.0, 2.0);
      B : constant AABB_2D := Make_AABB (-1.0, 0.0, -1.0, 0.0);
      C : AABB_2D;
      Raised : Boolean;
   begin
      Check (Is_Valid_AABB (A), "unit-ish AABB valid");
      Check (Is_Valid_AABB (B), "negative-extent AABB valid");
      Check (A.Max_X = 1.0 and then A.Max_Y = 2.0, "Make_AABB fields");
      Check (Projections_Overlap (0.0, 1.0, 0.5, 1.5), "1D interior overlap");
      Check (Projections_Overlap (0.0, 1.0, 1.0, 2.0), "1D touching closed");
      Check (not Projections_Overlap (0.0, 1.0, 1.1, 2.0), "1D separated");
      Check (Projections_Overlap (0.0, 0.0, 0.0, 0.0), "1D point=point");
      Check (not Projections_Overlap (0.0, 1.0, 2.0, 3.0), "1D far apart");
      C := (1.0, 0.0, 0.0, 1.0);
      Check (not Is_Valid_AABB (C), "inverted X invalid");
      Raised := False;
      begin
         declare
            Unused : AABB_2D;
         begin
            Unused := Make_AABB (1.0, 0.0, 0.0, 1.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_AABB inverted raises");
   end;

   ---------------------------------------------------------------------
   Section ("2. AABBs_Overlap 2-D (closed)");
   ---------------------------------------------------------------------
   declare
      A : constant AABB_2D := Make_AABB (0.0, 1.0, 0.0, 1.0);
      B : constant AABB_2D := Make_AABB (0.5, 1.5, 0.5, 1.5);
      C : constant AABB_2D := Make_AABB (2.0, 3.0, 2.0, 3.0);
      D : constant AABB_2D := Make_AABB (1.0, 2.0, 0.0, 1.0);  -- touch on X
      E : constant AABB_2D := Make_AABB (0.0, 1.0, 1.0, 2.0);  -- touch on Y
      F : constant AABB_2D := Make_AABB (1.0, 2.0, 1.0, 2.0);  -- corner touch
      G : constant AABB_2D := Make_AABB (0.2, 0.8, 0.2, 0.8);  -- contained
   begin
      Check (AABBs_Overlap (A, B), "partial overlap");
      Check (AABBs_Overlap (A => B, B => A), "overlap symmetric");
      Check (not AABBs_Overlap (A, C), "far disjoint");
      Check (AABBs_Overlap (A, D), "touching Max_X=Min_X closed");
      Check (AABBs_Overlap (A, E), "touching Max_Y=Min_Y closed");
      Check (AABBs_Overlap (A, F), "corner-touch closed");
      Check (AABBs_Overlap (A, G), "contained box overlaps");
      Check (AABBs_Overlap (A, A), "self-identical extents overlap");
      Check (not AABBs_Overlap (A, Make_AABB (1.01, 2.0, 0.0, 1.0)),
             "epsilon gap X no overlap");
      Check (not AABBs_Overlap (A, Make_AABB (0.0, 1.0, 1.01, 2.0)),
             "epsilon gap Y no overlap");
   end;

   ---------------------------------------------------------------------
   Section ("3. Empty / single / disjoint worlds");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      P : Pair_List;
   begin
      Check (W.Count = 0, "Empty_World count 0");
      P := Find_Overlapping_Pairs_Brute (W);
      Check (P.Count = 0, "brute empty -> 0 pairs");
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 0, "SAP empty -> 0 pairs");

      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Check (W.Count = 1, "single box count 1");
      P := Find_Overlapping_Pairs_Brute (W);
      Check (P.Count = 0, "brute single -> 0 pairs");
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 0, "SAP single -> 0 pairs");

      Add_Box (W, Make_AABB (5.0, 6.0, 5.0, 6.0));
      Add_Box (W, Make_AABB (-3.0, -2.0, 0.0, 1.0));
      P := Find_Overlapping_Pairs_Brute (W);
      Check (P.Count = 0, "brute three disjoint -> 0");
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 0, "SAP three disjoint -> 0");
      Check (Same_Pair_Set
               (Find_Overlapping_Pairs_Brute (W),
                Find_Overlapping_Pairs_SAP (W)),
             "SAP ≡ brute on disjoint trio");
   end;

   ---------------------------------------------------------------------
   Section ("4. Overlapping report unordered pairs once");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      P : Pair_List;
      Q : Pair_List;
   begin
      Add_Box (W, Make_AABB (0.0, 2.0, 0.0, 2.0));
      Add_Box (W, Make_AABB (1.0, 3.0, 1.0, 3.0));
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "two overlapping -> one pair");
      Check (Contains_Pair (P, 1, 2), "pair (1,2) present");
      Check (Contains_Pair (P, 2, 1), "pair (2,1) same unordered");
      Check (P.Items (1).A < P.Items (1).B, "canonical A < B");

      Add_Box (W, Make_AABB (1.5, 2.5, 1.5, 2.5));  -- overlaps both
      P := Find_Overlapping_Pairs_SAP (W);
      Q := Find_Overlapping_Pairs_Brute (W);
      Check (P.Count = 3, "triangle of overlaps count 3");
      Check (Same_Pair_Set (P, Q), "SAP ≡ brute triangle");
      Check (Contains_Pair (P, 1, 2), "has (1,2)");
      Check (Contains_Pair (P, 1, 3), "has (1,3)");
      Check (Contains_Pair (P, 2, 3), "has (2,3)");

      --  Append_Pair dedup
      Clear (P);
      Append_Pair (P, 2, 1);
      Append_Pair (P, 1, 2);
      Check (P.Count = 1, "Append_Pair deduplicates");
   end;

   ---------------------------------------------------------------------
   Section ("5. Touching edges (closed convention)");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      P : Pair_List;
   begin
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (1.0, 2.0, 0.0, 1.0));  -- share right/left edge
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "edge-touch X counted");
      Check (Same_Pair_Set (P, Find_Overlapping_Pairs_Brute (W)),
             "SAP ≡ brute edge-touch X");

      Clear (W);
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (0.0, 1.0, 1.0, 2.0));  -- share top/bottom
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "edge-touch Y counted");

      Clear (W);
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (1.0, 2.0, 1.0, 2.0));  -- corner
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "corner-touch counted");

      Clear (W);
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (1.0001, 2.0, 0.0, 1.0));
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 0, "tiny gap not counted");
   end;

   ---------------------------------------------------------------------
   Section ("6. Pair helpers / Make_Pair / Normalize");
   ---------------------------------------------------------------------
   declare
      P : Pair_List := Empty_Pair_List;
      R : Pair;
      Raised : Boolean;
   begin
      Check (P.Count = 0, "Empty_Pair_List");
      R := Make_Pair (5, 2);
      Check (R.A = 2 and then R.B = 5, "Make_Pair sorts ids");
      Append_Pair (P, 3, 1);
      Append_Pair (P, 4, 2);
      Append_Pair (P, 3, 1);
      Check (P.Count = 2, "dedup on append");
      Normalize_Pairs (P);
      Check (P.Items (1).A = 1 and then P.Items (1).B = 3, "normalize order 1");
      Check (P.Items (2).A = 2 and then P.Items (2).B = 4, "normalize order 2");
      Raised := False;
      begin
         declare
            Unused_P : Pair;
         begin
            Unused_P := Make_Pair (1, 1);
            pragma Unreferenced (Unused_P);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_Pair identical raises");
      Clear (P);
      Check (P.Count = 0, "Clear pair list");
   end;

   ---------------------------------------------------------------------
   Section ("7. Endpoints build / sort / Update_Sorted");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      Eps : Endpoint_Array;
      N   : Endpoint_Count;
   begin
      Add_Box (W, Make_AABB (2.0, 5.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (1.0, 3.0, 0.0, 1.0));
      Build_Endpoints (W, Axis_X, Eps, N);
      Check (N = 6, "3 boxes -> 6 endpoints");
      Check (not Endpoints_Sorted (Eps, N), "unsorted before Sort");
      Sort_Endpoints (Eps, N);
      Check (Endpoints_Sorted (Eps, N), "sorted after Sort_Endpoints");
      Check (Eps (1).Value = 0.0 and then Eps (1).Kind = 1, "first is start@0");
      --  Disturb slightly then Update_Sorted
      declare
         T : constant Endpoint := Eps (2);
      begin
         Eps (2) := Eps (4);
         Eps (4) := T;
      end;
      Check (not Endpoints_Sorted (Eps, N), "disturbed unsorted");
      Update_Sorted (Eps, N);
      Check (Endpoints_Sorted (Eps, N), "Update_Sorted restores");

      Build_Endpoints (W, Axis_Y, Eps, N);
      Sort_Endpoints (Eps, N);
      Check (Endpoints_Sorted (Eps, N), "Y endpoints sorted");
      Check (N = 6, "Y also 6 endpoints");
   end;

   ---------------------------------------------------------------------
   Section ("8. 1-D overlap pairs vs filter");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      PX, PY, Full : Pair_List;
   begin
      --  Overlap on X only (stacked vertically with gap)
      Add_Box (W, Make_AABB (0.0, 2.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (1.0, 3.0, 3.0, 4.0));
      PX := Find_1D_Overlap_Pairs (W, Axis_X);
      PY := Find_1D_Overlap_Pairs (W, Axis_Y);
      Full := Find_Overlapping_Pairs_SAP (W);
      Check (PX.Count = 1, "1D X overlap yes");
      Check (PY.Count = 0, "1D Y overlap no");
      Check (Full.Count = 0, "2D SAP filters Y miss");

      Clear (W);
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 2.0));
      Add_Box (W, Make_AABB (3.0, 4.0, 1.0, 3.0));
      PX := Find_1D_Overlap_Pairs (W, Axis_X);
      PY := Find_1D_Overlap_Pairs (W, Axis_Y);
      Full := Find_Overlapping_Pairs_SAP (W);
      Check (PX.Count = 0, "1D X miss");
      Check (PY.Count = 1, "1D Y hit");
      Check (Full.Count = 0, "2D SAP needs both axes");
   end;

   ---------------------------------------------------------------------
   Section ("9. Moving boxes / Set_Box update");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      P : Pair_List;
   begin
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (5.0, 6.0, 5.0, 6.0));
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 0, "initially disjoint");
      Set_Box (W, 2, Make_AABB (0.5, 1.5, 0.5, 1.5));
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "after move: overlap");
      Check (Same_Pair_Set (P, Find_Overlapping_Pairs_Brute (W)),
             "SAP ≡ brute after move");
      Set_Box (W, 2, Make_AABB (10.0, 11.0, 10.0, 11.0));
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 0, "moved away again");
      Clear (W);
      Check (W.Count = 0, "Clear world");
   end;

   ---------------------------------------------------------------------
   Section ("10. SAP ≡ brute on random small sets");
   ---------------------------------------------------------------------
   declare
      Trials_Ok : Natural := 0;
   begin
      for Trial in 1 .. 20 loop
         declare
            W : World := Empty_World;
            N : constant Positive := 1 + (Next_Rand mod 12);  -- 1..12
            Brute, SAP : Pair_List;
         begin
            for K in 1 .. N loop
               Add_Box (W, Rand_Box (0.0, 10.0, 3.0));
            end loop;
            Brute := Find_Overlapping_Pairs_Brute (W);
            SAP := Find_Overlapping_Pairs_SAP (W);
            if Same_Pair_Set (Brute, SAP) then
               Trials_Ok := Trials_Ok + 1;
            end if;
         end;
      end loop;
      Check (Trials_Ok = 20, "20/20 random trials SAP ≡ brute");
      --  Extra individual checks for a few fixed seeds
      Seed := 42;
      declare
         W : World := Empty_World;
      begin
         for K in 1 .. 8 loop
            Add_Box (W, Rand_Box (-5.0, 5.0, 2.5));
         end loop;
         Check (Same_Pair_Set
                  (Find_Overlapping_Pairs_Brute (W),
                   Find_Overlapping_Pairs_SAP (W)),
                "seed 42 n=8 agree");
      end;
      Seed := 99;
      declare
         W : World := Empty_World;
      begin
         for K in 1 .. 15 loop
            Add_Box (W, Rand_Box (0.0, 20.0, 4.0));
         end loop;
         Check (Same_Pair_Set
                  (Find_Overlapping_Pairs_Brute (W),
                   Find_Overlapping_Pairs_SAP (W)),
                "seed 99 n=15 agree");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. All-overlap cluster / chain");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      P : Pair_List;
   begin
      for I in 1 .. 5 loop
         Add_Box (W, Make_AABB (Real (I) * 0.1, Real (I) * 0.1 + 2.0,
                                Real (I) * 0.1, Real (I) * 0.1 + 2.0));
      end loop;
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 10, "5 mutual overlaps -> C(5,2)=10");
      Check (Same_Pair_Set (P, Find_Overlapping_Pairs_Brute (W)),
             "cluster SAP ≡ brute");

      Clear (W);
      --  Horizontal chain: each touches next
      for I in 0 .. 4 loop
         Add_Box (W, Make_AABB (Real (I), Real (I) + 1.0, 0.0, 1.0));
      end loop;
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 4, "5-box edge chain -> 4 pairs");
      Check (Contains_Pair (P, 1, 2), "chain (1,2)");
      Check (Contains_Pair (P, 4, 5), "chain (4,5)");
      Check (not Contains_Pair (P, 1, 3), "non-adjacent not paired");
   end;

   ---------------------------------------------------------------------
   Section ("12. 3-D AABB / SAP / brute");
   ---------------------------------------------------------------------
   declare
      W : World_3D := Empty_World_3D;
      P : Pair_List;
      Raised : Boolean;
   begin
      Check (W.Count = 0, "Empty_World_3D");
      Add_Box (W, Make_AABB_3D (0.0, 1.0, 0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB_3D (0.5, 1.5, 0.5, 1.5, 0.5, 1.5));
      Check (AABBs_Overlap (W.Boxes (1), W.Boxes (2)), "3D overlap");
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "3D SAP one pair");
      Check (Same_Pair_Set (P, Find_Overlapping_Pairs_Brute (W)),
             "3D SAP ≡ brute");

      Add_Box (W, Make_AABB_3D (0.5, 1.5, 0.5, 1.5, 3.0, 4.0));  -- miss Z
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "3D Z-gap filters third");
      Check (not Contains_Pair (P, 1, 3), "no (1,3) on Z miss");
      Check (Same_Pair_Set (P, Find_Overlapping_Pairs_Brute (W)),
             "3D filtered SAP ≡ brute");

      --  Touching on Z
      Set_Box (W, 3, Make_AABB_3D (0.5, 1.5, 0.5, 1.5, 1.0, 2.0));
      P := Find_Overlapping_Pairs_SAP (W);
      Check (Contains_Pair (P, 1, 3), "3D Z-touch closed");
      Check (Contains_Pair (P, 2, 3), "3D (2,3) after Z-touch");

      Raised := False;
      begin
         declare
            Unused : AABB_3D;
         begin
            Unused := Make_AABB_3D (0.0, 1.0, 0.0, 1.0, 2.0, 1.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Make_AABB_3D inverted Z raises");
      Clear (W);
      Check (W.Count = 0, "Clear 3D world");
   end;

   ---------------------------------------------------------------------
   Section ("13. Endpoint tie order / identical Min");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      Eps : Endpoint_Array;
      N   : Endpoint_Count;
      P   : Pair_List;
   begin
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));  -- identical boxes
      Build_Endpoints (W, Axis_X, Eps, N);
      Sort_Endpoints (Eps, N);
      Check (Endpoints_Sorted (Eps, N), "identical boxes endpoints sorted");
      --  Both starts before both ends at shared values
      Check (Eps (1).Kind = 1 and then Eps (2).Kind = 1,
             "tied starts before ends");
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "identical boxes overlap once");
   end;

   ---------------------------------------------------------------------
   Section ("14. Capacity / invalid Set_Box");
   ---------------------------------------------------------------------
   declare
      W : World := Empty_World;
      Raised : Boolean;
   begin
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Raised := False;
      begin
         Set_Box (W, 2, Make_AABB (0.0, 1.0, 0.0, 1.0));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Set_Box id>Count raises");

      Raised := False;
      begin
         Set_Box (W, 1, (1.0, 0.0, 0.0, 1.0));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Set_Box invalid AABB raises");

      Check (Is_Valid_AABB (Make_AABB_3D (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)),
             "degenerate point AABB_3D valid");
      Check (AABBs_Overlap
               (Make_AABB (0.0, 0.0, 0.0, 0.0),
                Make_AABB (0.0, 0.0, 0.0, 0.0)),
             "point-point 2D overlap");
   end;

   ---------------------------------------------------------------------
   Section ("15. More SAP ≡ brute fixtures");
   ---------------------------------------------------------------------
   declare
      procedure Expect_Agree (Label : String; W : World) is
      begin
         Check (Same_Pair_Set
                  (Find_Overlapping_Pairs_Brute (W),
                   Find_Overlapping_Pairs_SAP (W)),
                Label);
      end Expect_Agree;

      W : World;
   begin
      W := Empty_World;
      Add_Box (W, Make_AABB (-10.0, -9.0, -10.0, -9.0));
      Add_Box (W, Make_AABB (9.0, 10.0, 9.0, 10.0));
      Expect_Agree ("far corners", W);

      W := Empty_World;
      Add_Box (W, Make_AABB (0.0, 10.0, 0.0, 10.0));
      Add_Box (W, Make_AABB (1.0, 2.0, 1.0, 2.0));
      Add_Box (W, Make_AABB (8.0, 9.0, 8.0, 9.0));
      Expect_Agree ("large container + two inside", W);
      Check (Find_Overlapping_Pairs_SAP (W).Count = 2,
             "container yields 2 pairs (not inner-inner)");

      W := Empty_World;
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            Add_Box (W, Make_AABB
              (Real (I) * 2.0, Real (I) * 2.0 + 2.5,
               Real (J) * 2.0, Real (J) * 2.0 + 2.5));
         end loop;
      end loop;
      Expect_Agree ("4x4 grid mild overlap", W);
      Check (Find_Overlapping_Pairs_SAP (W).Count > 0, "grid has overlaps");

      W := Empty_World;
      Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
      Add_Box (W, Make_AABB (0.0, 1.0, 2.0, 3.0));
      Add_Box (W, Make_AABB (2.0, 3.0, 0.0, 1.0));
      Expect_Agree ("L-shape no 2D pairs", W);
      Check (Find_Overlapping_Pairs_SAP (W).Count = 0, "L-shape zero pairs");
   end;

   ---------------------------------------------------------------------
   Section ("16. 3-D endpoints / moving 3-D");
   ---------------------------------------------------------------------
   declare
      W : World_3D := Empty_World_3D;
      Eps : Endpoint_Array;
      N   : Endpoint_Count;
      P   : Pair_List;
   begin
      Add_Box (W, Make_AABB_3D (0.0, 2.0, 0.0, 2.0, 0.0, 2.0));
      Add_Box (W, Make_AABB_3D (3.0, 4.0, 3.0, 4.0, 3.0, 4.0));
      Build_Endpoints (W, Axis_Z, Eps, N);
      Check (N = 4, "2 boxes 3D -> 4 Z endpoints");
      Sort_Endpoints (Eps, N);
      Check (Endpoints_Sorted (Eps, N), "3D Z sorted");
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 0, "3D initially apart");
      Set_Box (W, 2, Make_AABB_3D (1.0, 3.0, 1.0, 3.0, 1.0, 3.0));
      P := Find_Overlapping_Pairs_SAP (W);
      Check (P.Count = 1, "3D after move overlap");
      Check (Same_Pair_Set (P, Find_Overlapping_Pairs_Brute (W)),
             "3D move SAP ≡ brute");
   end;

   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed");
   pragma Assert (Fail_Count = 0);
end Tests;

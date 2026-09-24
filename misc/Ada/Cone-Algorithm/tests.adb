--  Standalone test suite for Cone_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Cone_Algorithm; use Cone_Algorithm;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function R (X : Real) return Real is (X);
   function P (X, Y, Z : Real) return Point is
     ((X => X, Y => Y, Z => Z));

   function Raised_Surface
     (Pts : Point_Array; Idx : Positive; Cut, Ang : Real) return Boolean
   is
      B : Boolean;
   begin
      B := Is_Surface_Particle (Pts, Idx, Cut, Ang);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Surface;

   function Raised_Mask
     (Pts : Point_Array; Cut, Ang : Real) return Boolean
   is
      M : Boolean_Array (Pts'Range);
   begin
      M := Surface_Mask (Pts, Cut, Ang);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Mask;

   function Raised_Count
     (Pts : Point_Array; Cut, Ang : Real) return Boolean
   is
      C : Point_Count;
   begin
      C := Count_Surface (Pts, Cut, Ang);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Count;

   function Raised_Extract
     (Pts : Point_Array; Cut, Ang : Real) return Boolean
   is
   begin
      declare
         E : constant Point_Array := Extract_Surface (Pts, Cut, Ang);
      begin
         pragma Unreferenced (E);
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Extract;

   function Raised_Asym
     (Pts : Point_Array; Idx : Positive; Cut, Thr : Real) return Boolean
   is
      B : Boolean;
   begin
      B := Is_Surface_By_Asymmetry (Pts, Idx, Cut, Thr);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Asym;

   function Empty_Set return Point_Array is
      Pts : Point_Array (1 .. 0);
   begin
      return Pts;
   end Empty_Set;

   ------------------------------------------------------------------
   -- Helpers to build clusters
   ------------------------------------------------------------------

   function Make_Cube_3 return Point_Array is
      --  3×3×3 grid, spacing 1, centered near origin: coords in {-1,0,1}.
      Pts : Point_Array (1 .. 27);
      K   : Natural := 0;
   begin
      for XI in -1 .. 1 loop
         for YI in -1 .. 1 loop
            for ZI in -1 .. 1 loop
               K := K + 1;
               Pts (K) := P (Real (XI), Real (YI), Real (ZI));
            end loop;
         end loop;
      end loop;
      return Pts;
   end Make_Cube_3;

   function Make_Cube_5 return Point_Array is
      --  5×5×5 = 125 > Max_Points; build a hollow-ish 3-layer subset:
      --  actually build points with coords in {-2,-1,0,1,2} but only
      --  keep a 4×4×4 = 64 max. Use {-1.5,-0.5,0.5,1.5}^3 = 64 points.
      Pts : Point_Array (1 .. 64);
      K   : Natural := 0;
      Coords : constant array (1 .. 4) of Real :=
        [R (-1.5), R (-0.5), R (0.5), R (1.5)];
   begin
      for XI in Coords'Range loop
         for YI in Coords'Range loop
            for ZI in Coords'Range loop
               K := K + 1;
               Pts (K) := P (Coords (XI), Coords (YI), Coords (ZI));
            end loop;
         end loop;
      end loop;
      return Pts;
   end Make_Cube_5;

   function Make_Chain (N : Positive) return Point_Array is
      Pts : Point_Array (1 .. N);
   begin
      for I in 1 .. N loop
         Pts (I) := P (Real (I - 1), 0.0, 0.0);
      end loop;
      return Pts;
   end Make_Chain;

   function Make_Sheet_3x3 return Point_Array is
      Pts : Point_Array (1 .. 9);
      K   : Natural := 0;
   begin
      for XI in -1 .. 1 loop
         for YI in -1 .. 1 loop
            K := K + 1;
            Pts (K) := P (Real (XI), Real (YI), 0.0);
         end loop;
      end loop;
      return Pts;
   end Make_Sheet_3x3;

   function Make_Dense_Blob return Point_Array is
      --  Solid 3×3×3 plus an outer shell ring? Use 3×3×3 with spacing 1
      --  already. Build a denser FCC-like tetrahedral cluster of 14 pts:
      --  cube corners + face centers (FCC conventional cell fragment).
      Pts : Point_Array (1 .. 14);
   begin
      --  Cube corners
      Pts (1)  := P (0.0, 0.0, 0.0);
      Pts (2)  := P (1.0, 0.0, 0.0);
      Pts (3)  := P (0.0, 1.0, 0.0);
      Pts (4)  := P (1.0, 1.0, 0.0);
      Pts (5)  := P (0.0, 0.0, 1.0);
      Pts (6)  := P (1.0, 0.0, 1.0);
      Pts (7)  := P (0.0, 1.0, 1.0);
      Pts (8)  := P (1.0, 1.0, 1.0);
      --  Face centers
      Pts (9)  := P (0.5, 0.5, 0.0);
      Pts (10) := P (0.5, 0.5, 1.0);
      Pts (11) := P (0.5, 0.0, 0.5);
      Pts (12) := P (0.5, 1.0, 0.5);
      Pts (13) := P (0.0, 0.5, 0.5);
      Pts (14) := P (1.0, 0.5, 0.5);
      return Pts;
   end Make_Dense_Blob;

   function Find_Center_Index (Pts : Point_Array) return Positive is
      Best_I : Positive := Pts'First;
      Best_N : Real := Real'Last;
      N2     : Real;
   begin
      for I in Pts'Range loop
         N2 := Norm2 (Pts (I));
         if N2 < Best_N then
            Best_N := N2;
            Best_I := I;
         end if;
      end loop;
      return Best_I;
   end Find_Center_Index;

   function Find_Corner_Index (Pts : Point_Array) return Positive is
      Best_I : Positive := Pts'First;
      Best_N : Real := -1.0;
      N2     : Real;
   begin
      for I in Pts'Range loop
         N2 := Norm2 (Pts (I));
         if N2 > Best_N then
            Best_N := N2;
            Best_I := I;
         end if;
      end loop;
      return Best_I;
   end Find_Corner_Index;

begin
   Ada.Text_IO.Put_Line ("Cone_Algorithm test suite");
   Ada.Text_IO.Put_Line ("Max_Points =" & Positive'Image (Max_Points));

   ------------------------------------------------------------------
   Section ("Numeric helpers");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (R (1.0), R (0.0), R (0.0));
      B : constant Point := P (R (0.0), R (1.0), R (0.0));
      C : constant Point := P (R (1.0), R (1.0), R (1.0));
      Z : constant Point := P (R (0.0), R (0.0), R (0.0));
      N : Point;
      X : Point;
   begin
      Check (Near (Dist2 (A, B), R (2.0)), "Dist2 e1 e2 = 2");
      Check (Near (Dist (A, Z), R (1.0)), "Dist e1 origin = 1");
      Check (Near (Dot (A, B), R (0.0)), "Dot e1 e2 = 0");
      Check (Near (Dot (A, A), R (1.0)), "Dot e1 e1 = 1");
      X := Cross (A, B);
      Check (Near_Point (X, P (0.0, 0.0, 1.0)), "Cross e1×e2 = e3");
      Check (Near (Norm (C) * Norm (C), R (3.0)), "Norm (1,1,1)^2 = 3");
      N := Normalize (C);
      Check (Near (Norm (N), R (1.0)), "Normalize (1,1,1) unit");
      Check (Near_Point (Normalize (Z), Z), "Normalize zero → zero");
      Check (Near_Point (Add (A, B), P (1.0, 1.0, 0.0)), "Add");
      Check (Near_Point (Sub (A, B), P (1.0, -1.0, 0.0)), "Sub");
      Check (Near_Point (Scale (A, R (2.0)), P (2.0, 0.0, 0.0)), "Scale");
      Check (Near (R (1.0), R (1.0)), "Near equal");
      Check (not Near (R (1.0), R (2.0)), "Near unequal");
   end;

   ------------------------------------------------------------------
   Section ("Invalid arguments");
   ------------------------------------------------------------------
   declare
      One  : constant Point_Array := [1 => P (0.0, 0.0, 0.0)];
      Big  : Point_Array (1 .. Max_Points + 1);
      Cut  : constant Real := R (1.5);
      Ang  : constant Real := Default_Half_Angle;
   begin
      for I in Big'Range loop
         Big (I) := P (Real (I), 0.0, 0.0);
      end loop;

      Check (Raised_Surface (Empty_Set, 1, Cut, Ang),
             "empty → Invalid (Is_Surface)");
      Check (Raised_Mask (Empty_Set, Cut, Ang),
             "empty → Invalid (Mask)");
      Check (Raised_Count (Empty_Set, Cut, Ang),
             "empty → Invalid (Count)");
      Check (Raised_Extract (Empty_Set, Cut, Ang),
             "empty → Invalid (Extract)");
      Check (Raised_Surface (Big, 1, Cut, Ang),
             "oversized → Invalid");
      Check (Raised_Surface (One, 2, Cut, Ang),
             "bad index → Invalid");
      Check (Raised_Surface (One, 1, R (0.0), Ang),
             "cutoff 0 → Invalid");
      Check (Raised_Surface (One, 1, R (-1.0), Ang),
             "cutoff negative → Invalid");
      Check (Raised_Surface (One, 1, Cut, R (0.0)),
             "half-angle 0 → Invalid");
      Check (Raised_Surface (One, 1, Cut, R (-0.1)),
             "half-angle negative → Invalid");
      Check (Raised_Surface (One, 1, Cut, Half_Pi + R (0.01)),
             "half-angle > π/2 → Invalid");
      Check (not Raised_Surface (One, 1, Cut, Half_Pi),
             "half-angle = π/2 accepted");
      Check (Raised_Asym (One, 1, R (0.0), R (0.5)),
             "asym: bad cutoff → Invalid");
      Check (Raised_Asym (One, 1, Cut, R (-0.1)),
             "asym: negative threshold → Invalid");
      Check (Raised_Asym (Empty_Set, 1, Cut, R (0.5)),
             "asym: empty → Invalid");
   end;

   ------------------------------------------------------------------
   Section ("Single particle / isolated");
   ------------------------------------------------------------------
   declare
      One : constant Point_Array := [1 => P (R (0.0), R (0.0), R (0.0))];
      Far : constant Point_Array :=
        [P (0.0, 0.0, 0.0),
         P (10.0, 0.0, 0.0),
         P (0.0, 10.0, 0.0),
         P (0.0, 0.0, 10.0)];
      Cut : constant Real := R (1.5);
      Ang : constant Real := Default_Half_Angle;
   begin
      Check (Is_Surface_Particle (One, 1, Cut, Ang),
             "single particle is surface");
      Check (Count_Surface (One, Cut, Ang) = 1,
             "single: Count_Surface = 1");
      Check (Extract_Surface (One, Cut, Ang)'Length = 1,
             "single: Extract length 1");
      Check (Extract_Surface_Indices (One, Cut, Ang)'Length = 1,
             "single: indices length 1");

      Check (Count_Surface (Far, Cut, Ang) = 4,
             "all far apart → all 4 surface");
      for I in Far'Range loop
         Check (Is_Surface_Particle (Far, I, Cut, Ang),
                "far particle" & Positive'Image (I) & " surface");
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("Two-particle pair");
   ------------------------------------------------------------------
   declare
      Pair : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0)];
      Cut  : constant Real := R (1.5);
      Ang  : constant Real := Default_Half_Angle;
   begin
      Check (Is_Surface_Particle (Pair, 1, Cut, Ang),
             "pair[1] surface");
      Check (Is_Surface_Particle (Pair, 2, Cut, Ang),
             "pair[2] surface");
      Check (Count_Surface (Pair, Cut, Ang) = 2,
             "pair: both surface");
   end;

   ------------------------------------------------------------------
   Section ("Linear chain");
   ------------------------------------------------------------------
   declare
      Chain : constant Point_Array := Make_Chain (5);
      Cut   : constant Real := R (1.5);
      Ang   : constant Real := Default_Half_Angle;
      Mask  : Boolean_Array (Chain'Range);
   begin
      Mask := Surface_Mask (Chain, Cut, Ang);
      Check (Mask (1), "chain endpoint 1 surface");
      Check (Mask (5), "chain endpoint 5 surface");
      --  Thin 1-D chain: every particle has an empty cone off-axis.
      Check (Count_Surface (Chain, Cut, Ang) = 5,
             "chain: all 5 are surface (1-D)");
      for I in Chain'Range loop
         Check (Mask (I),
                "chain particle" & Positive'Image (I) & " surface");
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("Planar sheet");
   ------------------------------------------------------------------
   declare
      Sheet : constant Point_Array := Make_Sheet_3x3;
      Cut   : constant Real := R (1.5);
      Ang   : constant Real := Default_Half_Angle;
   begin
      --  Flat sheet: ±z empty cones → every particle is surface.
      Check (Count_Surface (Sheet, Cut, Ang) = 9,
             "sheet 3×3: all 9 surface");
      Check (Is_Surface_Particle (Sheet, 5, Cut, Ang),
             "sheet center is surface (planar)");
      Check (Is_Surface_Particle (Sheet, 1, Cut, Ang),
             "sheet corner is surface");
   end;

   ------------------------------------------------------------------
   Section ("3×3×3 cube: core vs shell");
   ------------------------------------------------------------------
   declare
      Cube   : constant Point_Array := Make_Cube_3;
      Cut    : constant Real := R (1.8);  -- face + edge neighbors
      Ang    : constant Real := Default_Half_Angle;  -- π/4
      Center : constant Positive := Find_Center_Index (Cube);
      Corner : constant Positive := Find_Corner_Index (Cube);
      Mask   : Boolean_Array (Cube'Range);
      Surf_N : Point_Count;
   begin
      Check (Cube'Length = 27, "cube 3×3×3 has 27 points");
      Check (Near_Point (Cube (Center), P (0.0, 0.0, 0.0)),
             "center index is origin");

      Check (not Is_Surface_Particle (Cube, Center, Cut, Ang),
             "cube center is bulk (interior)");
      Check (Is_Surface_Particle (Cube, Corner, Cut, Ang),
             "cube corner is surface");

      Mask := Surface_Mask (Cube, Cut, Ang);
      Check (not Mask (Center), "mask: center False");
      Check (Mask (Corner), "mask: corner True");

      Surf_N := Count_Surface (Cube, Cut, Ang);
      Check (Surf_N = 26, "cube: 26 surface (only center bulk)");
      Check (Surf_N + 1 = 27, "cube: surface + 1 = 27");

      declare
         E : constant Point_Array := Extract_Surface (Cube, Cut, Ang);
         I : constant Index_Array :=
           Extract_Surface_Indices (Cube, Cut, Ang);
      begin
         Check (E'Length = 26, "Extract_Surface length 26");
         Check (I'Length = 26, "Extract_Surface_Indices length 26");
         --  Center index must not appear.
         declare
            Found_Center : Boolean := False;
         begin
            for K in I'Range loop
               if I (K) = Center then
                  Found_Center := True;
               end if;
            end loop;
            Check (not Found_Center, "indices omit center");
         end;
      end;

      --  Face-center particle (1,0,0): should be surface.
      declare
         Face_I : Positive := Center;
         Found  : Boolean := False;
      begin
         for I in Cube'Range loop
            if Near_Point (Cube (I), P (1.0, 0.0, 0.0)) then
               Face_I := I;
               Found := True;
            end if;
         end loop;
         Check (Found, "found face-center (1,0,0)");
         Check (Is_Surface_Particle (Cube, Face_I, Cut, Ang),
                "face-center is surface");
      end;

      --  Edge-center (1,1,0): surface.
      declare
         Edge_I : Positive := Center;
         Found  : Boolean := False;
      begin
         for I in Cube'Range loop
            if Near_Point (Cube (I), P (1.0, 1.0, 0.0)) then
               Edge_I := I;
               Found := True;
            end if;
         end loop;
         Check (Found, "found edge-center (1,1,0)");
         Check (Is_Surface_Particle (Cube, Edge_I, Cut, Ang),
                "edge-center is surface");
      end;
   end;

   ------------------------------------------------------------------
   Section ("4×4×4 lattice: thicker core");
   ------------------------------------------------------------------
   declare
      Lat  : constant Point_Array := Make_Cube_5;  -- 64 pts
      Cut  : constant Real := R (1.2);  -- nearest only (spacing 1.0)
      Ang  : constant Real := Pi / 3.0;  -- 60°: stricter empty cone
      --  Interior-ish: points with all |coords| = 0.5
      Inner_Count : Natural := 0;
      Surf_Inner  : Natural := 0;
      Outer_Surf  : Natural := 0;
      Outer_Count : Natural := 0;
   begin
      Check (Lat'Length = 64, "4×4×4 has 64 points");
      Check (Count_Surface (Lat, Cut, Ang) >= 1,
             "4×4×4 has at least one surface");

      for I in Lat'Range loop
         declare
            Q : constant Point := Lat (I);
            Is_Inner : constant Boolean :=
              abs (Q.X) < R (1.0)
              and then abs (Q.Y) < R (1.0)
              and then abs (Q.Z) < R (1.0);
            --  |coord|=0.5 for all → the 8 innermost of the 4×4×4
         begin
            if Is_Inner then
               Inner_Count := Inner_Count + 1;
               if Is_Surface_Particle (Lat, I, Cut, Ang) then
                  Surf_Inner := Surf_Inner + 1;
               end if;
            else
               Outer_Count := Outer_Count + 1;
               if Is_Surface_Particle (Lat, I, Cut, Ang) then
                  Outer_Surf := Outer_Surf + 1;
               end if;
            end if;
         end;
      end loop;

      Check (Inner_Count = 8, "4×4×4 has 8 inner points");
      Check (Outer_Count = 56, "4×4×4 has 56 outer points");
      --  With NN cutoff and 60° half-angle, the 8-point inner cube may
      --  still look surface-like (only 8 pts). Prefer: outer shell has
      --  many surface particles.
      Check (Outer_Surf >= 24,
             "outer shell has many surface particles");
      Check (Count_Surface (Lat, Cut, Default_Half_Angle) =
               Count_Surface (Lat, Cut, Default_Half_Angle),
             "Count_Surface idempotent");
   end;

   ------------------------------------------------------------------
   Section ("FCC-like / dense blob");
   ------------------------------------------------------------------
   declare
      Blob : constant Point_Array := Make_Dense_Blob;
      Cut  : constant Real := R (1.1);
      Ang  : constant Real := Default_Half_Angle;
      N    : Point_Count;
   begin
      N := Count_Surface (Blob, Cut, Ang);
      Check (N >= 8, "FCC blob: at least 8 surface (corners)");
      Check (N <= 14, "FCC blob: at most 14 surface");
      --  Every corner of the conventional cube should be surface.
      for I in 1 .. 8 loop
         Check (Is_Surface_Particle (Blob, I, Cut, Ang),
                "FCC corner" & Positive'Image (I) & " surface");
      end loop;
      --  All particles in this small cluster are typically surface.
      Check (N = Count_Surface (Blob, Cut, Ang), "FCC count stable");
   end;

   ------------------------------------------------------------------
   Section ("Asymmetry oracle");
   ------------------------------------------------------------------
   declare
      Cube   : constant Point_Array := Make_Cube_3;
      Center : constant Positive := Find_Center_Index (Cube);
      Corner : constant Positive := Find_Corner_Index (Cube);
      Cut    : constant Real := R (1.8);
   begin
      Check (not Is_Surface_By_Asymmetry (Cube, Center, Cut, R (0.5)),
             "asym: center low asymmetry → bulk");
      Check (Is_Surface_By_Asymmetry (Cube, Corner, Cut, R (0.5)),
             "asym: corner high asymmetry → surface");
      Check (Is_Surface_By_Asymmetry
               ([1 => P (0.0, 0.0, 0.0)], 1, Cut, R (0.5)),
             "asym: isolated → surface");
   end;

   ------------------------------------------------------------------
   Section ("Parameter sensitivity / API glue");
   ------------------------------------------------------------------
   declare
      Cube : constant Point_Array := Make_Cube_3;
      Cut  : constant Real := R (1.8);
      Wide : constant Real := Pi / 3.0;       -- 60° harder empty cone
      Tiny : constant Real := Pi / 12.0;      -- 15° easier empty cone
   begin
      --  Wider half-angle ⇒ fewer (or equal) surface detections.
      Check (Count_Surface (Cube, Cut, Wide) <=
               Count_Surface (Cube, Cut, Tiny),
             "wider θ ⇒ ≤ surface count vs tiny θ");
      Check (not Is_Surface_Particle
               (Cube, Find_Center_Index (Cube), Cut, Wide),
             "center bulk at 60°");
      Check (Is_Surface_Particle
               (Cube, Find_Corner_Index (Cube), Cut, Wide),
             "corner surface at 60°");

      --  Very small cutoff → few neighbors → more surface.
      Check (Count_Surface (Cube, R (0.5), Default_Half_Angle) = 27,
             "tiny cutoff → all surface (no neighbors)");

      --  Default constants usable (force runtime compare via R).
      Check (Default_Cutoff > R (0.0), "Default_Cutoff positive");
      Check (Default_Half_Angle > R (0.0)
               and then Default_Half_Angle <= R (Half_Pi),
             "Default_Half_Angle in (0, π/2]");
   end;

   ------------------------------------------------------------------
   Section ("Mask / extract consistency");
   ------------------------------------------------------------------
   declare
      Pts  : constant Point_Array :=
        [P (0.0, 0.0, 0.0),
         P (1.0, 0.0, 0.0),
         P (0.5, 0.5, 0.5),
         P (2.0, 2.0, 2.0)];
      Cut  : constant Real := R (1.5);
      Ang  : constant Real := Default_Half_Angle;
      Mask : constant Boolean_Array := Surface_Mask (Pts, Cut, Ang);
      Ext  : constant Point_Array := Extract_Surface (Pts, Cut, Ang);
      Idx  : constant Index_Array :=
        Extract_Surface_Indices (Pts, Cut, Ang);
      Cnt  : constant Point_Count := Count_Surface (Pts, Cut, Ang);
   begin
      Check (Cnt = Ext'Length, "Count = Extract length");
      Check (Cnt = Idx'Length, "Count = Indices length");
      declare
         Ones : Natural := 0;
      begin
         for I in Mask'Range loop
            if Mask (I) then
               Ones := Ones + 1;
            end if;
         end loop;
         Check (Ones = Natural (Cnt), "mask True-count = Count");
      end;
      for K in Idx'Range loop
         Check (Mask (Idx (K)), "index points to masked surface");
         Check (Near_Point (Ext (K), Pts (Idx (K))),
                "extract matches index position");
      end loop;
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

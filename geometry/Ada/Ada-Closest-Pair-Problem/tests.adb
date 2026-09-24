--  Standalone test suite for Closest_Pair_Problem (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Closest_Pair_Problem; use Closest_Pair_Problem;

procedure Tests is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

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
   function P (X, Y : Real) return Point is ((X => X, Y => Y));

   function Raised_Invalid_BF (Pts : Point_Array) return Boolean is
      Res : Pair_Result;
   begin
      Res := Brute_Force (Pts);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_BF;

   function Raised_Invalid_DC (Pts : Point_Array) return Boolean is
      Res : Pair_Result;
   begin
      Res := Divide_And_Conquer (Pts);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_DC;

   function Raised_Invalid_CP (Pts : Point_Array) return Boolean is
      Res : Pair_Result;
   begin
      Res := Closest_Pair (Pts);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_CP;

   function Empty_Set return Point_Array is
      Z : Point_Array (1 .. 0);
   begin
      return Z;
   end Empty_Set;

   function Singleton return Point_Array is
      Z : constant Point_Array (1 .. 1) := [P (R (1.0), R (2.0))];
   begin
      return Z;
   end Singleton;

   function Too_Many return Point_Array is
      Z : Point_Array (1 .. Max_Points + 1);
   begin
      for I in Z'Range loop
         Z (I) := P (Real (I), Real (I) * R (0.5));
      end loop;
      return Z;
   end Too_Many;

   function Same_Unordered_Pair (A, B : Pair_Result) return Boolean is
   begin
      return A.Index_A = B.Index_A and then A.Index_B = B.Index_B;
   end Same_Unordered_Pair;

   function Dist_Match (A, B : Pair_Result; Tol : Real := 1.0E-8) return Boolean
   is
   begin
      return Near (A.Distance, B.Distance, Tol);
   end Dist_Match;

   procedure Check_Both
     (Pts     : Point_Array;
      Label   : String;
      Expect  : Real;
      Tol     : Real := 1.0E-8)
   is
      BF : constant Pair_Result := Brute_Force (Pts);
      DC : constant Pair_Result := Divide_And_Conquer (Pts);
      CP : constant Pair_Result := Closest_Pair (Pts);
   begin
      Check (Near (BF.Distance, Expect, Tol),
             Label & " brute distance");
      Check (Near (DC.Distance, Expect, Tol),
             Label & " D&C distance");
      Check (Near (CP.Distance, Expect, Tol),
             Label & " Closest_Pair distance");
      Check (Dist_Match (BF, DC, Tol),
             Label & " brute ≡ D&C distance");
      Check (BF.Index_A < BF.Index_B,
             Label & " brute Index_A < Index_B");
      Check (DC.Index_A < DC.Index_B,
             Label & " D&C Index_A < Index_B");
   end Check_Both;

   procedure Check_Agree (Pts : Point_Array; Label : String) is
      BF : constant Pair_Result := Brute_Force (Pts);
      DC : constant Pair_Result := Divide_And_Conquer (Pts);
      CM : constant Pair_Result := Closest_Pair (Pts, Brute);
      CD : constant Pair_Result := Closest_Pair (Pts, Divide_Conquer);
   begin
      Check (Dist_Match (BF, DC), Label & " brute ≡ D&C");
      Check (Dist_Match (BF, CM), Label & " Closest_Pair(Brute) ≡ brute");
      Check (Dist_Match (DC, CD), Label & " Closest_Pair(DC) ≡ D&C");
      Check (Same_Unordered_Pair (BF, CM)
             or else Dist_Match (BF, CM),
             Label & " method Brute pair ok");
   end Check_Agree;

   function Regular_Ngon (N : Positive; Radius : Real) return Point_Array is
      Pts : Point_Array (1 .. N);
      Two_Pi : constant Real := R (2.0) * Real (Ada.Numerics.Pi);
   begin
      for I in 1 .. N loop
         declare
            Ang : constant Real :=
              Two_Pi * Real (I - 1) / Real (N);
         begin
            Pts (I) := P
              (Radius * Real (Math.Cos (Long_Float (Ang))),
               Radius * Real (Math.Sin (Long_Float (Ang))));
         end;
      end loop;
      return Pts;
   end Regular_Ngon;

   --  Deterministic "random-ish" points from a simple LCG.
   function Next_State (S : Natural) return Natural is
      --  Small-modulus LCG to avoid Integer overflow under -gnata checks.
   begin
      return (S * 487 + 313) mod 10_000;
   end Next_State;

   function Pseudo_Random_Set
     (N : Positive; Seed : Natural) return Point_Array
   is
      Pts   : Point_Array (1 .. N);
      State : Natural := Seed mod 10_000;
   begin
      for I in 1 .. N loop
         State := Next_State (State);
         declare
            X : constant Real := Real (State) / R (1000.0) - R (5.0);
         begin
            State := Next_State (State);
            declare
               Y : constant Real := Real (State) / R (1000.0) - R (5.0);
            begin
               Pts (I) := P (X, Y);
            end;
         end;
      end loop;
      return Pts;
   end Pseudo_Random_Set;

begin
   Ada.Text_IO.Put_Line
     ("Closest_Pair_Problem — Ada 2023 educational test suite");

   ------------------------------------------------------------------
   Section ("Helpers: Dist / Dist2 / Near");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (R (0.0), R (0.0));
      B : constant Point := P (R (3.0), R (4.0));
   begin
      Check (Near (Dist2 (A, B), R (25.0)), "Dist2 (0,0)-(3,4) = 25");
      Check (Near (Dist (A, B), R (5.0)), "Dist (0,0)-(3,4) = 5");
      Check (Near (Dist (A, A), R (0.0)), "Dist self = 0");
      Check (Near (0.0, 0.0), "Near 0,0");
      Check (not Near (R (1.0), R (2.0)), "not Near 1,2");
      Check (Near_Point (A, A), "Near_Point identical");
      Check (not Near_Point (A, B), "not Near_Point distinct");
   end;

   ------------------------------------------------------------------
   Section ("Invalid arguments");
   ------------------------------------------------------------------
   Check (Raised_Invalid_BF (Empty_Set), "brute empty raises");
   Check (Raised_Invalid_DC (Empty_Set), "D&C empty raises");
   Check (Raised_Invalid_CP (Empty_Set), "Closest_Pair empty raises");
   Check (Raised_Invalid_BF (Singleton), "brute n=1 raises");
   Check (Raised_Invalid_DC (Singleton), "D&C n=1 raises");
   Check (Raised_Invalid_CP (Singleton), "Closest_Pair n=1 raises");
   Check (Raised_Invalid_BF (Too_Many), "brute oversized raises");
   Check (Raised_Invalid_DC (Too_Many), "D&C oversized raises");
   Check (Raised_Invalid_CP (Too_Many), "Closest_Pair oversized raises");

   ------------------------------------------------------------------
   Section ("Two points");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)), P (R (1.0), R (0.0))];
      BF  : constant Pair_Result := Brute_Force (Pts);
   begin
      Check_Both (Pts, "unit segment", R (1.0));
      Check (BF.Index_A = 1 and then BF.Index_B = 2,
             "two points indices 1,2");
   end;

   ------------------------------------------------------------------
   Section ("Duplicates → distance 0");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (R (1.0), R (2.0)),
         P (R (3.0), R (4.0)),
         P (R (1.0), R (2.0))];
      BF  : constant Pair_Result := Brute_Force (Pts);
      DC  : constant Pair_Result := Divide_And_Conquer (Pts);
   begin
      Check (Near (BF.Distance, R (0.0)), "dup brute dist 0");
      Check (Near (DC.Distance, R (0.0)), "dup D&C dist 0");
      Check (Dist_Match (BF, DC), "dup brute ≡ D&C");
      Check ((BF.Index_A = 1 and BF.Index_B = 3)
             or else (BF.Index_A = 1 and BF.Index_B = 1),
             "dup pair involves the duplicate indices");
      Check (BF.Index_A = 1 and then BF.Index_B = 3,
             "dup preferred indices 1,3");
   end;

   declare
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)), P (R (0.0), R (0.0))];
   begin
      Check_Both (Pts, "identical pair", R (0.0));
   end;

   ------------------------------------------------------------------
   Section ("Equilateral triangle");
   ------------------------------------------------------------------
   declare
      --  Side length 2: (0,0), (2,0), (1, √3)
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (2.0), R (0.0)),
         P (R (1.0), Real (Math.Sqrt (3.0)))];
   begin
      Check_Both (Pts, "equilateral side 2", R (2.0));
   end;

   ------------------------------------------------------------------
   Section ("Square");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (1.0), R (0.0)),
         P (R (1.0), R (1.0)),
         P (R (0.0), R (1.0))];
   begin
      Check_Both (Pts, "unit square", R (1.0));
   end;

   ------------------------------------------------------------------
   Section ("Collinear points");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (1.0), R (0.0)),
         P (R (3.0), R (0.0)),
         P (R (6.0), R (0.0))];
   begin
      Check_Both (Pts, "collinear gaps", R (1.0));
   end;

   declare
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (0.0), R (5.0)),
         P (R (0.0), R (2.0)),
         P (R (0.0), R (9.0))];
   begin
      Check_Both (Pts, "vertical collinear", R (2.0));
   end;

   ------------------------------------------------------------------
   Section ("Grid layouts");
   ------------------------------------------------------------------
   declare
      Pts : Point_Array (1 .. 9);
      K   : Point_Index := 1;
   begin
      for Y in 0 .. 2 loop
         for X in 0 .. 2 loop
            Pts (K) := P (Real (X), Real (Y));
            if K < 9 then
               K := K + 1;
            end if;
         end loop;
      end loop;
      Check_Both (Pts, "3x3 unit grid", R (1.0));
      Check_Agree (Pts, "3x3 grid");
   end;

   declare
      Pts : Point_Array (1 .. 16);
      K   : Point_Index := 1;
   begin
      for Y in 0 .. 3 loop
         for X in 0 .. 3 loop
            Pts (K) := P (Real (X) * R (2.0), Real (Y) * R (2.0));
            if K < 16 then
               K := K + 1;
            end if;
         end loop;
      end loop;
      Check_Both (Pts, "4x4 spacing-2 grid", R (2.0));
   end;

   ------------------------------------------------------------------
   Section ("Regular n-gons");
   ------------------------------------------------------------------
   declare
      --  Regular pentagon radius 1: chord length 2 sin(π/5)
      Pent  : constant Point_Array := Regular_Ngon (5, R (1.0));
      Chord : constant Real :=
        R (2.0) * Real (Math.Sin (Long_Float (Ada.Numerics.Pi) / 5.0));
   begin
      Check_Both (Pent, "regular pentagon r=1", Chord, Tol => 1.0E-7);
   end;

   declare
      Hex   : constant Point_Array := Regular_Ngon (6, R (1.0));
      Chord : constant Real := R (1.0);  --  side = radius for hexagon
   begin
      Check_Both (Hex, "regular hexagon r=1", Chord, Tol => 1.0E-7);
   end;

   declare
      Oct : constant Point_Array := Regular_Ngon (8, R (2.0));
      BF  : constant Pair_Result := Brute_Force (Oct);
      DC  : constant Pair_Result := Divide_And_Conquer (Oct);
   begin
      Check (Dist_Match (BF, DC), "regular octagon brute ≡ D&C");
      Check (BF.Distance > R (0.0), "regular octagon positive dist");
   end;

   ------------------------------------------------------------------
   Section ("Known hand-computed sets");
   ------------------------------------------------------------------
   declare
      --  Closest is (1,1)-(1.5,1) distance 0.5
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (5.0), R (5.0)),
         P (R (1.0), R (1.0)),
         P (R (1.5), R (1.0)),
         P (R (8.0), R (0.0))];
      BF  : constant Pair_Result := Brute_Force (Pts);
   begin
      Check_Both (Pts, "hand 0.5 pair", R (0.5));
      Check (BF.Index_A = 3 and then BF.Index_B = 4,
             "hand pair indices 3,4");
   end;

   declare
      --  Diagonal closest: (0,0)-(1,1) = √2; but (2,0)-(3,0)=1 is closer
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (1.0), R (1.0)),
         P (R (2.0), R (0.0)),
         P (R (3.0), R (0.0))];
   begin
      Check_Both (Pts, "hand dist 1", R (1.0));
   end;

   declare
      Pts : constant Point_Array :=
        [P (R (-1.0), R (0.0)),
         P (R (1.0), R (0.0)),
         P (R (0.0), R (0.1))];
      --  Closest: (0,0.1) to either (±1,0)? No — dist to (±1,0) =
      --  sqrt(1+0.01)=sqrt(1.01). Between (-1,0)-(1,0)=2. So closest
      --  is either endpoint to the tip: sqrt(1.01)
      Expect : constant Real :=
        Real (Math.Sqrt (1.01));
   begin
      Check_Both (Pts, "isosceles tip", Expect, Tol => 1.0E-7);
   end;

   ------------------------------------------------------------------
   Section ("Brute ≡ D&C on many sets");
   ------------------------------------------------------------------
   for Seed in 1 .. 12 loop
      declare
         N   : constant Positive := 5 + (Seed mod 10);
         Pts : constant Point_Array := Pseudo_Random_Set (N, Seed * 17);
      begin
         Check_Agree (Pts, "rand seed" & Natural'Image (Seed));
      end;
   end loop;

   declare
      Pts : constant Point_Array := Pseudo_Random_Set (32, 42);
   begin
      Check_Agree (Pts, "rand n=32");
   end;

   declare
      Pts : constant Point_Array := Pseudo_Random_Set (64, 99);
   begin
      Check_Agree (Pts, "rand n=64");
   end;

   ------------------------------------------------------------------
   Section ("Strip / midline stress");
   ------------------------------------------------------------------
   declare
      --  Two clusters far apart; closest is inside left cluster
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (0.1), R (0.0)),
         P (R (0.0), R (0.1)),
         P (R (100.0), R (100.0)),
         P (R (100.1), R (100.0)),
         P (R (100.0), R (100.1))];
   begin
      Check_Both (Pts, "two clusters", R (0.1));
   end;

   declare
      --  Closest pair straddles the median X
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (1.0), R (10.0)),
         P (R (1.05), R (10.0)),
         P (R (2.0), R (0.0))];
   begin
      Check_Both (Pts, "across median", R (0.05));
   end;

   ------------------------------------------------------------------
   Section ("Max_Points boundary");
   ------------------------------------------------------------------
   declare
      Pts : Point_Array (1 .. Max_Points);
   begin
      for I in Pts'Range loop
         Pts (I) := P (Real (I), R (0.0));
      end loop;
      --  Consecutive spacing 1
      Check_Both (Pts, "n=Max_Points collinear", R (1.0));
   end;

   ------------------------------------------------------------------
   Section ("Closest_Pair default is D&C");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (R (0.0), R (0.0)),
         P (R (3.0), R (4.0)),
         P (R (1.0), R (0.0))];
      CP : constant Pair_Result := Closest_Pair (Pts);
      DC : constant Pair_Result := Divide_And_Conquer (Pts);
   begin
      Check (Dist_Match (CP, DC), "default Closest_Pair ≡ D&C");
      Check (Near (CP.Distance, R (1.0)), "default dist = 1");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS, "
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

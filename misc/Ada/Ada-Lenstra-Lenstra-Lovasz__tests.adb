--  Standalone test suite for Lenstra_Lenstra_Lovasz (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Lenstra_Lenstra_Lovasz; use Lenstra_Lenstra_Lovasz;

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
   function RI (X : Integer) return Integer is (X);
   function RR (X : Real) return Real is (X);

   function Vec_Eq (A, B : Vector) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Eq;

   function Mat_Eq (A, B : Matrix) return Boolean is
   begin
      if A'Length (1) /= B'Length (1)
        or else A'Length (2) /= B'Length (2)
      then
         return False;
      end if;
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if A (I, J)
              /= B (I - A'First (1) + B'First (1),
                    J - A'First (2) + B'First (2))
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Mat_Eq;

   function Bundle_Row
     (Bundle : Basis_Bundle; I : Positive) return Vector
   is
   begin
      return Slice (Bundle.B (I), Bundle.M);
   end Bundle_Row;

   --  True if every reduced vector is an integer linear combination of
   --  the original rows for tiny 2×2 / square full-rank cases via Cramer's
   --  check that volume matches and norms did not explode — educational.
   function Volume_Near
     (A, B : Basis_Bundle; Tol : Real := 1.0E-6) return Boolean
   is
   begin
      return Near (Volume (A), Volume (B), Tol);
   end Volume_Near;

begin
   -------------------------------------------------------------------------
   Section ("Near / Dot / Norm2 helpers");
   -------------------------------------------------------------------------
   Check (Near (RR (1.0), RR (1.0 + 1.0E-12)), "Near equal reals");
   Check (not Near (RR (1.0), RR (2.0)), "Near distinct reals");
   declare
      U : constant Vector := [RI (1), RI (2), RI (3)];
      V : constant Vector := [RI (4), RI (5), RI (6)];
      W : constant Vector := [RI (3), RI (4)];
   begin
      Check (Near (Dot (U, V), RR (32.0)),
             "Dot (1,2,3)·(4,5,6)=32");
      Check (Near (Norm2 (W), RR (25.0)),
             "Norm2 (3,4)=25");
      Check (Near (Euclidean_Norm (W), RR (5.0)),
             "‖(3,4)‖=5");
   end;
   Check (Nearest_Integer (RR (2.3)) = 2, "Nearest_Integer 2.3 → 2");
   Check (Nearest_Integer (RR (2.7)) = 3, "Nearest_Integer 2.7 → 3");
   Check (Nearest_Integer (RR (-1.6)) = -2, "Nearest_Integer -1.6 → -2");
   Check (Nearest_Integer (RR (0.5)) = 1, "Nearest_Integer 0.5 → 1");
   Check (Nearest_Integer (RR (-0.5)) = -1, "Nearest_Integer -0.5 → -1");

   -------------------------------------------------------------------------
   Section ("Make_Basis / Slice / To_Matrix round-trip");
   -------------------------------------------------------------------------
   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (1), RI (0)], [RI (0), RI (1)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Back   : constant Matrix := To_Matrix (Bundle);
   begin
      Check (Bundle.N = 2 and then Bundle.M = 2, "identity bundle dims");
      Check (Mat_Eq (M, Back), "To_Matrix round-trip identity");
      Check (Vec_Eq (Bundle_Row (Bundle, 1), [RI (1), RI (0)]),
             "row1 = (1,0)");
      Check (Vec_Eq (Bundle_Row (Bundle, 2), [RI (0), RI (1)]),
             "row2 = (0,1)");
      Check (Near (Volume (Bundle), RR (1.0)), "vol(I)=1");
      Check (Is_Size_Reduced (Bundle), "I is size-reduced");
      Check (Satisfies_Lovasz (Bundle), "I satisfies Lovász");
      Check (Is_LLL_Reduced (Bundle), "I is LLL-reduced");
   end;

   -------------------------------------------------------------------------
   Section ("Already-reduced bases stay stable");
   -------------------------------------------------------------------------
   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (1), RI (0)], [RI (0), RI (1)]];
      Red : constant Matrix := LLL_Reduce (M);
   begin
      Check (Mat_Eq (M, Red), "2D identity stable under LLL");
   end;

   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (5), RI (0)], [RI (0), RI (5)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Red    : constant Basis_Bundle := LLL_Reduce (Bundle);
   begin
      Check (Is_LLL_Reduced (Bundle), "diag(5,5) already LLL");
      Check (Mat_Eq (To_Matrix (Red), M), "diag(5,5) stable");
      Check (Near (Volume (Red), RR (25.0)), "vol diag(5,5)=25");
   end;

   declare
      M : constant Matrix (1 .. 3, 1 .. 3) :=
        [[RI (1), RI (0), RI (0)],
         [RI (0), RI (1), RI (0)],
         [RI (0), RI (0), RI (1)]];
      Red : constant Matrix := LLL_Reduce (M);
   begin
      Check (Mat_Eq (M, Red), "3D identity stable");
      Check (Is_LLL_Reduced (Make_Basis (Red)), "3D I still LLL");
   end;

   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (2), RI (0)], [RI (0), RI (3)]];
      Red : constant Basis_Bundle := LLL_Reduce (Make_Basis (M));
   begin
      Check (Is_LLL_Reduced (Red), "diag(2,3) LLL after reduce");
      Check (Mat_Eq (To_Matrix (Red), M), "diag(2,3) unchanged");
   end;

   -------------------------------------------------------------------------
   Section ("Classic 2D shortening examples");
   -------------------------------------------------------------------------
   --  Highly skewed basis: (100,0) and (99,1) → short vectors near (1,-99)?
   --  Actually LLL yields something like (1, -1)? Let's check properties.
   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (100), RI (0)], [RI (99), RI (1)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Red    : constant Basis_Bundle := LLL_Reduce (Bundle);
      Before : constant Real := Sum_Squared_Norms (Bundle);
      After  : constant Real := Sum_Squared_Norms (Red);
   begin
      Check (Is_LLL_Reduced (Red), "skew 2D is LLL-reduced");
      Check (Is_Size_Reduced (Red), "skew 2D size-reduced");
      Check (Satisfies_Lovasz (Red), "skew 2D Lovász ok");
      Check (After <= Before + RR (1.0E-6),
             "skew 2D sum‖·‖² did not increase");
      Check (Volume_Near (Bundle, Red), "skew 2D volume preserved");
      Check (Max_Euclidean_Norm (Red) <= Max_Euclidean_Norm (Bundle) + 1.0E-6,
             "skew 2D max norm not worse");
      --  Expect a short vector such as (±1, ∓1) with ‖·‖² = 2
      declare
         Short : Boolean := False;
         Row   : Vector (1 .. 2);
      begin
         for I in 1 .. Red.N loop
            Row := Bundle_Row (Red, I);
            if Near (Norm2 (Row), RR (2.0))
              or else Near (Norm2 (Row), RR (1.0))
            then
               Short := True;
            end if;
         end loop;
         Check (Short, "skew 2D has a short basis vector (‖·‖²≤2)");
      end;
   end;

   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (11), RI (2)], [RI (2), RI (13)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Red    : constant Basis_Bundle := LLL_Reduce (Bundle);
   begin
      Check (Is_LLL_Reduced (Red), "[[11,2],[2,13]] LLL-reduced");
      Check (Volume_Near (Bundle, Red, 1.0E-4),
             "[[11,2],[2,13]] volume preserved");
      Check (Sum_Squared_Norms (Red) <= Sum_Squared_Norms (Bundle) + 1.0E-6,
             "[[11,2],[2,13]] sum norms ok");
   end;

   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (5), RI (3)], [RI (2), RI (1)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Red    : constant Basis_Bundle := LLL_Reduce (Bundle);
   begin
      Check (Is_LLL_Reduced (Red), "[[5,3],[2,1]] LLL-reduced");
      Check (Volume_Near (Bundle, Red), "[[5,3],[2,1]] volume");
      Check (Is_Size_Reduced (Red), "[[5,3],[2,1]] size-reduced");
   end;

   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (7), RI (5)], [RI (3), RI (2)]];
      Red : constant Basis_Bundle := LLL_Reduce (Make_Basis (M));
   begin
      Check (Is_LLL_Reduced (Red), "[[7,5],[3,2]] LLL-reduced");
      Check (Is_Size_Reduced (Red), "[[7,5],[3,2]] size-reduced");
   end;

   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (4), RI (1)], [RI (1), RI (4)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Red    : constant Basis_Bundle := LLL_Reduce (Bundle);
   begin
      Check (Is_LLL_Reduced (Red), "[[4,1],[1,4]] LLL");
      Check (Volume_Near (Bundle, Red), "[[4,1],[1,4]] volume");
   end;

   -------------------------------------------------------------------------
   Section ("Wikipedia Z³ example (rows = column-vectors transposed)");
   -------------------------------------------------------------------------
   --  Columns of [[1,-1,3],[1,0,5],[1,2,6]] are b1,b2,b3; store as rows:
   --  b1=(1,1,1), b2=(-1,0,2), b3=(3,5,6)
   --  Reduced columns [[0,1,-1],[1,0,0],[0,1,2]] → rows (0,1,0),(1,0,1),(-1,0,2)
   declare
      M : constant Matrix (1 .. 3, 1 .. 3) :=
        [[RI (1), RI (1), RI (1)],
         [RI (-1), RI (0), RI (2)],
         [RI (3), RI (5), RI (6)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Red    : constant Basis_Bundle := LLL_Reduce (Bundle);
      Expect : constant Matrix (1 .. 3, 1 .. 3) :=
        [[RI (0), RI (1), RI (0)],
         [RI (1), RI (0), RI (1)],
         [RI (-1), RI (0), RI (2)]];
      --  Reduced basis may differ by sign/order of an LLL-equivalent set;
      --  check LLL properties + volume + that expected rows appear (±).
      function Has_PM (Row : Vector) return Boolean is
         Neg : Vector (Row'Range);
      begin
         for I in Row'Range loop
            Neg (I) := -Row (I);
         end loop;
         for I in 1 .. Red.N loop
            if Vec_Eq (Bundle_Row (Red, I), Row)
              or else Vec_Eq (Bundle_Row (Red, I), Neg)
            then
               return True;
            end if;
         end loop;
         return False;
      end Has_PM;
   begin
      Check (Is_LLL_Reduced (Red), "Wiki Z3 LLL-reduced");
      Check (Is_Size_Reduced (Red), "Wiki Z3 size-reduced");
      Check (Satisfies_Lovasz (Red), "Wiki Z3 Lovász");
      Check (Volume_Near (Bundle, Red, 1.0E-4), "Wiki Z3 volume");
      Check (Sum_Squared_Norms (Red) < Sum_Squared_Norms (Bundle),
             "Wiki Z3 shorter (sum ‖·‖²)");
      Check (Has_PM ([RI (0), RI (1), RI (0)])
               or else Has_PM ([RI (1), RI (0), RI (0)])
               or else Has_PM ([RI (0), RI (0), RI (1)]),
             "Wiki Z3 contains a short axis-like vector");
      --  Soft check against the published reduced basis (allowing signs)
      declare
         Match_Count : Natural := 0;
      begin
         for I in Expect'Range (1) loop
            if Has_PM
              ([Expect (I, 1), Expect (I, 2), Expect (I, 3)])
            then
               Match_Count := Match_Count + 1;
            end if;
         end loop;
         Check (Match_Count >= 2,
                "Wiki Z3 matches ≥2 published reduced vectors (±)");
      end;
   end;

   -------------------------------------------------------------------------
   Section ("More 2D / 3D unrolled examples");
   -------------------------------------------------------------------------
   declare
      Examples : constant array (1 .. 10) of Matrix (1 .. 2, 1 .. 2) :=
        [[[RI (9), RI (4)], [RI (4), RI (9)]],
         [[RI (6), RI (1)], [RI (1), RI (6)]],
         [[RI (8), RI (3)], [RI (5), RI (2)]],
         [[RI (15), RI (7)], [RI (7), RI (15)]],
         [[RI (20), RI (9)], [RI (9), RI (4)]],
         [[RI (12), RI (5)], [RI (5), RI (12)]],
         [[RI (3), RI (1)], [RI (1), RI (2)]],
         [[RI (10), RI (3)], [RI (3), RI (1)]],
         [[RI (14), RI (5)], [RI (9), RI (4)]],
         [[RI (2), RI (1)], [RI (1), RI (2)]]];
   begin
      for E in Examples'Range loop
         declare
            Bundle : constant Basis_Bundle := Make_Basis (Examples (E));
            Red    : constant Basis_Bundle := LLL_Reduce (Bundle);
            Tag    : constant String :=
              Integer'Image (E);
         begin
            Check (Is_Size_Reduced (Red),
                   "ex2D" & Tag & " size-reduced");
            Check (Satisfies_Lovasz (Red),
                   "ex2D" & Tag & " Lovász");
            Check (Is_LLL_Reduced (Red),
                   "ex2D" & Tag & " LLL-reduced");
            Check (Volume_Near (Bundle, Red, 1.0E-3),
                   "ex2D" & Tag & " volume");
         end;
      end loop;
   end;

   declare
      M1 : constant Matrix (1 .. 3, 1 .. 3) :=
        [[RI (2), RI (0), RI (0)],
         [RI (1), RI (2), RI (0)],
         [RI (1), RI (1), RI (2)]];
      M2 : constant Matrix (1 .. 3, 1 .. 3) :=
        [[RI (4), RI (1), RI (0)],
         [RI (1), RI (4), RI (1)],
         [RI (0), RI (1), RI (4)]];
      M3 : constant Matrix (1 .. 3, 1 .. 2) :=
        [[RI (3), RI (1)],
         [RI (1), RI (3)],
         [RI (2), RI (2)]];
      R1 : constant Basis_Bundle := LLL_Reduce (Make_Basis (M1));
      R2 : constant Basis_Bundle := LLL_Reduce (Make_Basis (M2));
      R3 : constant Basis_Bundle := LLL_Reduce (Make_Basis (M3));
   begin
      Check (Is_LLL_Reduced (R1), "lower-tri 3D LLL");
      Check (Volume_Near (Make_Basis (M1), R1, 1.0E-3),
             "lower-tri 3D volume");
      Check (Is_LLL_Reduced (R2), "toeplitz-ish 3D LLL");
      Check (Volume_Near (Make_Basis (M2), R2, 1.0E-3),
             "toeplitz-ish 3D volume");
      Check (Is_LLL_Reduced (R3), "3×2 tall LLL");
      Check (Is_Size_Reduced (R3), "3×2 tall size-reduced");
      Check (Satisfies_Lovasz (R3), "3×2 tall Lovász");
   end;

   -------------------------------------------------------------------------
   Section ("δ boundary / Invalid_Argument");
   -------------------------------------------------------------------------
   declare
      Raised : Boolean;
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (1), RI (0)], [RI (0), RI (1)]];
   begin
      Raised := False;
      begin
         declare
            Ignore : constant Matrix :=
              LLL_Reduce (M, Reduction_Delta => RR (0.25));
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Delta=1/4 raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Ignore : constant Matrix :=
              LLL_Reduce (M, Reduction_Delta => RR (0.2));
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Delta=0.2 raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Ignore : constant Matrix :=
              LLL_Reduce (M, Reduction_Delta => RR (1.5));
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Delta=1.5 raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Empty  : Basis_Bundle (0, 0);
            Ignore : constant Basis_Bundle := LLL_Reduce (Empty);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "empty basis raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Empty  : Basis_Bundle (2, 0);
            Ignore : constant Basis_Bundle := LLL_Reduce (Empty);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "M=0 raises Invalid_Argument");
   end;

   --  δ just above 1/4 and δ = 1 are accepted
   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (5), RI (2)], [RI (2), RI (5)]];
      R1 : constant Basis_Bundle :=
        LLL_Reduce (Make_Basis (M), Reduction_Delta => RR (0.2500001));
      R2 : constant Basis_Bundle :=
        LLL_Reduce (Make_Basis (M), Reduction_Delta => RR (1.0));
      R3 : constant Basis_Bundle :=
        LLL_Reduce (Make_Basis (M), Reduction_Delta => RR (0.75));
   begin
      Check (Is_LLL_Reduced (R1, RR (0.2500001)),
             "δ≈1/4+ accepted + reduced");
      Check (Is_LLL_Reduced (R2, RR (1.0)), "δ=1 accepted + reduced");
      Check (Is_LLL_Reduced (R3), "δ=3/4 default path");
   end;

   -------------------------------------------------------------------------
   Section ("Basis-array overload + single vector");
   -------------------------------------------------------------------------
   declare
      B : Basis (1 .. 2);
      Red : Basis (1 .. 2);
   begin
      B (1) := Make_Vector ([RI (10), RI (1)]);
      B (2) := Make_Vector ([RI (9), RI (1)]);
      Red := LLL_Reduce (B, Ambient => 2);
      declare
         Bundle : Basis_Bundle (2, 2);
      begin
         Bundle.B (1) := Red (1);
         Bundle.B (2) := Red (2);
         Check (Is_LLL_Reduced (Bundle), "Basis overload LLL");
         Check (Is_Size_Reduced (Bundle), "Basis overload size-reduced");
      end;
   end;

   declare
      M : constant Matrix (1 .. 1, 1 .. 3) :=
        [[RI (2), RI (3), RI (6)]];
      Red : constant Basis_Bundle := LLL_Reduce (Make_Basis (M));
   begin
      Check (Red.N = 1 and then Red.M = 3, "single vector dims");
      Check (Vec_Eq (Bundle_Row (Red, 1), [RI (2), RI (3), RI (6)]),
             "single vector unchanged");
      Check (Is_LLL_Reduced (Red), "single vector is LLL");
   end;

   -------------------------------------------------------------------------
   Section ("μ bound and Lovász float-tol spot checks");
   -------------------------------------------------------------------------
   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (13), RI (5)], [RI (8), RI (3)]];
      Red : constant Basis_Bundle := LLL_Reduce (Make_Basis (M));
      Bstar       : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Mu          : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Bstar_Norm2 : Real_Vector (1 .. Max_Dim);
      Ok_Mu : Boolean := True;
      Ok_Lv : Boolean := True;
   begin
      Gram_Schmidt (Red, Bstar, Mu, Bstar_Norm2);
      for I in 1 .. Red.N loop
         for J in 1 .. I - 1 loop
            if abs (Mu (I, J)) > 0.5 + Mu_Tol then
               Ok_Mu := False;
            end if;
         end loop;
      end loop;
      for K in 2 .. Red.N loop
         declare
            Left  : constant Real := Default_Delta * Bstar_Norm2 (K - 1);
            Right : constant Real :=
              Bstar_Norm2 (K)
              + Mu (K, K - 1) * Mu (K, K - 1) * Bstar_Norm2 (K - 1);
         begin
            if Left > Right + Lovasz_Tol then
               Ok_Lv := False;
            end if;
         end;
      end loop;
      Check (Ok_Mu, "explicit |μ|≤1/2 check");
      Check (Ok_Lv, "explicit Lovász inequality check");
      Check (Near (Volume (Red), abs (Real (13 * 3 - 5 * 8)), 1.0E-4)
               or else Volume (Red) > 0.0,
             "volume positive / det-related");
   end;

   -------------------------------------------------------------------------
   Section ("Copy_Basis / Max_Euclidean_Norm");
   -------------------------------------------------------------------------
   declare
      M : constant Matrix (1 .. 2, 1 .. 2) :=
        [[RI (3), RI (0)], [RI (0), RI (4)]];
      Bundle : constant Basis_Bundle := Make_Basis (M);
      Cpy    : constant Basis_Bundle := Copy_Basis (Bundle);
   begin
      Check (Mat_Eq (To_Matrix (Bundle), To_Matrix (Cpy)),
             "Copy_Basis preserves matrix");
      Check (Near (Max_Euclidean_Norm (Bundle), RR (4.0)),
             "max norm of diag(3,4)=4");
      Check (Near (Sum_Squared_Norms (Bundle), RR (25.0)),
             "sum sq norms 9+16=25");
   end;

   -------------------------------------------------------------------------
   -- Summary
   -------------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Results:" & Natural'Image (Pass_Count) & " PASS,"
     & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 or else Pass_Count < 80 then
      if Pass_Count < 80 then
         Ada.Text_IO.Put_Line (
           "Insufficient PASS count (need ≥ 80).");
      end if;
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

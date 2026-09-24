--  Standalone test suite for Birkhoff_Von_Neumann (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Birkhoff_Von_Neumann; use Birkhoff_Von_Neumann;

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

   function Perm_Eq
     (A, B : Permutation; N : Dimension) return Boolean
   is
   begin
      for I in 1 .. N loop
         if A (A'First + (I - 1)) /= B (B'First + (I - 1)) then
            return False;
         end if;
      end loop;
      return True;
   end Perm_Eq;

   function Decompose_OK (A : Matrix) return Boolean is
      D : Decomposition;
      R : Matrix (A'Range (1), A'Range (2));
   begin
      D := Decompose (A);
      if not D.Success then
         return False;
      end if;
      if not Near (Lambda_Sum (D), 1.0, Sum_Tol * 10.0) then
         return False;
      end if;
      R := Reconstruct (D);
      return Matrices_Near (A, R, Recon_Tol);
   end Decompose_OK;

begin
   Ada.Text_IO.Put_Line ("Birkhoff_Von_Neumann test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Predicates: square / near / nonnegative / DS");
   ---------------------------------------------------------------------
   declare
      Sq : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.5, 0.5], [0.5, 0.5]];
      Rec : constant Matrix (1 .. 2, 1 .. 3) :=
        [[0.1, 0.2, 0.7], [0.3, 0.4, 0.3]];
      Neg : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.5, 0.5], [0.5, -0.1]];
      Bad_Sum : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.6, 0.6], [0.4, 0.4]];
      Empty : Matrix (1 .. 0, 1 .. 0);
   begin
      Check (Is_Square (Sq), "Is_Square 2x2");
      Check (not Is_Square (Rec), "Is_Square rejects 2x3");
      Check (Is_Square (Empty), "Is_Square empty");
      Check (Near (1.0, 1.0 + Zero_Tol / 2.0), "Near true");
      Check (not Near (1.0, 2.0), "Near false");
      Check (Entry_Near_Zero (0.0), "Entry_Near_Zero 0");
      Check (not Entry_Near_Zero (1.0), "Entry_Near_Zero 1");
      Check (Is_Nonnegative (Sq), "Is_Nonnegative DS");
      Check (not Is_Nonnegative (Neg), "Is_Nonnegative rejects neg");
      Check (Is_Doubly_Stochastic (Sq), "DS uniform 2x2");
      Check (Is_Doubly_Stochastic (Empty), "DS empty");
      Check (not Is_Doubly_Stochastic (Rec), "DS rejects rectangular");
      Check (not Is_Doubly_Stochastic (Neg), "DS rejects negative");
      Check (not Is_Doubly_Stochastic (Bad_Sum), "DS rejects bad sums");
      Check (Near (Row_Sum (Sq, 1), 1.0), "Row_Sum 1");
      Check (Near (Col_Sum (Sq, 2), 1.0), "Col_Sum 2");
   end;

   ---------------------------------------------------------------------
   Section ("2. Identity / Uniform / Permutation builders");
   ---------------------------------------------------------------------
   for N in Dimension range 1 .. 6 loop
      declare
         I  : constant Matrix := Identity (N);
         U  : constant Matrix := Uniform (N);
         P  : constant Permutation := Identity_Permutation (N);
         Rv : constant Permutation := Reverse_Permutation (N);
         Cy : constant Permutation := Cycle_Permutation (N, 1);
         PM : constant Matrix := Permutation_Matrix (P, N);
         RM : constant Matrix := Permutation_Matrix (Rv, N);
      begin
         Check (Is_Doubly_Stochastic (I),
                "Identity DS n=" & Dimension'Image (N));
         Check (Is_Doubly_Stochastic (U),
                "Uniform DS n=" & Dimension'Image (N));
         Check (Is_Permutation (P, N),
                "Id perm n=" & Dimension'Image (N));
         Check (Is_Permutation (Rv, N),
                "Rev perm n=" & Dimension'Image (N));
         Check (Is_Permutation (Cy, N),
                "Cycle perm n=" & Dimension'Image (N));
         Check (Matrices_Near (I, PM),
                "PermMatrix id n=" & Dimension'Image (N));
         Check (Is_Doubly_Stochastic (RM),
                "Rev matrix DS n=" & Dimension'Image (N));
         Check (Near (U (1, 1), 1.0 / Real (N)),
                "Uniform entry n=" & Dimension'Image (N));
         Check (I (1, 1) = 1.0 and then
                (N = 1 or else I (1, 2) = 0.0),
                "Identity entries n=" & Dimension'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("3. Scale / Add / Sub / Matrices_Near / Frobenius");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[0.5, 0.5], [0.5, 0.5]];
      S : constant Matrix := Scale (A, 2.0);
      C : constant Matrix := Add (A, B);
      D : constant Matrix := Sub (A, B);
   begin
      Check (S (1, 1) = 2.0 and then S (2, 2) = 8.0, "Scale *2");
      Check (Near (C (1, 1), 1.5) and then Near (C (2, 2), 4.5), "Add");
      Check (Near (D (1, 1), 0.5) and then Near (D (2, 1), 2.5), "Sub");
      Check (Matrices_Near (A, A), "Matrices_Near self");
      Check (not Matrices_Near (A, B), "Matrices_Near distinct");
      Check (Near (Frobenius_Distance (A, A), 0.0), "Frobenius self 0");
      Check (Frobenius_Distance (A, B) > 1.0, "Frobenius A-B > 1");
   end;

   ---------------------------------------------------------------------
   Section ("4. Convex_Combination and Make_Toy_DS");
   ---------------------------------------------------------------------
   declare
      Terms : Term_List (1 .. 2);
      M     : Matrix (1 .. 2, 1 .. 2);
      Toy   : Matrix (1 .. 3, 1 .. 3);
   begin
      Terms (1).Lambda := 0.3;
      Terms (1).N := 2;
      Terms (1).Perm := [1, 2, others => 0];
      Terms (2).Lambda := 0.7;
      Terms (2).N := 2;
      Terms (2).Perm := [2, 1, others => 0];
      M := Convex_Combination (Terms, 2, 2);
      Check (Is_Doubly_Stochastic (M), "Convex combo DS");
      Check (Near (M (1, 1), 0.3) and then Near (M (1, 2), 0.7),
             "Convex combo entries");
      Toy := Make_Toy_DS (3);
      Check (Is_Doubly_Stochastic (Toy), "Make_Toy_DS 3 DS");
      for N in Dimension range 1 .. 6 loop
         Check (Is_Doubly_Stochastic (Make_Toy_DS (N)),
                "Make_Toy_DS DS n=" & Dimension'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia 3x3 example");
   ---------------------------------------------------------------------
   declare
      W : constant Matrix := Wikipedia_Example_3x3;
      D : Decomposition;
      R : Matrix (1 .. 3, 1 .. 3);
   begin
      Check (Is_Doubly_Stochastic (W), "Wiki 3x3 is DS");
      Check (Near (W (1, 1), 7.0 / 12.0), "Wiki (1,1)=7/12");
      Check (Near (W (1, 2), 0.0), "Wiki (1,2)=0");
      Check (Near (W (2, 1), 2.0 / 12.0), "Wiki (2,1)=2/12");
      D := Decompose (W);
      Check (D.Success, "Wiki decompose Success");
      Check (D.Count >= 1, "Wiki at least one term");
      Check (Near (Lambda_Sum (D), 1.0, 1.0E-8), "Wiki lambda sum 1");
      R := Reconstruct (D);
      Check (Matrices_Near (W, R, 1.0E-8), "Wiki reconstruct");
      Check (Reconstruct_Near (W), "Wiki Reconstruct_Near");
   end;

   ---------------------------------------------------------------------
   Section ("6. Support matching Find_Support_Permutation");
   ---------------------------------------------------------------------
   declare
      I3 : constant Matrix := Identity (3);
      P3 : Permutation (1 .. 3);
      P2 : Permutation (1 .. 2);
      Full : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.5, 0.5], [0.5, 0.5]];
      Sparse : constant Matrix (1 .. 3, 1 .. 3) :=
        [[0.0, 1.0, 0.0],
         [0.0, 0.0, 1.0],
         [1.0, 0.0, 0.0]];
      NoMatch : constant Matrix (1 .. 2, 1 .. 2) :=
        [[1.0, 1.0],
         [0.0, 0.0]];
      Raised : Boolean;
   begin
      P3 := Find_Support_Permutation (I3);
      Check (Perm_Eq (P3, Identity_Permutation (3), 3),
             "Support of I3 is id");
      P2 := Find_Support_Permutation (Full);
      Check (Is_Permutation (P2, 2), "Support of full 2x2");
      P3 := Find_Support_Permutation (Sparse);
      Check (P3 (1) = 2 and then P3 (2) = 3 and then P3 (3) = 1,
             "Support sparse cycle");
      Raised := False;
      begin
         P2 := Find_Support_Permutation (NoMatch);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "NoMatch raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("7. Decompose identity / uniform / toy");
   ---------------------------------------------------------------------
   for N in Dimension range 1 .. 6 loop
      declare
         I : constant Matrix := Identity (N);
         U : constant Matrix := Uniform (N);
         T : constant Matrix := Make_Toy_DS (N);
         DI : constant Decomposition := Decompose (I);
         DU : constant Decomposition := Birkhoff_Decomposition (U);
      begin
         Check (Decompose_OK (I),
                "Decompose identity n=" & Dimension'Image (N));
         Check (DI.Count = 1 and then Near (DI.Terms (1).Lambda, 1.0),
                "Identity single term n=" & Dimension'Image (N));
         Check (Decompose_OK (U),
                "Decompose uniform n=" & Dimension'Image (N));
         Check (DU.Success and then DU.Count >= 1,
                "Uniform Success n=" & Dimension'Image (N));
         Check (Near (Lambda_Sum (DU), 1.0, 1.0E-8),
                "Uniform lambda sum n=" & Dimension'Image (N));
         Check (Decompose_OK (T),
                "Decompose toy n=" & Dimension'Image (N));
         Check (Reconstruct_Near (T),
                "Reconstruct_Near toy n=" & Dimension'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("8. Empty / Invalid_Argument paths");
   ---------------------------------------------------------------------
   declare
      Empty : Matrix (1 .. 0, 1 .. 0);
      D0    : constant Decomposition := Decompose (Empty);
      Rec   : constant Matrix (1 .. 2, 1 .. 3) :=
        [[0.1, 0.2, 0.7], [0.3, 0.4, 0.3]];
      Neg   : constant Matrix (1 .. 2, 1 .. 2) :=
        [[0.5, 0.5], [-0.1, 1.1]];
      Raised : Boolean;
   begin
      Check (D0.Success and then D0.Count = 0 and then D0.N = 0,
             "empty decompose");
      Check (Reconstruct (D0)'Length (1) = 0, "empty reconstruct");
      Check (not Reconstruct_Near (Rec), "Reconstruct_Near rect False");
      Check (not Reconstruct_Near (Neg), "Reconstruct_Near neg False");
      Raised := False;
      begin
         declare
            D : constant Decomposition := Decompose (Rec);
            pragma Unreferenced (D);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Decompose rectangular raises");
      Raised := False;
      begin
         declare
            D : constant Decomposition := Decompose (Neg);
            pragma Unreferenced (D);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Decompose non-DS raises");
   end;

   ---------------------------------------------------------------------
   Section ("9. Known 2x2 family A(t)");
   ---------------------------------------------------------------------
   --  A(t) = [[t, 1-t], [1-t, t]] for t in [0,1] is DS.
   for K in 0 .. 10 loop
      declare
         T : constant Real := Real (K) / 10.0;
         A : constant Matrix (1 .. 2, 1 .. 2) :=
           [[T, 1.0 - T],
            [1.0 - T, T]];
         D : Decomposition;
      begin
         Check (Is_Doubly_Stochastic (A),
                "A(t) DS t=" & Integer'Image (K));
         D := Decompose (A);
         Check (D.Success and then Matrices_Near (A, Reconstruct (D)),
                "A(t) reconstruct t=" & Integer'Image (K));
         Check (Near (Lambda_Sum (D), 1.0, 1.0E-8),
                "A(t) lambda sum t=" & Integer'Image (K));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("10. Cycle convex combinations");
   ---------------------------------------------------------------------
   for N in Dimension range 3 .. 5 loop
      declare
         Terms : Term_List (1 .. N);
         M     : Matrix (1 .. N, 1 .. N);
         Lam   : constant Real := 1.0 / Real (N);
      begin
         for S in 0 .. N - 1 loop
            Terms (S + 1).Lambda := Lam;
            Terms (S + 1).N := N;
            declare
               P : constant Permutation := Cycle_Permutation (N, S);
            begin
               for I in 1 .. N loop
                  Terms (S + 1).Perm (I) := P (I);
               end loop;
            end;
         end loop;
         M := Convex_Combination (Terms, N, N);
         Check (Is_Doubly_Stochastic (M),
                "cycle combo DS n=" & Dimension'Image (N));
         --  Cycle average equals Uniform.
         Check (Matrices_Near (M, Uniform (N), 1.0E-10),
                "cycle combo = Uniform n=" & Dimension'Image (N));
         Check (Decompose_OK (M),
                "cycle combo decompose n=" & Dimension'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("11. Extra DS matrices and alias");
   ---------------------------------------------------------------------
   declare
      --  Classical 3x3 with zeros on diagonal alternative pattern
      A : constant Matrix (1 .. 3, 1 .. 3) :=
        [[0.0, 0.5, 0.5],
         [0.5, 0.0, 0.5],
         [0.5, 0.5, 0.0]];
      B : constant Matrix (1 .. 4, 1 .. 4) := Make_Toy_DS (4);
      C : constant Matrix (1 .. 4, 1 .. 4) := Uniform (4);
      D1, D2 : Decomposition;
      Bad_Terms : Term_List (1 .. 1);
      Raised : Boolean;
   begin
      Check (Is_Doubly_Stochastic (A), "zero-diag 3x3 DS");
      Check (Decompose_OK (A), "zero-diag decompose");
      D1 := Decompose (B);
      D2 := Birkhoff_Decomposition (B);
      Check (D1.Count = D2.Count and then
             Near (Lambda_Sum (D1), Lambda_Sum (D2)),
             "Decompose alias Birkhoff_Decomposition");
      Check (Decompose_OK (C), "Uniform 4 decompose");
      Check (Reconstruct_Near (A), "Reconstruct_Near zero-diag");

      Bad_Terms (1).Lambda := 1.0;
      Bad_Terms (1).N := 2;
      Bad_Terms (1).Perm := [1, 1, others => 0];  -- not a permutation
      Raised := False;
      begin
         declare
            M : constant Matrix := Convex_Combination (Bad_Terms, 1, 2);
            pragma Unreferenced (M);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Convex_Combination bad perm raises");

      Bad_Terms (1).Perm := [1, 2, others => 0];
      Bad_Terms (1).Lambda := 0.5;  -- sum != 1
      Raised := False;
      begin
         declare
            M : constant Matrix := Convex_Combination (Bad_Terms, 1, 2);
            pragma Unreferenced (M);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Convex_Combination sum!=1 raises");
   end;

   ---------------------------------------------------------------------
   Section ("12. Permutation edge cases / Is_Permutation");
   ---------------------------------------------------------------------
   declare
      Id3  : constant Permutation (1 .. 3) := [1, 2, 3];
      Bad1 : constant Permutation (1 .. 3) := [1, 1, 2];
      Bad2 : constant Permutation (1 .. 3) := [1, 2, 4];
      Bad3 : constant Permutation (1 .. 3) := [0, 2, 3];
      Empty_P : Permutation (1 .. 0);
   begin
      Check (Is_Permutation (Id3, 3), "perm id3");
      Check (Is_Permutation (Id3, 0), "perm N=0");
      Check (Is_Permutation (Empty_P, 0), "empty perm");
      Check (not Is_Permutation (Bad1, 3), "reject duplicate");
      Check (not Is_Permutation (Bad2, 3), "reject out of range");
      Check (not Is_Permutation (Bad3, 3), "reject zero");
      Check (Reverse_Permutation (4) (1) = 4
             and then Reverse_Permutation (4) (4) = 1,
             "reverse 4 endpoints");
      Check (Cycle_Permutation (5, 2) (1) = 3
             and then Cycle_Permutation (5, 2) (4) = 1,
             "cycle shift 2");
      Check (Cycle_Permutation (3, 0) (2) = 2, "cycle shift 0 = id");
      Check (Cycle_Permutation (3, 3) (1) = 1, "cycle shift N = id");
   end;

   ---------------------------------------------------------------------
   Section ("13. Zero_Matrix and n=7,8 smoke");
   ---------------------------------------------------------------------
   declare
      Z : constant Matrix := Zero_Matrix (3);
      I7 : constant Matrix := Identity (7);
      U8 : constant Matrix := Uniform (8);
      T5 : constant Matrix := Make_Toy_DS (5);
   begin
      Check (Near (Z (1, 1), 0.0) and then Near (Z (3, 3), 0.0),
             "Zero_Matrix");
      Check (not Is_Doubly_Stochastic (Z), "zeros not DS (sums 0)");
      Check (Decompose_OK (I7), "Identity 7");
      Check (Decompose_OK (U8), "Uniform 8");
      Check (Decompose_OK (T5), "Toy 5");
      Check (Is_Doubly_Stochastic (Make_Toy_DS (8)), "Toy 8 DS");
      Check (Decompose_OK (Make_Toy_DS (8)), "Toy 8 decompose");
   end;

   ---------------------------------------------------------------------
   Section ("14. Term lambdas nonnegative / order independence smoke");
   ---------------------------------------------------------------------
   declare
      W : constant Matrix := Wikipedia_Example_3x3;
      D : constant Decomposition := Decompose (W);
      All_Nonneg : Boolean := True;
      R1 : Matrix (1 .. 3, 1 .. 3);
   begin
      for K in 1 .. D.Count loop
         if D.Terms (K).Lambda < -Zero_Tol then
            All_Nonneg := False;
         end if;
         Check (Is_Permutation (D.Terms (K).Perm, 3),
                "wiki term perm #" & Natural'Image (K));
      end loop;
      Check (All_Nonneg, "all wiki lambdas nonnegative");
      R1 := Reconstruct (D);
      Check (Matrices_Near (W, R1), "wiki R1 near");
      --  Each support edge of first term should have been positive in W.
      if D.Count >= 1 then
         declare
            P : Permutation renames D.Terms (1).Perm;
            Ok : Boolean := True;
         begin
            for I in 1 .. 3 loop
               if W (I, P (I)) <= Zero_Tol then
                  Ok := False;
               end if;
            end loop;
            Check (Ok, "first term supported by W");
         end;
      end if;
   end;

   ---------------------------------------------------------------------
   Section ("15. Bulk A(t)-style and mixed sizes");
   ---------------------------------------------------------------------
   for N in Dimension range 2 .. 4 loop
      for K in 0 .. 5 loop
         declare
            T : constant Real := Real (K) / 5.0;
            Terms : Term_List (1 .. 2);
            M : Matrix (1 .. N, 1 .. N);
         begin
            Terms (1).Lambda := T;
            Terms (1).N := N;
            declare
               P : constant Permutation := Identity_Permutation (N);
            begin
               for I in 1 .. N loop
                  Terms (1).Perm (I) := P (I);
               end loop;
            end;
            Terms (2).Lambda := 1.0 - T;
            Terms (2).N := N;
            declare
               P : constant Permutation := Reverse_Permutation (N);
            begin
               for I in 1 .. N loop
                  Terms (2).Perm (I) := P (I);
               end loop;
            end;
            if Near (T, 0.0) then
               --  Avoid zero-weight term issues: use reverse alone.
               Terms (1).Lambda := 1.0;
               Terms (1).Perm := Terms (2).Perm;
               M := Convex_Combination (Terms, 1, N);
            elsif Near (T, 1.0) then
               M := Convex_Combination (Terms, 1, N);
            else
               M := Convex_Combination (Terms, 2, N);
            end if;
            Check (Is_Doubly_Stochastic (M),
                   "mix DS n=" & Dimension'Image (N)
                   & " k=" & Integer'Image (K));
            Check (Decompose_OK (M),
                   "mix decomp n=" & Dimension'Image (N)
                   & " k=" & Integer'Image (K));
         end;
      end loop;
   end loop;

   ---------------------------------------------------------------------
   Section ("16. Additional reconstruction / distance checks");
   ---------------------------------------------------------------------
   declare
      Samples : constant array (1 .. 8) of Dimension :=
        [1, 2, 2, 3, 3, 4, 5, 6];
   begin
      for S of Samples loop
         declare
            M : constant Matrix :=
              (if S mod 2 = 0 then Uniform (S) else Make_Toy_DS (S));
            D : constant Decomposition := Decompose (M);
            R : constant Matrix := Reconstruct (D);
         begin
            Check (Frobenius_Distance (M, R) < 1.0E-7,
                   "Frob recon n=" & Dimension'Image (S));
            Check (D.N = S, "D.N matches n=" & Dimension'Image (S));
            Check (D.Count <= Max_Terms,
                   "Count bound n=" & Dimension'Image (S));
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===============================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count)
      & "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 150 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

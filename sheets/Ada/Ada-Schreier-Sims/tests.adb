--  Standalone test suite for Schreier_Sims (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Schreier_Sims; use Schreier_Sims;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   --  Pack a partial image list into Image_Array for Make_Permutation.
   function P (N : Positive; A : Image_Array) return Permutation is
     (Make_Permutation (A, N));


   ------------------------------------------------------------------
   --  Identity / Compose / Inverse primitives
   ------------------------------------------------------------------

   procedure Test_Primitives is
      Id3 : constant Permutation := Identity (3);
      Id4 : constant Permutation := Identity (4);
      --  (1 2) in S3
      T12 : constant Permutation :=
        P (3, [2, 1, 3, others => 1]);
      --  (1 2 3)
      C123 : constant Permutation :=
        P (3, [2, 3, 1, others => 1]);
      --  (2 3)
      T23 : constant Permutation :=
        P (3, [1, 3, 2, others => 1]);
      Comp : Permutation;
   begin
      Section ("Primitives");
      Check (Is_Identity (Id3), "Identity(3) is identity");
      Check (Is_Identity (Id4), "Identity(4) is identity");
      Check (Id3.N = 3, "Identity(3).N = 3");
      Check (Apply (Id3, 2) = 2, "Id3 fixes 2");
      Check (Apply (T12, 1) = 2, "(1 2) sends 1->2");
      Check (Apply (T12, 2) = 1, "(1 2) sends 2->1");
      Check (Apply (C123, 1) = 2, "(1 2 3) sends 1->2");
      Check (Apply (C123, 3) = 1, "(1 2 3) sends 3->1");
      Check (Is_Identity (Compose (T12, T12)), "(1 2)^2 = id");
      Check (Is_Identity (Compose (C123, Inverse (C123))),
             "g * g^{-1} = id");
      Check (Is_Identity (Compose (Inverse (C123), C123)),
             "g^{-1} * g = id");
      Comp := Compose (T12, T23);
      --  1 -T12-> 2 -T23-> 3; 2 -T12-> 1 -T23-> 1; 3 -T12-> 3 -T23-> 2
      Check (Apply (Comp, 1) = 3 and then Apply (Comp, 2) = 1
             and then Apply (Comp, 3) = 2,
             "(1 2)*(2 3) = (1 3 2)");
      Check (Equal (T12, T12), "Equal reflexive");
      Check (not Equal (T12, C123), "distinct perms not Equal");
      Check (not Is_Identity (T12), "(1 2) not identity");
   end Test_Primitives;

   ------------------------------------------------------------------
   --  Invalid arguments
   ------------------------------------------------------------------

   procedure Test_Invalid is
      Raised : Boolean;
   begin
      Section ("Invalid_Argument");

      Raised := False;
      begin
         declare
            Bad : constant Permutation :=
              Make_Permutation ([1, 1, 3, others => 1], 3);
            pragma Unreferenced (Bad);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "non-bijective Make_Permutation raises");

      Raised := False;
      begin
         declare
            Bad : constant Permutation := Identity (99);
            pragma Unreferenced (Bad);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Identity(99) raises");

      Raised := False;
      begin
         declare
            Empty : Generator_List (1 .. 0);
            G     : constant BSGS := Build_BSGS (Empty);
            pragma Unreferenced (G);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "empty Generator_List raises");

      Raised := False;
      begin
         declare
            A : constant Permutation := Identity (3);
            B : constant Permutation := Identity (4);
            C : constant Permutation := Compose (A, B);
            pragma Unreferenced (C);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Compose mismatched degrees raises");

      Raised := False;
      begin
         declare
            G3 : constant BSGS := Build_BSGS ([Identity (3)]);
            P4 : constant Permutation := Identity (4);
            B  : Boolean;
         begin
            B := Contains (G3, P4);
            pragma Unreferenced (B);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Contains degree mismatch raises");
   end Test_Invalid;

   ------------------------------------------------------------------
   --  Trivial / cyclic
   ------------------------------------------------------------------

   procedure Test_Trivial_And_Cyclic is
      Id : constant Permutation := Identity (5);
      --  (1 2 3 4 5)
      Rot : constant Permutation :=
        P (5, [2, 3, 4, 5, 1, others => 1]);
      G_Id  : constant BSGS := Build_BSGS ([Id]);
      G_C5  : constant BSGS := Build_BSGS ([Rot]);
      Rot2  : constant Permutation := Compose (Rot, Rot);
      Rot3  : constant Permutation := Compose (Rot2, Rot);
      Rot4  : constant Permutation := Compose (Rot3, Rot);
      --  transposition not in <rot>
      Bad : constant Permutation :=
        P (5, [2, 1, 3, 4, 5, others => 1]);
   begin
      Section ("Trivial and cyclic");
      Check (Order (G_Id) = 1, "trivial group order 1");
      Check (Base_Length (G_Id) = 0, "trivial base length 0");
      Check (Contains (G_Id, Id), "trivial contains id");
      Check (Order (G_C5) = 5, "C5 order 5");
      Check (Contains (G_C5, Id), "C5 contains id");
      Check (Contains (G_C5, Rot), "C5 contains rot");
      Check (Contains (G_C5, Rot2), "C5 contains rot^2");
      Check (Contains (G_C5, Rot3), "C5 contains rot^3");
      Check (Contains (G_C5, Rot4), "C5 contains rot^4");
      Check (not Contains (G_C5, Bad), "C5 rejects transposition");
      Check (Base_Length (G_C5) >= 1, "C5 has nonempty base");
   end Test_Trivial_And_Cyclic;

   ------------------------------------------------------------------
   --  S3
   ------------------------------------------------------------------

   procedure Test_S3 is
      --  Generators: (1 2), (1 2 3)
      A : constant Permutation := P (3, [2, 1, 3, others => 1]);
      B : constant Permutation := P (3, [2, 3, 1, others => 1]);
      G : constant BSGS := Build_BSGS ([A, B]);
      --  All 6 elements of S3
      E : constant Permutation := Identity (3);
      T12 : constant Permutation := A;
      T13 : constant Permutation := P (3, [3, 2, 1, others => 1]);
      T23 : constant Permutation := P (3, [1, 3, 2, others => 1]);
      C123 : constant Permutation := B;
      C132 : constant Permutation := P (3, [3, 1, 2, others => 1]);
   begin
      Section ("S3");
      Check (Order (G) = 6, "S3 order 6");
      Check (Contains (G, E), "S3 contains id");
      Check (Contains (G, T12), "S3 contains (1 2)");
      Check (Contains (G, T13), "S3 contains (1 3)");
      Check (Contains (G, T23), "S3 contains (2 3)");
      Check (Contains (G, C123), "S3 contains (1 2 3)");
      Check (Contains (G, C132), "S3 contains (1 3 2)");
      Check (Base_Length (G) >= 1, "S3 base nonempty");
      Check (G.Levels (1).Orbit_Size = 3, "S3 first orbit size 3");
   end Test_S3;

   ------------------------------------------------------------------
   --  S4
   ------------------------------------------------------------------

   procedure Test_S4 is
      --  Adjacent transpositions generate S4
      T12 : constant Permutation := P (4, [2, 1, 3, 4, others => 1]);
      T23 : constant Permutation := P (4, [1, 3, 2, 4, others => 1]);
      T34 : constant Permutation := P (4, [1, 2, 4, 3, others => 1]);
      G   : constant BSGS := Build_BSGS ([T12, T23, T34]);
      --  Alternative generators: (1 2), (1 2 3 4)
      A : constant Permutation := T12;
      R : constant Permutation := P (4, [2, 3, 4, 1, others => 1]);
      G2 : constant BSGS := Build_BSGS ([A, R]);
      --  Known elements
      C1234 : constant Permutation := R;
      Dbl   : constant Permutation :=
        P (4, [2, 1, 4, 3, others => 1]);  -- (1 2)(3 4)
      --  Not used as non-element inside S4 — everything is in S4.
      --  Check a 3-cycle:
      C123 : constant Permutation := P (4, [2, 3, 1, 4, others => 1]);
   begin
      Section ("S4");
      Check (Order (G) = 24, "S4 (adj trans) order 24");
      Check (Order (G2) = 24, "S4 ((1 2),(1 2 3 4)) order 24");
      Check (Contains (G, Identity (4)), "S4 contains id");
      Check (Contains (G, T12), "S4 contains (1 2)");
      Check (Contains (G, C1234), "S4 contains (1 2 3 4)");
      Check (Contains (G, Dbl), "S4 contains (1 2)(3 4)");
      Check (Contains (G, C123), "S4 contains (1 2 3)");
      Check (Contains (G2, T34), "S4 alt contains (3 4)");
      Check (Contains (G2, T23), "S4 alt contains (2 3)");
   end Test_S4;

   ------------------------------------------------------------------
   --  A4
   ------------------------------------------------------------------

   procedure Test_A4 is
      --  A4 generated by 3-cycles (1 2 3), (1 2 4)
      C123 : constant Permutation := P (4, [2, 3, 1, 4, others => 1]);
      C124 : constant Permutation := P (4, [2, 4, 3, 1, others => 1]);
      G    : constant BSGS := Build_BSGS ([C123, C124]);
      --  Double transposition (even): (1 2)(3 4)
      V1 : constant Permutation := P (4, [2, 1, 4, 3, others => 1]);
      V2 : constant Permutation := P (4, [3, 4, 1, 2, others => 1]);
      V3 : constant Permutation := P (4, [4, 3, 2, 1, others => 1]);
      --  Odd permutation (1 2) — not in A4
      Odd : constant Permutation := P (4, [2, 1, 3, 4, others => 1]);
      --  (1 2 3 4) is odd? sign = -1 for 4-cycle — not in A4
      C4 : constant Permutation := P (4, [2, 3, 4, 1, others => 1]);
   begin
      Section ("A4");
      Check (Order (G) = 12, "A4 order 12");
      Check (Contains (G, Identity (4)), "A4 contains id");
      Check (Contains (G, C123), "A4 contains (1 2 3)");
      Check (Contains (G, C124), "A4 contains (1 2 4)");
      Check (Contains (G, V1), "A4 contains (1 2)(3 4)");
      Check (Contains (G, V2), "A4 contains (1 3)(2 4)");
      Check (Contains (G, V3), "A4 contains (1 4)(2 3)");
      Check (not Contains (G, Odd), "A4 rejects (1 2)");
      Check (not Contains (G, C4), "A4 rejects (1 2 3 4)");
   end Test_A4;

   ------------------------------------------------------------------
   --  D4 (dihedral of the square) inside S4
   ------------------------------------------------------------------

   procedure Test_D4 is
      --  Rotation (1 2 3 4), reflection (2 4)
      Rot : constant Permutation := P (4, [2, 3, 4, 1, others => 1]);
      Ref : constant Permutation := P (4, [1, 4, 3, 2, others => 1]);
      G   : constant BSGS := Build_BSGS ([Rot, Ref]);
      Rot2 : constant Permutation := Compose (Rot, Rot);  -- (1 3)(2 4)
      Rot3 : constant Permutation := Compose (Rot2, Rot);
      --  (1 2)(3 4) is in D4? With this embedding:
      --  D4 = {id, rot, rot2, rot3, ref, rot*ref, rot2*ref, rot3*ref}
      RF : constant Permutation := Compose (Rot, Ref);
      --  3-cycle not in D4
      C123 : constant Permutation := P (4, [2, 3, 1, 4, others => 1]);
      --  (1 2) alone not in this D4
      T12 : constant Permutation := P (4, [2, 1, 3, 4, others => 1]);
   begin
      Section ("D4");
      Check (Order (G) = 8, "D4 order 8");
      Check (Contains (G, Identity (4)), "D4 contains id");
      Check (Contains (G, Rot), "D4 contains rotation");
      Check (Contains (G, Rot2), "D4 contains rot^2");
      Check (Contains (G, Rot3), "D4 contains rot^3");
      Check (Contains (G, Ref), "D4 contains reflection");
      Check (Contains (G, RF), "D4 contains rot*ref");
      Check (not Contains (G, C123), "D4 rejects (1 2 3)");
      Check (not Contains (G, T12), "D4 rejects (1 2)");
   end Test_D4;

   ------------------------------------------------------------------
   --  Klein four-group V4 ≤ S4
   ------------------------------------------------------------------

   procedure Test_Klein is
      A : constant Permutation := P (4, [2, 1, 4, 3, others => 1]);
      --  (1 2)(3 4)
      B : constant Permutation := P (4, [3, 4, 1, 2, others => 1]);
      --  (1 3)(2 4)
      C : constant Permutation := P (4, [4, 3, 2, 1, others => 1]);
      --  (1 4)(2 3) = A*B
      G : constant BSGS := Build_BSGS ([A, B]);
      Odd : constant Permutation := P (4, [2, 1, 3, 4, others => 1]);
   begin
      Section ("Klein four");
      Check (Order (G) = 4, "V4 order 4");
      Check (Contains (G, Identity (4)), "V4 contains id");
      Check (Contains (G, A), "V4 contains (1 2)(3 4)");
      Check (Contains (G, B), "V4 contains (1 3)(2 4)");
      Check (Contains (G, C), "V4 contains (1 4)(2 3)");
      Check (not Contains (G, Odd), "V4 rejects (1 2)");
      Check (Is_Identity (Compose (A, A)), "V4 elt order 2");
   end Test_Klein;

   ------------------------------------------------------------------
   --  Extra: C4, S2, product checks, base observers
   ------------------------------------------------------------------

   procedure Test_Extra is
      R4 : constant Permutation := P (4, [2, 3, 4, 1, others => 1]);
      G4 : constant BSGS := Build_BSGS ([R4]);
      T  : constant Permutation := P (2, [2, 1, others => 1]);
      G2 : constant BSGS := Build_BSGS ([T]);
      --  S5 via adjacent transpositions (order 120) — N=5 ≤ 10
      A12 : constant Permutation :=
        P (5, [2, 1, 3, 4, 5, others => 1]);
      A23 : constant Permutation :=
        P (5, [1, 3, 2, 4, 5, others => 1]);
      A34 : constant Permutation :=
        P (5, [1, 2, 4, 3, 5, others => 1]);
      A45 : constant Permutation :=
        P (5, [1, 2, 3, 5, 4, others => 1]);
      S5 : constant BSGS := Build_BSGS ([A12, A23, A34, A45]);
      --  A5 via 3-cycles (1 2 3), (1 2 4), (1 2 5) — order 60
      C123 : constant Permutation :=
        P (5, [2, 3, 1, 4, 5, others => 1]);
      C124 : constant Permutation :=
        P (5, [2, 4, 3, 1, 5, others => 1]);
      C125 : constant Permutation :=
        P (5, [2, 5, 3, 4, 1, others => 1]);
      A5 : constant BSGS := Build_BSGS ([C123, C124, C125]);
      Odd5 : constant Permutation := A12;
   begin
      Section ("Extra groups / observers");
      Check (Order (G4) = 4, "C4 order 4");
      Check (Contains (G4, Compose (R4, R4)), "C4 contains rot^2");
      Check (Order (G2) = 2, "S2 order 2");
      Check (Contains (G2, T), "S2 contains transposition");
      Check (Order (S5) = 120, "S5 order 120");
      Check (Contains (S5, A12), "S5 contains (1 2)");
      Check (Order (A5) = 60, "A5 order 60");
      Check (Contains (A5, C123), "A5 contains (1 2 3)");
      Check (not Contains (A5, Odd5), "A5 rejects (1 2)");
      Check (Base_Length (S5) >= 2, "S5 base length >= 2");
      Check (Base_Point (S5, 1) >= 1, "S5 base point 1 valid");

      --  Inconsistent degrees in generator list
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               Bad : constant BSGS :=
                 Build_BSGS ([Identity (3), Identity (4)]);
               pragma Unreferenced (Bad);
            begin
               null;
            end;
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "inconsistent generator degrees raise");
      end;

      --  Non-bijective stored? Make_Permutation already guards; also
      --  image with out-of-range would raise:
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               Bad : constant Permutation :=
                 Make_Permutation ([2, 3, 4, others => 1], 3);
               pragma Unreferenced (Bad);
            begin
               null;
            end;
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "image value > N raises");
      end;
   end Test_Extra;

begin
   Ada.Text_IO.Put_Line ("Schreier_Sims test suite");
   Ada.Text_IO.Put_Line ("========================");

   Test_Primitives;
   Test_Invalid;
   Test_Trivial_And_Cyclic;
   Test_S3;
   Test_S4;
   Test_A4;
   Test_D4;
   Test_Klein;
   Test_Extra;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;

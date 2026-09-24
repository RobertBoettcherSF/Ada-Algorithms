--  Standalone test suite for Gale_Shapley_Algorithm.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Gale_Shapley_Algorithm; use Gale_Shapley_Algorithm;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Pid (X : Positive) return Person_Id is (Person_Id (X));

   type Nat_List is array (Positive range <>) of Natural;

   function Clear_Raises (Size : Natural) return Boolean is
      Inst : Instance;
   begin
      Clear (Inst, Size);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Set_P_Raises
     (Inst     : in out Instance;
      Proposer : Person_Id;
      Rank     : Person_Id;
      Receiver : Person_Id) return Boolean
   is
   begin
      Set_Proposer_Choice (Inst, Proposer, Rank, Receiver);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_P_Raises;

   function Set_R_Raises
     (Inst     : in out Instance;
      Receiver : Person_Id;
      Rank     : Person_Id;
      Proposer : Person_Id) return Boolean
   is
   begin
      Set_Receiver_Choice (Inst, Receiver, Rank, Proposer);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_R_Raises;

   function Load_P_Raises
     (Inst : in out Instance; Prefs : Pref_Matrix) return Boolean
   is
   begin
      Load_Proposer_Prefs (Inst, Prefs);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_P_Raises;

   function Load_Both_Raises
     (A, B : Pref_Matrix) return Boolean
   is
      Inst : Instance;
   begin
      Load (Inst, A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_Both_Raises;

   function Choice_P_Raises
     (Inst : Instance; Proposer, Rank : Person_Id) return Boolean
   is
      Unused : Person_Id;
   begin
      Unused := Proposer_Choice (Inst, Proposer, Rank);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Choice_P_Raises;

   function Rank_P_Raises
     (Inst : Instance; Proposer, Receiver : Person_Id) return Boolean
   is
      Unused : Person_Id;
   begin
      Unused := Proposer_Rank (Inst, Proposer, Receiver);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Rank_P_Raises;

   function Mate_Raises
     (Result : Matching; Proposer : Person_Id) return Boolean
   is
      Unused : Person_Id;
   begin
      Unused := Receiver_Of (Result, Proposer);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Mate_Raises;

   function Solve_Raises (Inst : Instance) return Boolean is
      R : Matching;
   begin
      Solve (Inst, R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Solve_Raises;

   function Mates_Equal (A, B : Matching) return Boolean is
   begin
      if A.N /= B.N then
         return False;
      end if;
      for I in 1 .. A.N loop
         if A.Proposer_Mate (I) /= B.Proposer_Mate (I)
           or else A.Receiver_Mate (I) /= B.Receiver_Mate (I)
         then
            return False;
         end if;
      end loop;
      return True;
   end Mates_Equal;

   procedure Expect_Stable
     (Inst : Instance; Who : Side; Label : String)
   is
      R : Matching;
   begin
      Solve (Inst, R, Who);
      Check (Is_Bijection (R), Label & " bijection");
      Check (Is_Stable (Inst, R), Label & " stable");
   end Expect_Stable;

   procedure Expect_Identity (Inst : Instance; Label : String) is
      R : Matching;
      Ok : Boolean := True;
   begin
      Solve (Inst, R);
      for I in 1 .. Size (Inst) loop
         if R.Proposer_Mate (I) /= I then
            Ok := False;
         end if;
      end loop;
      Check (Ok, Label & " identity matching");
      Check (Is_Stable (Inst, R), Label & " stable");
   end Expect_Identity;

   procedure Check_Dual_Swap (Inst : Instance; Label : String) is
      --  Receiver-proposing on Inst equals proposer-proposing on the
      --  swapped-side instance, with mate arrays swapped back.
      Swapped : Instance;
      A, B    : Matching;
      N       : constant Natural := Size (Inst);
      Ok      : Boolean := True;
   begin
      Clear (Swapped, N);
      for I in 1 .. N loop
         for K in 1 .. N loop
            Set_Proposer_Choice
              (Swapped, Pid (I), Pid (K),
               Receiver_Choice (Inst, Pid (I), Pid (K)));
            Set_Receiver_Choice
              (Swapped, Pid (I), Pid (K),
               Proposer_Choice (Inst, Pid (I), Pid (K)));
         end loop;
      end loop;
      Solve (Inst, A, Receivers);
      Solve (Swapped, B, Proposers);
      for I in 1 .. N loop
         if A.Proposer_Mate (I) /= B.Receiver_Mate (I)
           or else A.Receiver_Mate (I) /= B.Proposer_Mate (I)
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, Label & " dual = swapped sides");
      Check (Is_Stable (Inst, A), Label & " dual stable");
   end Check_Dual_Swap;

   --  Apply list L(1 .. N) = Start, Start+1, ... wrapping, to one person.
   procedure Set_Rotated_P
     (Inst : in out Instance; Person, Start, N : Natural)
   is
   begin
      for K in 1 .. N loop
         declare
            Partner : constant Positive :=
              ((Start - 1 + K - 1) mod N) + 1;
         begin
            Set_Proposer_Choice
              (Inst, Pid (Person), Pid (K), Pid (Partner));
         end;
      end loop;
   end Set_Rotated_P;

   procedure Set_Rotated_R
     (Inst : in out Instance; Person, Start, N : Natural)
   is
   begin
      for K in 1 .. N loop
         declare
            Partner : constant Positive :=
              ((Start - 1 + K - 1) mod N) + 1;
         begin
            Set_Receiver_Choice
              (Inst, Pid (Person), Pid (K), Pid (Partner));
         end;
      end loop;
   end Set_Rotated_R;

   procedure Fill_All_Rotated
     (Inst : in out Instance; N, P_Start, R_Start : Natural)
   is
   begin
      Clear (Inst, N);
      for I in 1 .. N loop
         Set_Rotated_P (Inst, I, P_Start, N);
         Set_Rotated_R (Inst, I, R_Start, N);
      end loop;
   end Fill_All_Rotated;

   procedure Fill_Cyclic
     (Inst : in out Instance; N : Natural)
   is
   begin
      Clear (Inst, N);
      for I in 1 .. N loop
         Set_Rotated_P (Inst, I, I, N);
         Set_Rotated_R (Inst, I, I, N);
      end loop;
   end Fill_Cyclic;

   --  Two-choice list for n=2: Flip=False => (1,2), True => (2,1).
   procedure Set_N2_List_P
     (Inst : in out Instance; Person : Positive; Flip : Boolean)
   is
   begin
      if Flip then
         Set_Proposer_Choice (Inst, Pid (Person), 1, 2);
         Set_Proposer_Choice (Inst, Pid (Person), 2, 1);
      else
         Set_Proposer_Choice (Inst, Pid (Person), 1, 1);
         Set_Proposer_Choice (Inst, Pid (Person), 2, 2);
      end if;
   end Set_N2_List_P;

   procedure Set_N2_List_R
     (Inst : in out Instance; Person : Positive; Flip : Boolean)
   is
   begin
      if Flip then
         Set_Receiver_Choice (Inst, Pid (Person), 1, 2);
         Set_Receiver_Choice (Inst, Pid (Person), 2, 1);
      else
         Set_Receiver_Choice (Inst, Pid (Person), 1, 1);
         Set_Receiver_Choice (Inst, Pid (Person), 2, 2);
      end if;
   end Set_N2_List_R;

   --  Brute-force: every permutation; verify GS is proposer-optimal
   --  and receiver-pessimal among stable matchings. N ≤ 6.
   procedure Check_Optimality (Inst : Instance; Label : String) is
      N : constant Natural := Size (Inst);
      GS, Dual : Matching;
      Pi       : array (1 .. 8) of Natural;
      Used     : array (1 .. 8) of Boolean := [others => False];
      Stable_Count : Natural := 0;
      Prop_Best : array (1 .. 8) of Natural := [others => 0];
      Rec_Worst : array (1 .. 8) of Natural := [others => 0];
      Ok_P, Ok_R : Boolean := True;

      function Rank_P (P, R : Natural) return Natural is
      begin
         return Natural (Proposer_Rank (Inst, Pid (P), Pid (R)));
      end Rank_P;

      function Rank_R (R, P : Natural) return Natural is
      begin
         return Natural (Receiver_Rank (Inst, Pid (R), Pid (P)));
      end Rank_R;

      function Pi_Stable return Boolean is
      begin
         for P in 1 .. N loop
            for R in 1 .. N loop
               if R /= Pi (P) then
                  declare
                     Q : Natural := 0;
                  begin
                     for S in 1 .. N loop
                        if Pi (S) = R then
                           Q := S;
                        end if;
                     end loop;
                     if Rank_P (P, R) < Rank_P (P, Pi (P))
                       and then Rank_R (R, P) < Rank_R (R, Q)
                     then
                        return False;
                     end if;
                  end;
               end if;
            end loop;
         end loop;
         return True;
      end Pi_Stable;

      procedure Recurse (Pos : Natural) is
      begin
         if Pos > N then
            if Pi_Stable then
               Stable_Count := Stable_Count + 1;
               for P in 1 .. N loop
                  declare
                     Rp : constant Natural := Rank_P (P, Pi (P));
                  begin
                     if Prop_Best (P) = 0 or else Rp < Prop_Best (P) then
                        Prop_Best (P) := Rp;
                     end if;
                  end;
                  declare
                     Rr : constant Natural := Rank_R (Pi (P), P);
                  begin
                     if Rec_Worst (Pi (P)) = 0
                       or else Rr > Rec_Worst (Pi (P))
                     then
                        Rec_Worst (Pi (P)) := Rr;
                     end if;
                  end;
               end loop;
            end if;
            return;
         end if;
         for J in 1 .. N loop
            if not Used (J) then
               Used (J) := True;
               Pi (Pos) := J;
               Recurse (Pos + 1);
               Used (J) := False;
            end if;
         end loop;
      end Recurse;
   begin
      Solve (Inst, GS, Proposers);
      Solve (Inst, Dual, Receivers);
      Recurse (1);
      Check (Stable_Count >= 1, Label & " ≥1 stable");
      Check (Is_Stable (Inst, GS), Label & " GS stable");
      Check (Is_Stable (Inst, Dual), Label & " dual stable");
      for P in 1 .. N loop
         if Rank_P (P, GS.Proposer_Mate (P)) /= Prop_Best (P) then
            Ok_P := False;
         end if;
         if Rank_R (P, GS.Receiver_Mate (P)) /= Rec_Worst (P) then
            Ok_R := False;
         end if;
      end loop;
      Check (Ok_P, Label & " proposer-optimal");
      Check (Ok_R, Label & " receiver-pessimal");
   end Check_Optimality;

begin
   Put_Line ("Gale_Shapley_Algorithm test suite");
   Put_Line ("=================================");

   ---------------------------------------------------------------------
   Section ("1. Empty N=0");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
      Empty_P : Pref_Matrix (1 .. 0, 1 .. 0);
   begin
      Clear (Inst, Nat (0));
      Check (Size (Inst) = 0, "Size 0 after Clear");
      Solve (Inst, R);
      Check (R.N = 0, "empty matching N");
      Check (Is_Bijection (R), "empty bijection");
      Check (Is_Stable (Inst, R), "empty stable");
      Check (Is_Permutation (R.Proposer_Mate, Nat (0)), "empty perm");
      Check (Is_Complete_Permutation (Empty_P, Nat (0)), "empty prefs ok");
      R := Match (Inst);
      Check (R.N = 0, "Match empty N");
      Load (Inst, Empty_P, Empty_P);
      Check (Size (Inst) = 0, "Load empty Size");
   end;

   ---------------------------------------------------------------------
   Section ("2. N=1 trivial");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
   begin
      Clear (Inst, Nat (1));
      Check (Size (Inst) = 1, "Size 1");
      Check (Proposer_Choice (Inst, 1, 1) = 1, "P choice 1");
      Check (Receiver_Choice (Inst, 1, 1) = 1, "R choice 1");
      Check (Proposer_Rank (Inst, 1, 1) = 1, "P rank 1");
      Check (Receiver_Rank (Inst, 1, 1) = 1, "R rank 1");
      Solve (Inst, R);
      Check (R.N = 1, "N=1 result N");
      Check (R.Proposer_Mate (1) = 1, "1-1");
      Check (R.Receiver_Mate (1) = 1, "1-1 inv");
      Check (Is_Stable (Inst, R), "N=1 stable");
      Check (Receiver_Of (R, 1) = 1, "Receiver_Of");
      Check (Proposer_Of (R, 1) = 1, "Proposer_Of");
      Solve (Inst, R, Receivers);
      Check (R.Proposer_Mate (1) = 1, "N=1 dual 1-1");
   end;

   ---------------------------------------------------------------------
   Section ("3. Identity preferences N=2..8");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
   begin
      for N of Nat_List'[2, 4, 8] loop
         Clear (Inst, N);
         Expect_Identity (Inst, "id n=" & Natural'Image (N));
         Expect_Stable (Inst, Receivers, "id dual n=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. N=2 exhaustive preference profiles");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      A, B : Matching;
      Tag  : String (1 .. 4);
      Bits : array (1 .. 4) of Boolean;
   begin
      for Mask in 0 .. 15 loop
         Clear (Inst, 2);
         Bits (1) := (Mask rem 2) = 1;
         Bits (2) := ((Mask / 2) rem 2) = 1;
         Bits (3) := ((Mask / 4) rem 2) = 1;
         Bits (4) := ((Mask / 8) rem 2) = 1;
         Set_N2_List_P (Inst, 1, Bits (1));
         Set_N2_List_P (Inst, 2, Bits (2));
         Set_N2_List_R (Inst, 1, Bits (3));
         Set_N2_List_R (Inst, 2, Bits (4));
         for K in 1 .. 4 loop
            if Bits (K) then
               Tag (K) := '1';
            else
               Tag (K) := '0';
            end if;
         end loop;
         Expect_Stable (Inst, Proposers, "n2 " & Tag);
         Solve (Inst, A, Receivers);
         Check (Is_Stable (Inst, A), "n2 dual stable " & Tag);
         Check (Is_Bijection (A), "n2 dual bij " & Tag);
         Solve (Inst, A, Proposers);
         B := Match (Inst, Proposers);
         Check (Mates_Equal (A, B), "n2 Match=Solve " & Tag);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Classic n=3 with two stable matchings");
   ---------------------------------------------------------------------
   --  Proposers: 1: 1 2 3 | 2: 2 1 3 | 3: 1 2 3
   --  Receivers: 1: 2 1 3 | 2: 1 2 3 | 3: 1 2 3
   --  Proposer-optimal: 1-1, 2-2, 3-3
   --  Receiver-optimal: 1-2, 2-1, 3-3
   declare
      Inst : Instance;
      GS, Dual : Matching;
      PP : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[1, 2, 3],
         [2, 1, 3],
         [1, 2, 3]];
      RR : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[2, 1, 3],
         [1, 2, 3],
         [1, 2, 3]];
   begin
      Load (Inst, PP, RR);
      Check (Size (Inst) = 3, "classic n=3 Size");
      Check (Proposer_Choice (Inst, 2, 1) = 2, "P2 first is 2");
      Check (Receiver_Choice (Inst, 1, 1) = 2, "R1 first is 2");
      Check (Prefers (Inst, Proposers, 2, 2, 1), "P2 prefers 2 to 1");
      Check (not Prefers (Inst, Proposers, 2, 1, 2), "P2 not 1 over 2");
      Solve (Inst, GS, Proposers);
      Solve (Inst, Dual, Receivers);
      Check (GS.Proposer_Mate (1) = 1, "GS 1-1");
      Check (GS.Proposer_Mate (2) = 2, "GS 2-2");
      Check (GS.Proposer_Mate (3) = 3, "GS 3-3");
      Check (Dual.Proposer_Mate (1) = 2, "dual 1-2");
      Check (Dual.Proposer_Mate (2) = 1, "dual 2-1");
      Check (Dual.Proposer_Mate (3) = 3, "dual 3-3");
      Check (not Mates_Equal (GS, Dual), "two distinct stables");
      Check (Is_Stable (Inst, GS), "GS stable");
      Check (Is_Stable (Inst, Dual), "dual stable");
      Check_Dual_Swap (Inst, "classic3");
      Check_Optimality (Inst, "classic3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Reverse / anti-identity lists");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
   begin
      for N of Nat_List'[2, 3, 5] loop
         Clear (Inst, N);
         for I in 1 .. N loop
            for K in 1 .. N loop
               Set_Proposer_Choice
                 (Inst, Pid (I), Pid (K), Pid (N - K + 1));
               Set_Receiver_Choice
                 (Inst, Pid (I), Pid (K), Pid (N - K + 1));
            end loop;
         end loop;
         Expect_Stable (Inst, Proposers, "rev n=" & Natural'Image (N));
         Expect_Stable (Inst, Receivers, "rev dual n=" & Natural'Image (N));
         Solve (Inst, R);
         --  Both sides rank N best, then N-1, ... so the highest-index
         --  proposer keeps N, the next keeps N-1, ... i.e. identity.
         declare
            Ok : Boolean := True;
         begin
            for I in 1 .. N loop
               if R.Proposer_Mate (I) /= I then
                  Ok := False;
               end if;
            end loop;
            Check (Ok, "rev n=" & Natural'Image (N) & " identity");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. All proposers share one list");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
   begin
      for N of Nat_List'[2, 4, 6] loop
         Fill_All_Rotated (Inst, N, 1, 1);
         Expect_Stable (Inst, Proposers, "same n=" & Natural'Image (N));
         Solve (Inst, R);
         --  All proposers want 1,2,...,N; all receivers want 1,2,...,N
         --  so identity (P1 keeps 1, P2 gets 2, ...).
         declare
            Ok : Boolean := True;
         begin
            for I in 1 .. N loop
               if R.Proposer_Mate (I) /= I then
                  Ok := False;
               end if;
            end loop;
            Check (Ok, "same-list identity n=" & Natural'Image (N));
         end;
         Check_Dual_Swap (Inst, "same n=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Cyclic (rotated-by-person) preferences");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
   begin
      for N of Nat_List'[3, 5, 7] loop
         Fill_Cyclic (Inst, N);
         Expect_Stable (Inst, Proposers, "cyc n=" & Natural'Image (N));
         Expect_Stable (Inst, Receivers, "cyc dual n=" & Natural'Image (N));
         Check_Dual_Swap (Inst, "cyc n=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("9. Shifted shared lists");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
   begin
      for N of Nat_List'[3, 4, 5] loop
         Fill_All_Rotated (Inst, N, 2, N);
         Expect_Stable (Inst, Proposers, "sh n=" & Natural'Image (N));
         Expect_Stable (Inst, Receivers, "sh dual n=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Rank lookup and Prefers");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      PP : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[3, 1, 2],
         [2, 3, 1],
         [1, 2, 3]];
      RR : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[2, 3, 1],
         [1, 2, 3],
         [3, 2, 1]];
   begin
      Load (Inst, PP, RR);
      Check (Proposer_Rank (Inst, 1, 3) = 1, "P1 ranks 3 first");
      Check (Proposer_Rank (Inst, 1, 1) = 2, "P1 ranks 1 second");
      Check (Proposer_Rank (Inst, 1, 2) = 3, "P1 ranks 2 last");
      Check (Receiver_Rank (Inst, 1, 2) = 1, "R1 ranks 2 first");
      Check (Receiver_Rank (Inst, 3, 1) = 3, "R3 ranks 1 last");
      Check (Proposer_Choice (Inst, 2, 1) = 2, "P2#1=2");
      Check (Receiver_Choice (Inst, 3, 2) = 2, "R3#2=2");
      Check (Prefers (Inst, Proposers, 1, 3, 2), "P1: 3>2");
      Check (Prefers (Inst, Receivers, 3, 3, 1), "R3: 3>1");
      Check (not Prefers (Inst, Proposers, 3, 3, 1), "P3: not 3>1");
      Check (not Prefers (Inst, Proposers, 1, 1, 1), "P1: 1 not > 1");
   end;

   ---------------------------------------------------------------------
   Section ("11. Is_Complete_Permutation / Is_Permutation");
   ---------------------------------------------------------------------
   declare
      Ok3 : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[1, 2, 3],
         [2, 3, 1],
         [3, 1, 2]];
      Dup : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[1, 1, 2],
         [1, 2, 3],
         [3, 2, 1]];
      Zero : constant Pref_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 2],
         [0, 1]];
      Big : constant Pref_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 2],
         [1, 3]];
      Off : constant Pref_Matrix (2 .. 3, 2 .. 3) :=
        [[1, 2],
         [2, 1]];
      Wide : constant Pref_Matrix (1 .. 3, 1 .. 4) :=
        [[1, 2, 3, 1],
         [2, 3, 1, 1],
         [3, 1, 2, 1]];
      A_Ok : constant Mate_Array (1 .. 4) := [1, 3, 2, 4];
      A_Dup : constant Mate_Array (1 .. 3) := [1, 2, 1];
      A_Short : constant Mate_Array (1 .. 2) := [1, 2];
   begin
      Check (Is_Complete_Permutation (Ok3, 3), "ok3 perm");
      Check (not Is_Complete_Permutation (Dup, 3), "dup not perm");
      Check (not Is_Complete_Permutation (Zero, 2), "zero not perm");
      Check (not Is_Complete_Permutation (Big, 2), "oob not perm");
      Check (not Is_Complete_Permutation (Off, 2), "off-base not perm");
      Check (Is_Complete_Permutation (Wide, 3), "wide extra col ok");
      Check (not Is_Complete_Permutation (Wide, 4), "wide short rows");
      Check (Is_Complete_Permutation (Ok3, Nat (0)), "N=0 ignores");
      Check (Is_Permutation (A_Ok, 4), "mate perm");
      Check (not Is_Permutation (A_Dup, 3), "mate dup");
      Check (not Is_Permutation (A_Short, 3), "mate short");
      Check (Is_Permutation (A_Ok, Nat (0)), "mate N=0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Is_Stable rejects unstable / bad matchings");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
      PP : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[1, 2, 3],
         [2, 1, 3],
         [1, 2, 3]];
      RR : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[2, 1, 3],
         [1, 2, 3],
         [1, 2, 3]];
   begin
      Load (Inst, PP, RR);
      --  The receiver-optimal matching is stable, but a crossed pair
      --  that is NOT that matching may be unstable. Build 1-3, 2-2, 3-1:
      --  P1 prefers 1 to 3, R1 is with 3 and prefers 1 to 3 (R1: 2,1,3)
      --  so (1,1) blocks.
      R.N := 3;
      R.Proposer_Mate := [others => 0];
      R.Receiver_Mate := [others => 0];
      R.Proposer_Mate (1) := 3;
      R.Proposer_Mate (2) := 2;
      R.Proposer_Mate (3) := 1;
      R.Receiver_Mate (3) := 1;
      R.Receiver_Mate (2) := 2;
      R.Receiver_Mate (1) := 3;
      Check (Is_Bijection (R), "crossed bijection");
      Check (not Is_Stable (Inst, R), "crossed unstable");
      --  Dimension mismatch
      R.N := 2;
      Check (not Is_Stable (Inst, R), "N mismatch");
      --  Not a bijection
      R.N := 3;
      R.Proposer_Mate (1) := 1;
      R.Proposer_Mate (2) := 1;
      R.Proposer_Mate (3) := 3;
      R.Receiver_Mate (1) := 1;
      R.Receiver_Mate (2) := 0;
      R.Receiver_Mate (3) := 3;
      Check (not Is_Bijection (R), "not bijection");
      Check (not Is_Stable (Inst, R), "not bijection unstable");
      --  Inverse broken
      R.Proposer_Mate (1) := 1;
      R.Proposer_Mate (2) := 2;
      R.Proposer_Mate (3) := 3;
      R.Receiver_Mate (1) := 2;
      R.Receiver_Mate (2) := 1;
      R.Receiver_Mate (3) := 3;
      Check (not Is_Bijection (R), "inverse broken");
   end;

   ---------------------------------------------------------------------
   Section ("13. Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Bad_Dup : constant Pref_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 1],
         [1, 2]];
      Bad_Rect : constant Pref_Matrix (1 .. 2, 1 .. 3) :=
        [[1, 2, 3],
         [2, 1, 3]];
      Ok2 : constant Pref_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 2],
         [2, 1]];
      Off : constant Pref_Matrix (2 .. 3, 2 .. 3) :=
        [[1, 2],
         [2, 1]];
      R : Matching;
   begin
      Check (Clear_Raises (Max_N + 1), "Clear Max_N+1");
      Check (Clear_Raises (Nat (10_000)), "Clear 10000");
      Clear (Inst, 2);
      Check (Set_P_Raises (Inst, 3, 1, 1), "Set P person OOB");
      Check (Set_P_Raises (Inst, 1, 3, 1), "Set P rank OOB");
      Check (Set_P_Raises (Inst, 1, 1, 3), "Set P partner OOB");
      Check (Set_R_Raises (Inst, 3, 1, 1), "Set R person OOB");
      Check (Load_P_Raises (Inst, Bad_Dup), "Load dup row");
      Check (Load_P_Raises (Inst, Bad_Rect), "Load rect");
      Check (Load_Both_Raises (Ok2, Bad_Dup), "Load both one bad");
      Check (Load_Both_Raises (Ok2, Bad_Rect), "Load both rect");
      --  Off-base: First = 2
      Check (Load_Both_Raises (Off, Off), "Load off-base");
      --  Load without matching Size
      Clear (Inst, 3);
      Check (Load_P_Raises (Inst, Ok2), "Load size mismatch");
      --  Inspectors
      Clear (Inst, 2);
      Check (Choice_P_Raises (Inst, 3, 1), "Choice OOB person");
      Check (Choice_P_Raises (Inst, 1, 3), "Choice OOB rank");
      Check (Rank_P_Raises (Inst, 3, 1), "Rank OOB");
      --  Incomplete prefs: duplicate then Solve
      Set_Proposer_Choice (Inst, 1, 1, 1);
      Set_Proposer_Choice (Inst, 1, 2, 1);
      Check (Solve_Raises (Inst), "Solve incomplete");
      --  Mate inspectors
      Clear (Inst, 2);
      Solve (Inst, R);
      Check (Mate_Raises (R, 3), "Receiver_Of OOB");
      --  Empty instance inspectors
      Clear (Inst, 0);
      Check (Choice_P_Raises (Inst, 1, 1), "Choice on empty");
      Check (Rank_P_Raises (Inst, 1, 1), "Rank on empty");
      --  Load_Proposer_Prefs on empty with non-empty matrix
      Check (Load_P_Raises (Inst, Ok2), "Load into N=0");
   end;

   ---------------------------------------------------------------------
   Section ("14. Set vs Load agreement");
   ---------------------------------------------------------------------
   declare
      A, B : Instance;
      RA, RB : Matching;
      PP : constant Pref_Matrix (1 .. 4, 1 .. 4) :=
        [[2, 1, 4, 3],
         [1, 3, 2, 4],
         [4, 3, 2, 1],
         [3, 2, 1, 4]];
      RR : constant Pref_Matrix (1 .. 4, 1 .. 4) :=
        [[4, 1, 2, 3],
         [2, 3, 1, 4],
         [1, 2, 3, 4],
         [3, 4, 1, 2]];
   begin
      Load (A, PP, RR);
      Clear (B, 4);
      for I in 1 .. 4 loop
         for K in 1 .. 4 loop
            Set_Proposer_Choice (B, Pid (I), Pid (K), Pid (PP (I, K)));
            Set_Receiver_Choice (B, Pid (I), Pid (K), Pid (RR (I, K)));
         end loop;
      end loop;
      Solve (A, RA);
      Solve (B, RB);
      Check (Mates_Equal (RA, RB), "Load vs Set matching");
      Check (Is_Stable (A, RA), "Load stable");
      Check (Is_Stable (B, RB), "Set stable");
      for I in 1 .. 4 loop
         Check
           (Proposer_Choice (A, Pid (I), 1)
            = Proposer_Choice (B, Pid (I), 1),
            "first choice I=" & Natural'Image (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("15. Match function vs Solve overloads");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      A, B, C : Matching;
   begin
      Fill_Cyclic (Inst, 5);
      Solve (Inst, A);
      Solve (Inst, B, Proposers);
      C := Match (Inst);
      Check (Mates_Equal (A, B), "Solve = Solve(Proposers)");
      Check (Mates_Equal (A, C), "Solve = Match");
      Solve (Inst, A, Receivers);
      C := Match (Inst, Receivers);
      Check (Mates_Equal (A, C), "Solve dual = Match dual");
   end;

   ---------------------------------------------------------------------
   Section ("16. Proposer-optimal brute-force families");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
   begin
      Clear (Inst, 3);
      Check_Optimality (Inst, "id3");
      Fill_Cyclic (Inst, 3);
      Check_Optimality (Inst, "cyc3");
      Fill_Cyclic (Inst, 4);
      Check_Optimality (Inst, "cyc4");
      Fill_All_Rotated (Inst, 4, 2, 3);
      Check_Optimality (Inst, "sh4");
      --  Asymmetric n=4
      declare
         PP : constant Pref_Matrix (1 .. 4, 1 .. 4) :=
           [[1, 2, 3, 4],
            [2, 1, 4, 3],
            [3, 4, 1, 2],
            [4, 3, 2, 1]];
         RR : constant Pref_Matrix (1 .. 4, 1 .. 4) :=
           [[4, 3, 2, 1],
            [1, 2, 3, 4],
            [2, 1, 4, 3],
            [3, 4, 1, 2]];
      begin
         Load (Inst, PP, RR);
         Check_Optimality (Inst, "asym4");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("17. Larger identity / cycle / shift");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
   begin
      declare
         Sizes : constant array (Positive range <>) of Positive :=
           [12, 16, 24, 32];
      begin
         for N of Sizes loop
            Clear (Inst, N);
            Solve (Inst, R);
            Check (Is_Stable (Inst, R), "large id n=" & Natural'Image (N));
            Check (Is_Bijection (R), "large id bij n=" & Natural'Image (N));
            Fill_Cyclic (Inst, N);
            Solve (Inst, R);
            Check (Is_Stable (Inst, R), "large cyc n=" & Natural'Image (N));
            Solve (Inst, R, Receivers);
            Check (Is_Stable (Inst, R), "large cyc dual n=" & Natural'Image (N));
         end loop;
      end;
      Clear (Inst, 48);
      Solve (Inst, R);
      Check (R.N = 48, "n=48 N");
      Check (Is_Stable (Inst, R), "n=48 stable");
      Fill_All_Rotated (Inst, 20, 7, 3);
      Expect_Stable (Inst, Proposers, "n=20 shift");
      Expect_Stable (Inst, Receivers, "n=20 shift dual");
   end;

   ---------------------------------------------------------------------
   Section ("18. Everyone matched + inspectors");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
      Seen : array (1 .. 10) of Boolean;
   begin
      Fill_Cyclic (Inst, 10);
      Solve (Inst, R);
      Seen := [others => False];
      for I in 1 .. 10 loop
         Seen (R.Proposer_Mate (I)) := True;
      end loop;
      Check
        (Natural (Receiver_Of (R, 1)) = R.Proposer_Mate (1),
         "Receiver_Of 1");
      Check
        (Natural (Proposer_Of (R, 1)) = R.Receiver_Mate (1),
         "Proposer_Of 1");
      Check
        (Natural (Receiver_Of (R, 10)) = R.Proposer_Mate (10),
         "Receiver_Of 10");
      declare
         Covered : Boolean := True;
      begin
         for I in 1 .. 10 loop
            if not Seen (I) then
               Covered := False;
            end if;
         end loop;
         Check (Covered, "all receivers matched");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("19. Unique stable matching (strict alignment)");
   ---------------------------------------------------------------------
   --  When both sides have identical identity lists the unique stable
   --  matching is the identity (and both proposing sides agree).
   declare
      Inst : Instance;
      A, B : Matching;
   begin
      for N in 1 .. 6 loop
         Clear (Inst, N);
         Solve (Inst, A, Proposers);
         Solve (Inst, B, Receivers);
         Check (Mates_Equal (A, B), "unique n=" & Natural'Image (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("20. Max_N smoke + Load identity");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Matching;
   begin
      Clear (Inst, Max_N);
      Check (Size (Inst) = Max_N, "Max_N Size");
      Check (Proposer_Choice (Inst, Pid (Max_N), Pid (Max_N)) = Pid (Max_N),
             "Max_N last choice");
      Solve (Inst, R);
      Check (R.N = Max_N, "Max_N result N");
      Check (R.Proposer_Mate (1) = 1, "Max_N 1-1");
      Check (R.Proposer_Mate (Max_N) = Max_N, "Max_N last-last");
      Check (Is_Bijection (R), "Max_N bijection");
      --  Stability on Max_N is O(n^3) = 128^3 ≈ 2e6 rank scans; cheap.
      Check (Is_Stable (Inst, R), "Max_N stable");
   end;

   ---------------------------------------------------------------------
   Section ("21. Prefers / rank after incremental overwrite");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
   begin
      Clear (Inst, 3);
      --  Rewrite proposer 1's list to 2, 3, 1
      Set_Proposer_Choice (Inst, 1, 1, 2);
      Set_Proposer_Choice (Inst, 1, 2, 3);
      Set_Proposer_Choice (Inst, 1, 3, 1);
      Check (Proposer_Choice (Inst, 1, 1) = 2, "overwrite #1");
      Check (Proposer_Rank (Inst, 1, 2) = 1, "overwrite rank 2");
      Check (Proposer_Rank (Inst, 1, 1) = 3, "overwrite rank 1");
      Check (Prefers (Inst, Proposers, 1, 2, 1), "overwrite prefers");
      Expect_Stable (Inst, Proposers, "after overwrite");
   end;

   ---------------------------------------------------------------------
   Section ("22. n=5 mixed rotations optimality");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
   begin
      Clear (Inst, 5);
      for I in 1 .. 5 loop
         Set_Rotated_P (Inst, I, ((I * 2 - 1) rem 5) + 1, 5);
         Set_Rotated_R (Inst, I, ((I * 3) rem 5) + 1, 5);
      end loop;
      Expect_Stable (Inst, Proposers, "mix5");
      Expect_Stable (Inst, Receivers, "mix5 dual");
      Check_Optimality (Inst, "mix5");
      Check_Dual_Swap (Inst, "mix5");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count)
      & " PASS," & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 and then Pass_Count >= 150 then
      Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILED OR TOO FEW");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

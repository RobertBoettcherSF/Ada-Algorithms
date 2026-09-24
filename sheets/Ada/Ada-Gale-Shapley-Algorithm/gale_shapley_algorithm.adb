--  Gale_Shapley_Algorithm body — deferred acceptance + stability checks.

pragma Ada_2022;

package body Gale_Shapley_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   procedure Raise_If_OOB (N : Natural; A, B : Person_Id) is
   begin
      if Natural (A) > N or else Natural (B) > N then
         raise Invalid_Argument;
      end if;
   end Raise_If_OOB;

   procedure Raise_If_OOB3
     (N : Natural; A, B, C : Person_Id)
   is
   begin
      if Natural (A) > N
        or else Natural (B) > N
        or else Natural (C) > N
      then
         raise Invalid_Argument;
      end if;
   end Raise_If_OOB3;

   function Row_Is_Permutation
     (Store : Pref_Store; Row : Person_Id; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      for K in 1 .. N loop
         declare
            V : constant Natural := Store (Row, Person_Id (K));
         begin
            if V < 1 or else V > N or else Seen (V) then
               return False;
            end if;
            Seen (V) := True;
         end;
      end loop;
      return True;
   end Row_Is_Permutation;

   function Prefs_Are_Valid (Inst : Instance) return Boolean is
   begin
      for I in 1 .. Inst.N loop
         if not Row_Is_Permutation (Inst.P_List, Person_Id (I), Inst.N)
           or else
             not Row_Is_Permutation (Inst.R_List, Person_Id (I), Inst.N)
         then
            return False;
         end if;
      end loop;
      return True;
   end Prefs_Are_Valid;

   procedure Ensure_Valid (Inst : Instance) is
   begin
      if not Prefs_Are_Valid (Inst) then
         raise Invalid_Argument;
      end if;
   end Ensure_Valid;

   function Rank_In_List
     (Store : Pref_Store; Person, Partner : Person_Id; N : Natural)
      return Person_Id
   is
   begin
      for K in 1 .. N loop
         if Store (Person, Person_Id (K)) = Natural (Partner) then
            return Person_Id (K);
         end if;
      end loop;
      raise Invalid_Argument;
   end Rank_In_List;

   function Choice_In_List
     (Store : Pref_Store; Person, Rank : Person_Id; N : Natural)
      return Person_Id
   is
      V : Natural;
   begin
      Raise_If_OOB (N, Person, Rank);
      V := Store (Person, Rank);
      if V < 1 or else V > N then
         raise Invalid_Argument;
      end if;
      return Person_Id (V);
   end Choice_In_List;

   procedure Copy_Pref_Row
     (Prefs : Pref_Matrix;
      Row   : Positive;
      N     : Natural;
      Dest  : in out Pref_Store)
   is
   begin
      for K in 1 .. N loop
         Dest (Person_Id (Row), Person_Id (K)) := Prefs (Row, K);
      end loop;
   end Copy_Pref_Row;

   procedure Check_Load_Shape
     (Prefs : Pref_Matrix; Expected_N : Natural)
   is
      Order : constant Natural := Prefs'Length (1);
   begin
      if Prefs'First (1) /= 1
        or else Prefs'First (2) /= 1
        or else Prefs'Length (2) /= Order
        or else Order /= Expected_N
        or else Order > Max_N
      then
         raise Invalid_Argument;
      end if;
      if not Is_Complete_Permutation (Prefs, Expected_N) then
         raise Invalid_Argument;
      end if;
   end Check_Load_Shape;

   procedure Build_Ranks
     (List : Pref_Store; N : Natural; Rank : out Pref_Store)
   is
   begin
      Rank := [others => [others => 0]];
      for I in 1 .. N loop
         for K in 1 .. N loop
            declare
               Partner : constant Natural :=
                 List (Person_Id (I), Person_Id (K));
            begin
               Rank (Person_Id (I), Person_Id (Partner)) := K;
            end;
         end loop;
      end loop;
   end Build_Ranks;

   ---------------------------------------------------------------------------
   -- Deferred acceptance (proposers propose down their lists)
   ---------------------------------------------------------------------------

   procedure Deferred_Acceptance
     (N         : Natural;
      Prop_List : Pref_Store;
      Rec_Rank  : Pref_Store;
      Prop_Mate : out Mate_Array;
      Rec_Mate  : out Mate_Array)
   is
      Next_Offer : array (1 .. Max_N) of Natural := [others => 1];
      Stack      : array (1 .. Max_N) of Natural := [others => 0];
      Top        : Natural := N;
      P, R, Q, K : Natural;
   begin
      for I in Prop_Mate'Range loop
         Prop_Mate (I) := 0;
      end loop;
      for I in Rec_Mate'Range loop
         Rec_Mate (I) := 0;
      end loop;

      if N = 0 then
         return;
      end if;

      for I in 1 .. N loop
         Stack (I) := I;
      end loop;

      while Top > 0 loop
         P := Stack (Top);
         Top := Top - 1;
         while Prop_Mate (P) = 0 loop
            K := Next_Offer (P);
            if K > N then
               --  Unreachable for complete equal-sized lists (everyone
               --  is matched before any proposer exhausts their list).
               raise Invalid_Argument;
            end if;
            R := Prop_List (Person_Id (P), Person_Id (K));
            Next_Offer (P) := K + 1;
            Q := Rec_Mate (R);
            if Q = 0 then
               Rec_Mate (R) := P;
               Prop_Mate (P) := R;
            elsif Rec_Rank (Person_Id (R), Person_Id (P))
              < Rec_Rank (Person_Id (R), Person_Id (Q))
            then
               Rec_Mate (R) := P;
               Prop_Mate (P) := R;
               Prop_Mate (Q) := 0;
               Top := Top + 1;
               Stack (Top) := Q;
            end if;
         end loop;
      end loop;
   end Deferred_Acceptance;

   procedure Fill_Matching
     (N         : Natural;
      Prop_Mate : Mate_Array;
      Rec_Mate  : Mate_Array;
      Result    : out Matching)
   is
   begin
      Result.N := N;
      Result.Proposer_Mate := [others => 0];
      Result.Receiver_Mate := [others => 0];
      for I in 1 .. N loop
         Result.Proposer_Mate (I) := Prop_Mate (I);
         Result.Receiver_Mate (I) := Rec_Mate (I);
      end loop;
   end Fill_Matching;

   ---------------------------------------------------------------------------
   -- Mutators / inspectors
   ---------------------------------------------------------------------------

   procedure Clear (Inst : in out Instance; Size : Natural) is
   begin
      if Size > Max_N then
         raise Invalid_Argument;
      end if;
      Inst.N := Size;
      Inst.P_List := [others => [others => 0]];
      Inst.R_List := [others => [others => 0]];
      for I in 1 .. Size loop
         for K in 1 .. Size loop
            Inst.P_List (Person_Id (I), Person_Id (K)) := K;
            Inst.R_List (Person_Id (I), Person_Id (K)) := K;
         end loop;
      end loop;
   end Clear;

   procedure Set_Proposer_Choice
     (Inst     : in out Instance;
      Proposer : Person_Id;
      Rank     : Person_Id;
      Receiver : Person_Id)
   is
   begin
      Raise_If_OOB3 (Inst.N, Proposer, Rank, Receiver);
      Inst.P_List (Proposer, Rank) := Natural (Receiver);
   end Set_Proposer_Choice;

   procedure Set_Receiver_Choice
     (Inst     : in out Instance;
      Receiver : Person_Id;
      Rank     : Person_Id;
      Proposer : Person_Id)
   is
   begin
      Raise_If_OOB3 (Inst.N, Receiver, Rank, Proposer);
      Inst.R_List (Receiver, Rank) := Natural (Proposer);
   end Set_Receiver_Choice;

   procedure Load_Proposer_Prefs
     (Inst : in out Instance; Prefs : Pref_Matrix)
   is
   begin
      Check_Load_Shape (Prefs, Inst.N);
      for I in 1 .. Inst.N loop
         Copy_Pref_Row (Prefs, I, Inst.N, Inst.P_List);
      end loop;
   end Load_Proposer_Prefs;

   procedure Load_Receiver_Prefs
     (Inst : in out Instance; Prefs : Pref_Matrix)
   is
   begin
      Check_Load_Shape (Prefs, Inst.N);
      for I in 1 .. Inst.N loop
         Copy_Pref_Row (Prefs, I, Inst.N, Inst.R_List);
      end loop;
   end Load_Receiver_Prefs;

   procedure Load
     (Inst           : in out Instance;
      Proposer_Prefs : Pref_Matrix;
      Receiver_Prefs : Pref_Matrix)
   is
      Order : constant Natural := Proposer_Prefs'Length (1);
   begin
      if Proposer_Prefs'First (1) /= 1
        or else Proposer_Prefs'First (2) /= 1
        or else Receiver_Prefs'First (1) /= 1
        or else Receiver_Prefs'First (2) /= 1
        or else Proposer_Prefs'Length (2) /= Order
        or else Receiver_Prefs'Length (1) /= Order
        or else Receiver_Prefs'Length (2) /= Order
        or else Order > Max_N
      then
         raise Invalid_Argument;
      end if;
      if not Is_Complete_Permutation (Proposer_Prefs, Order)
        or else not Is_Complete_Permutation (Receiver_Prefs, Order)
      then
         raise Invalid_Argument;
      end if;
      Clear (Inst, Order);
      for I in 1 .. Order loop
         Copy_Pref_Row (Proposer_Prefs, I, Order, Inst.P_List);
         Copy_Pref_Row (Receiver_Prefs, I, Order, Inst.R_List);
      end loop;
   end Load;

   function Size (Inst : Instance) return Natural is
   begin
      return Inst.N;
   end Size;

   function Proposer_Choice
     (Inst : Instance; Proposer, Rank : Person_Id) return Person_Id
   is
   begin
      return Choice_In_List (Inst.P_List, Proposer, Rank, Inst.N);
   end Proposer_Choice;

   function Receiver_Choice
     (Inst : Instance; Receiver, Rank : Person_Id) return Person_Id
   is
   begin
      return Choice_In_List (Inst.R_List, Receiver, Rank, Inst.N);
   end Receiver_Choice;

   function Proposer_Rank
     (Inst : Instance; Proposer, Receiver : Person_Id) return Person_Id
   is
   begin
      Raise_If_OOB (Inst.N, Proposer, Receiver);
      return Rank_In_List (Inst.P_List, Proposer, Receiver, Inst.N);
   end Proposer_Rank;

   function Receiver_Rank
     (Inst : Instance; Receiver, Proposer : Person_Id) return Person_Id
   is
   begin
      Raise_If_OOB (Inst.N, Receiver, Proposer);
      return Rank_In_List (Inst.R_List, Receiver, Proposer, Inst.N);
   end Receiver_Rank;

   function Prefers
     (Inst                         : Instance;
      Who                          : Side;
      Person, Candidate, Incumbent : Person_Id) return Boolean
   is
   begin
      Raise_If_OOB3 (Inst.N, Person, Candidate, Incumbent);
      if Who = Proposers then
         return Proposer_Rank (Inst, Person, Candidate)
           < Proposer_Rank (Inst, Person, Incumbent);
      end if;
      return Receiver_Rank (Inst, Person, Candidate)
        < Receiver_Rank (Inst, Person, Incumbent);
   end Prefers;

   function Is_Complete_Permutation
     (Prefs : Pref_Matrix; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean;
   begin
      if N = 0 then
         return True;
      end if;
      if N > Max_N then
         return False;
      end if;
      if Prefs'First (1) /= 1 or else Prefs'First (2) /= 1 then
         return False;
      end if;
      if Prefs'Length (1) < N or else Prefs'Length (2) < N then
         return False;
      end if;
      for I in 1 .. N loop
         Seen := [others => False];
         for K in 1 .. N loop
            declare
               V : constant Natural := Prefs (I, K);
            begin
               if V < 1 or else V > N or else Seen (V) then
                  return False;
               end if;
               Seen (V) := True;
            end;
         end loop;
      end loop;
      return True;
   end Is_Complete_Permutation;

   function Is_Permutation
     (A : Mate_Array; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      if N = 0 then
         return True;
      end if;
      if N > Max_N then
         return False;
      end if;
      if A'First /= 1 or else A'Length < N then
         return False;
      end if;
      for I in 1 .. N loop
         declare
            J : constant Natural := A (I);
         begin
            if J < 1 or else J > N or else Seen (J) then
               return False;
            end if;
            Seen (J) := True;
         end;
      end loop;
      return True;
   end Is_Permutation;

   ---------------------------------------------------------------------------
   -- Solve / Match
   ---------------------------------------------------------------------------

   procedure Solve
     (Inst : Instance; Result : out Matching; Who_Proposes : Side)
   is
      P_Rank, R_Rank : Pref_Store;
      Prop_Mate      : Mate_Array (1 .. Max_N) := [others => 0];
      Rec_Mate       : Mate_Array (1 .. Max_N) := [others => 0];
   begin
      Ensure_Valid (Inst);
      if Inst.N = 0 then
         Fill_Matching (0, Prop_Mate, Rec_Mate, Result);
         return;
      end if;
      Build_Ranks (Inst.P_List, Inst.N, P_Rank);
      Build_Ranks (Inst.R_List, Inst.N, R_Rank);
      if Who_Proposes = Proposers then
         Deferred_Acceptance
           (Inst.N, Inst.P_List, R_Rank, Prop_Mate, Rec_Mate);
      else
         --  Receivers propose: swap roles, then swap the mate arrays
         --  back into proposer/receiver coordinates.
         Deferred_Acceptance
           (Inst.N, Inst.R_List, P_Rank, Rec_Mate, Prop_Mate);
      end if;
      Fill_Matching (Inst.N, Prop_Mate, Rec_Mate, Result);
   end Solve;

   procedure Solve (Inst : Instance; Result : out Matching) is
   begin
      Solve (Inst, Result, Proposers);
   end Solve;

   function Match
     (Inst : Instance; Who_Proposes : Side := Proposers) return Matching
   is
      Result : Matching;
   begin
      Solve (Inst, Result, Who_Proposes);
      return Result;
   end Match;

   ---------------------------------------------------------------------------
   -- Stability and inspectors
   ---------------------------------------------------------------------------

   function Is_Bijection (Result : Matching) return Boolean is
   begin
      if Result.N > Max_N then
         return False;
      end if;
      if not Is_Permutation (Result.Proposer_Mate, Result.N) then
         return False;
      end if;
      for I in 1 .. Result.N loop
         declare
            R : constant Natural := Result.Proposer_Mate (I);
         begin
            if Result.Receiver_Mate (R) /= I then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Bijection;

   function Is_Stable
     (Inst : Instance; Result : Matching) return Boolean
   is
      P_Rank, R_Rank : Pref_Store;
   begin
      Ensure_Valid (Inst);
      if Result.N /= Inst.N then
         return False;
      end if;
      if not Is_Bijection (Result) then
         return False;
      end if;
      Build_Ranks (Inst.P_List, Inst.N, P_Rank);
      Build_Ranks (Inst.R_List, Inst.N, R_Rank);
      for P in 1 .. Inst.N loop
         declare
            R_Cur : constant Natural := Result.Proposer_Mate (P);
            Rp    : constant Natural :=
              P_Rank (Person_Id (P), Person_Id (R_Cur));
         begin
            for R in 1 .. Inst.N loop
               if R /= R_Cur
                 and then P_Rank (Person_Id (P), Person_Id (R)) < Rp
               then
                  declare
                     Q : constant Natural := Result.Receiver_Mate (R);
                  begin
                     if R_Rank (Person_Id (R), Person_Id (P))
                       < R_Rank (Person_Id (R), Person_Id (Q))
                     then
                        return False;
                     end if;
                  end;
               end if;
            end loop;
         end;
      end loop;
      return True;
   end Is_Stable;

   function Receiver_Of
     (Result : Matching; Proposer : Person_Id) return Person_Id
   is
      V : Natural;
   begin
      if Natural (Proposer) > Result.N then
         raise Invalid_Argument;
      end if;
      V := Result.Proposer_Mate (Natural (Proposer));
      if V < 1 or else V > Result.N then
         raise Invalid_Argument;
      end if;
      return Person_Id (V);
   end Receiver_Of;

   function Proposer_Of
     (Result : Matching; Receiver : Person_Id) return Person_Id
   is
      V : Natural;
   begin
      if Natural (Receiver) > Result.N then
         raise Invalid_Argument;
      end if;
      V := Result.Receiver_Mate (Natural (Receiver));
      if V < 1 or else V > Result.N then
         raise Invalid_Argument;
      end if;
      return Person_Id (V);
   end Proposer_Of;

end Gale_Shapley_Algorithm;

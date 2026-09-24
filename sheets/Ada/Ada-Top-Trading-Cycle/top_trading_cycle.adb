--  Top_Trading_Cycle body — TTC solve, pointing / cycles, core check.

pragma Ada_2022;

package body Top_Trading_Cycle
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   procedure Raise_If_Bad_Id (N : Natural; A : Agent_Id) is
   begin
      if N = 0 or else Natural (A) > N then
         raise Invalid_Argument;
      end if;
   end Raise_If_Bad_Id;

   procedure Raise_If_Bad_Ids (N : Natural; A, B : Agent_Id) is
   begin
      if N = 0
        or else Natural (A) > N
        or else Natural (B) > N
      then
         raise Invalid_Argument;
      end if;
   end Raise_If_Bad_Ids;

   procedure Raise_If_Bad_Ids3 (N : Natural; A, B, C : Agent_Id) is
   begin
      if N = 0
        or else Natural (A) > N
        or else Natural (B) > N
        or else Natural (C) > N
      then
         raise Invalid_Argument;
      end if;
   end Raise_If_Bad_Ids3;

   function Row_Is_Permutation
     (Store : Pref_Store; Row : Agent_Id; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      for K in 1 .. N loop
         declare
            V : constant Natural := Store (Row, Agent_Id (K));
         begin
            if V < 1 or else V > N or else Seen (V) then
               return False;
            end if;
            Seen (V) := True;
         end;
      end loop;
      return True;
   end Row_Is_Permutation;

   function Endow_Is_Permutation
     (Store : Own_Store; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      for K in 1 .. N loop
         declare
            V : constant Natural := Store (Agent_Id (K));
         begin
            if V < 1 or else V > N or else Seen (V) then
               return False;
            end if;
            Seen (V) := True;
         end;
      end loop;
      return True;
   end Endow_Is_Permutation;

   function Prefs_Are_Valid (Inst : Instance) return Boolean is
   begin
      for I in 1 .. Inst.N loop
         if not Row_Is_Permutation (Inst.Prefs, Agent_Id (I), Inst.N) then
            return False;
         end if;
      end loop;
      return True;
   end Prefs_Are_Valid;

   procedure Ensure_Valid (Inst : Instance) is
   begin
      if not Prefs_Are_Valid (Inst)
        or else not Endow_Is_Permutation (Inst.Endow, Inst.N)
      then
         raise Invalid_Argument;
      end if;
   end Ensure_Valid;

   function Rank_In_List
     (Store : Pref_Store; Agent, House : Agent_Id; N : Natural)
      return Agent_Id
   is
   begin
      for K in 1 .. N loop
         if Store (Agent, Agent_Id (K)) = Natural (House) then
            return Agent_Id (K);
         end if;
      end loop;
      raise Invalid_Argument;
   end Rank_In_List;

   procedure Copy_Pref_Row
     (Prefs : Pref_Matrix;
      Row   : Positive;
      N     : Natural;
      Dest  : in out Pref_Store;
      DRow  : Agent_Id)
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      for K in 1 .. N loop
         declare
            V : constant Natural := Prefs (Row, K);
         begin
            if V < 1 or else V > N or else Seen (V) then
               raise Invalid_Argument;
            end if;
            Seen (V) := True;
            Dest (DRow, Agent_Id (K)) := V;
         end;
      end loop;
      for K in N + 1 .. Max_N loop
         Dest (DRow, Agent_Id (K)) := 0;
      end loop;
   end Copy_Pref_Row;

   procedure Require_Point_Shape (Point : Pointing_Array; N : Natural) is
   begin
      if N > Max_N
        or else Point'First /= 1
        or else Point'Length < N
      then
         raise Invalid_Argument;
      end if;
   end Require_Point_Shape;

   procedure Require_Rem_Shape (Remaining : Id_Array; N : Natural) is
   begin
      if Remaining'First /= 1 or else Remaining'Length < N then
         raise Invalid_Argument;
      end if;
   end Require_Rem_Shape;

   ---------------------------------------------------------------------------
   -- Clear / setters / loaders
   ---------------------------------------------------------------------------

   procedure Clear (Inst : in out Instance; Size : Natural) is
   begin
      if Size > Max_N then
         raise Invalid_Argument;
      end if;
      Inst.N := Size;
      Inst.Prefs := [others => [others => 0]];
      Inst.Endow := [others => 0];
      for I in 1 .. Size loop
         Inst.Endow (Agent_Id (I)) := I;
         for K in 1 .. Size loop
            Inst.Prefs (Agent_Id (I), Agent_Id (K)) := K;
         end loop;
      end loop;
   end Clear;

   procedure Set_Preference
     (Inst  : in out Instance;
      Agent : Agent_Id;
      Rank  : Agent_Id;
      House : House_Id)
   is
   begin
      Raise_If_Bad_Ids3 (Inst.N, Agent, Rank, House);
      Inst.Prefs (Agent, Rank) := Natural (House);
   end Set_Preference;

   procedure Set_Endowment
     (Inst  : in out Instance;
      Agent : Agent_Id;
      House : House_Id)
   is
   begin
      Raise_If_Bad_Ids (Inst.N, Agent, House);
      Inst.Endow (Agent) := Natural (House);
   end Set_Endowment;

   procedure Load_Preferences
     (Inst : in out Instance; Prefs : Pref_Matrix)
   is
      N : constant Natural := Inst.N;
   begin
      if N = 0 then
         return;
      end if;
      if Prefs'First (1) /= 1
        or else Prefs'First (2) /= 1
        or else Prefs'Length (1) < N
        or else Prefs'Length (2) < N
      then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N loop
         Copy_Pref_Row (Prefs, I, N, Inst.Prefs, Agent_Id (I));
      end loop;
   end Load_Preferences;

   procedure Load_Endowment
     (Inst : in out Instance; Endow : Id_Array)
   is
      N : constant Natural := Inst.N;
   begin
      if N = 0 then
         return;
      end if;
      if Endow'First /= 1 or else Endow'Length < N then
         raise Invalid_Argument;
      end if;
      declare
         Seen : array (1 .. Max_N) of Boolean := [others => False];
      begin
         for I in 1 .. N loop
            declare
               V : constant Natural := Endow (I);
            begin
               if V < 1 or else V > N or else Seen (V) then
                  raise Invalid_Argument;
               end if;
               Seen (V) := True;
               Inst.Endow (Agent_Id (I)) := V;
            end;
         end loop;
      end;
      for I in N + 1 .. Max_N loop
         Inst.Endow (Agent_Id (I)) := 0;
      end loop;
   end Load_Endowment;

   procedure Load
     (Inst  : in out Instance;
      Prefs : Pref_Matrix;
      Endow : Id_Array)
   is
      N : Natural;
   begin
      if Prefs'First (1) /= 1
        or else Prefs'First (2) /= 1
        or else Prefs'Length (1) /= Prefs'Length (2)
      then
         raise Invalid_Argument;
      end if;
      N := Prefs'Length (1);
      if N > Max_N then
         raise Invalid_Argument;
      end if;
      Clear (Inst, N);
      Load_Preferences (Inst, Prefs);
      Load_Endowment (Inst, Endow);
   end Load;

   procedure Load_Identity_Endowment
     (Inst : in out Instance; Prefs : Pref_Matrix)
   is
      N : Natural;
   begin
      if Prefs'First (1) /= 1
        or else Prefs'First (2) /= 1
        or else Prefs'Length (1) /= Prefs'Length (2)
      then
         raise Invalid_Argument;
      end if;
      N := Prefs'Length (1);
      if N > Max_N then
         raise Invalid_Argument;
      end if;
      Clear (Inst, N);
      Load_Preferences (Inst, Prefs);
   end Load_Identity_Endowment;

   function Size (Inst : Instance) return Natural is (Inst.N);

   function Preference
     (Inst : Instance; Agent, Rank : Agent_Id) return House_Id
   is
      V : Natural;
   begin
      Raise_If_Bad_Ids (Inst.N, Agent, Rank);
      V := Inst.Prefs (Agent, Rank);
      if V < 1 or else V > Inst.N then
         raise Invalid_Argument;
      end if;
      return House_Id (V);
   end Preference;

   function Endowment
     (Inst : Instance; Agent : Agent_Id) return House_Id
   is
      V : Natural;
   begin
      Raise_If_Bad_Id (Inst.N, Agent);
      V := Inst.Endow (Agent);
      if V < 1 or else V > Inst.N then
         raise Invalid_Argument;
      end if;
      return House_Id (V);
   end Endowment;

   function Owner_Of_House
     (Inst : Instance; House : House_Id) return Agent_Id
   is
   begin
      Raise_If_Bad_Id (Inst.N, House);
      if not Endow_Is_Permutation (Inst.Endow, Inst.N) then
         raise Invalid_Argument;
      end if;
      for I in 1 .. Inst.N loop
         if Inst.Endow (Agent_Id (I)) = Natural (House) then
            return Agent_Id (I);
         end if;
      end loop;
      raise Invalid_Argument;
   end Owner_Of_House;

   function Rank_Of
     (Inst : Instance; Agent : Agent_Id; House : House_Id) return Agent_Id
   is
   begin
      Raise_If_Bad_Ids (Inst.N, Agent, House);
      return Rank_In_List (Inst.Prefs, Agent, House, Inst.N);
   end Rank_Of;

   function Prefers
     (Inst                    : Instance;
      Agent                   : Agent_Id;
      Candidate, Incumbent    : House_Id) return Boolean
   is
   begin
      Raise_If_Bad_Ids3 (Inst.N, Agent, Candidate, Incumbent);
      return Rank_In_List (Inst.Prefs, Agent, Candidate, Inst.N)
        < Rank_In_List (Inst.Prefs, Agent, Incumbent, Inst.N);
   end Prefers;

   function Is_Complete_Permutation
     (Prefs : Pref_Matrix; N : Natural) return Boolean
   is
   begin
      if N = 0 then
         return True;
      end if;
      if N > Max_N
        or else Prefs'First (1) /= 1
        or else Prefs'First (2) /= 1
        or else Prefs'Length (1) < N
        or else Prefs'Length (2) < N
      then
         return False;
      end if;
      for I in 1 .. N loop
         declare
            Seen : array (1 .. Max_N) of Boolean := [others => False];
         begin
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
         end;
      end loop;
      return True;
   end Is_Complete_Permutation;

   function Is_Permutation
     (A : Id_Array; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      if N = 0 then
         return True;
      end if;
      if N > Max_N or else A'First /= 1 or else A'Length < N then
         return False;
      end if;
      for I in 1 .. N loop
         declare
            V : constant Natural := A (I);
         begin
            if V < 1 or else V > N or else Seen (V) then
               return False;
            end if;
            Seen (V) := True;
         end;
      end loop;
      return True;
   end Is_Permutation;

   ---------------------------------------------------------------------------
   -- Pointing / cycles
   ---------------------------------------------------------------------------

   procedure Compute_Pointing_With_Holdings
     (Inst      : Instance;
      Remaining : Id_Array;
      Holding   : Id_Array;
      Point     : out Pointing_Array)
   is
      N : constant Natural := Inst.N;
      --  Owner_Now (House) = remaining agent currently holding House, else 0.
      Owner_Now : array (1 .. Max_N) of Natural := [others => 0];
   begin
      Ensure_Valid (Inst);
      Require_Rem_Shape (Remaining, N);
      if Holding'First /= 1 or else Holding'Length < N then
         raise Invalid_Argument;
      end if;
      if Point'First /= 1 or else Point'Length < N then
         raise Invalid_Argument;
      end if;

      for I in Point'Range loop
         Point (I) := 0;
      end loop;

      for I in 1 .. N loop
         if Remaining (I) /= 0 then
            declare
               H : constant Natural := Holding (I);
            begin
               if H < 1 or else H > N then
                  raise Invalid_Argument;
               end if;
               Owner_Now (H) := I;
            end;
         end if;
      end loop;

      for I in 1 .. N loop
         if Remaining (I) /= 0 then
            declare
               Found : Boolean := False;
            begin
               for R in 1 .. N loop
                  declare
                     H : constant Natural :=
                       Inst.Prefs (Agent_Id (I), Agent_Id (R));
                  begin
                     if H >= 1 and then H <= N and then Owner_Now (H) /= 0
                     then
                        Point (I) := Owner_Now (H);
                        Found := True;
                        exit;
                     end if;
                  end;
               end loop;
               if not Found then
                  raise Invalid_Argument;
               end if;
            end;
         end if;
      end loop;
   end Compute_Pointing_With_Holdings;

   procedure Compute_Pointing
     (Inst      : Instance;
      Remaining : Id_Array;
      Point     : out Pointing_Array)
   is
      N       : constant Natural := Inst.N;
      Holding : Id_Array (1 .. Max_N) := [others => 0];
   begin
      Ensure_Valid (Inst);
      for I in 1 .. N loop
         Holding (I) := Inst.Endow (Agent_Id (I));
      end loop;
      Compute_Pointing_With_Holdings (Inst, Remaining, Holding, Point);
   end Compute_Pointing;

   procedure Find_Cycle
     (Point  : Pointing_Array;
      N      : Natural;
      Start  : Agent_Id;
      Cycle  : out Cycle_Array;
      Length : out Natural)
   is
      --  Tortoise/hare style via path recording: walk until revisit.
      Seen_At : array (0 .. Max_N) of Natural := [others => 0];
      Path    : array (1 .. Max_N + 1) of Natural := [others => 0];
      Len     : Natural := 0;
      Cur     : Natural;
   begin
      Require_Point_Shape (Point, N);
      if Cycle'First /= 1 or else Cycle'Length < N then
         raise Invalid_Argument;
      end if;
      for I in Cycle'Range loop
         Cycle (I) := 0;
      end loop;
      Length := 0;

      if N = 0 or else Natural (Start) > N or else Point (Natural (Start)) = 0
      then
         return;
      end if;

      Cur := Natural (Start);
      while Cur /= 0 and then Cur <= N loop
         if Seen_At (Cur) /= 0 then
            --  Cycle starts at Path index Seen_At (Cur).
            declare
               C0 : constant Natural := Seen_At (Cur);
            begin
               Length := Len - C0 + 1;
               for K in 1 .. Length loop
                  Cycle (K) := Path (C0 + K - 1);
               end loop;
            end;
            return;
         end if;
         Len := Len + 1;
         Path (Len) := Cur;
         Seen_At (Cur) := Len;
         Cur := Point (Cur);
         if Len > N then
            --  Should be unreachable in a functional graph of size N.
            Length := 0;
            return;
         end if;
      end loop;
      Length := 0;
   end Find_Cycle;

   function Has_Cycle
     (Point : Pointing_Array; N : Natural) return Boolean
   is
      --  Color: 0 white, 1 gray, 2 black.
      Color : array (1 .. Max_N) of Natural := [others => 0];
   begin
      Require_Point_Shape (Point, N);
      if N = 0 then
         return False;
      end if;
      for S in 1 .. N loop
         if Point (S) /= 0 and then Color (S) = 0 then
            declare
               Cur : Natural := S;
            begin
               while Cur /= 0 and then Cur <= N and then Color (Cur) = 0 loop
                  Color (Cur) := 1;
                  Cur := Point (Cur);
               end loop;
               if Cur /= 0 and then Cur <= N and then Color (Cur) = 1 then
                  return True;
               end if;
               --  Paint the path black.
               Cur := S;
               while Cur /= 0 and then Cur <= N and then Color (Cur) = 1 loop
                  Color (Cur) := 2;
                  Cur := Point (Cur);
               end loop;
            end;
         end if;
      end loop;
      return False;
   end Has_Cycle;

   function Count_Cycles
     (Point : Pointing_Array; N : Natural) return Natural
   is
      Color : array (1 .. Max_N) of Natural := [others => 0];
      Count : Natural := 0;
   begin
      Require_Point_Shape (Point, N);
      for S in 1 .. N loop
         if Point (S) /= 0 and then Color (S) = 0 then
            declare
               Cur : Natural := S;
            begin
               while Cur /= 0 and then Cur <= N and then Color (Cur) = 0 loop
                  Color (Cur) := 1;
                  Cur := Point (Cur);
               end loop;
               if Cur /= 0 and then Cur <= N and then Color (Cur) = 1 then
                  Count := Count + 1;
                  --  Mark cycle nodes gray→visited specially then black path.
                  declare
                     Cyc : Natural := Cur;
                  begin
                     loop
                        Color (Cyc) := 2;
                        Cyc := Point (Cyc);
                        exit when Cyc = Cur;
                     end loop;
                  end;
               end if;
               Cur := S;
               while Cur /= 0 and then Cur <= N and then Color (Cur) = 1 loop
                  Color (Cur) := 2;
                  Cur := Point (Cur);
               end loop;
            end;
         end if;
      end loop;
      return Count;
   end Count_Cycles;

   ---------------------------------------------------------------------------
   -- Solve / Allocate
   ---------------------------------------------------------------------------

   procedure Solve (Inst : Instance; Result : out Allocation) is
      N : constant Natural := Inst.N;
      Remaining : Id_Array (1 .. Max_N) := [others => 0];
      Holding   : Id_Array (1 .. Max_N) := [others => 0];
      Point     : Pointing_Array (1 .. Max_N) := [others => 0];
      Left      : Natural;
   begin
      Result.N := N;
      Result.House_Of := [others => 0];
      Result.Agent_Of := [others => 0];

      if N = 0 then
         return;
      end if;

      Ensure_Valid (Inst);

      for I in 1 .. N loop
         Remaining (I) := 1;
         Holding (I) := Inst.Endow (Agent_Id (I));
      end loop;
      Left := N;

      while Left > 0 loop
         Compute_Pointing_With_Holdings (Inst, Remaining, Holding, Point);

         --  Mark every agent that lies on some cycle this round.
         declare
            On_Cycle : array (1 .. Max_N) of Boolean := [others => False];
            Found_Any : Boolean := False;
         begin
            for S in 1 .. N loop
               if Remaining (S) /= 0 and then not On_Cycle (S) then
                  declare
                     Cyc : Cycle_Array (1 .. Max_N) := [others => 0];
                     Len : Natural := 0;
                  begin
                     Find_Cycle (Point, N, Agent_Id (S), Cyc, Len);
                     if Len > 0 then
                        Found_Any := True;
                        for K in 1 .. Len loop
                           On_Cycle (Cyc (K)) := True;
                        end loop;
                     end if;
                  end;
               end if;
            end loop;

            if not Found_Any then
               --  Functional graph on remaining agents must have a cycle.
               raise Invalid_Argument;
            end if;

            --  Assign: agent i on a cycle gets Holding (Point (i)).
            for I in 1 .. N loop
               if On_Cycle (I) then
                  declare
                     H : constant Natural := Holding (Point (I));
                  begin
                     Result.House_Of (I) := H;
                     Result.Agent_Of (H) := I;
                  end;
               end if;
            end loop;

            --  Remove cycled agents from the residual market.
            for I in 1 .. N loop
               if On_Cycle (I) then
                  Remaining (I) := 0;
                  Left := Left - 1;
               end if;
            end loop;
         end;
      end loop;
   end Solve;

   function Allocate (Inst : Instance) return Allocation is
      R : Allocation;
   begin
      Solve (Inst, R);
      return R;
   end Allocate;

   ---------------------------------------------------------------------------
   -- Structural / core checks
   ---------------------------------------------------------------------------

   function Is_Bijection (Result : Allocation) return Boolean is
      N : constant Natural := Result.N;
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      if N = 0 then
         return True;
      end if;
      if N > Max_N then
         return False;
      end if;
      for I in 1 .. N loop
         declare
            H : constant Natural := Result.House_Of (I);
         begin
            if H < 1 or else H > N or else Seen (H) then
               return False;
            end if;
            Seen (H) := True;
            if Result.Agent_Of (H) /= I then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Bijection;

   function Is_Individually_Rational
     (Inst : Instance; Result : Allocation) return Boolean
   is
      N : constant Natural := Inst.N;
   begin
      Ensure_Valid (Inst);
      if Result.N /= N or else not Is_Bijection (Result) then
         return False;
      end if;
      for I in 1 .. N loop
         declare
            A : constant Agent_Id := Agent_Id (I);
            Assigned : constant House_Id :=
              House_Id (Result.House_Of (I));
            Own      : constant House_Id :=
              House_Id (Inst.Endow (A));
         begin
            if Rank_In_List (Inst.Prefs, A, Assigned, N)
              > Rank_In_List (Inst.Prefs, A, Own, N)
            then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Individually_Rational;

   --  Weak-core blocking search: for coalition mask, houses owned by
   --  S under endowment; try to assign each member a distinct S-house
   --  strictly preferred to Result.
   function Coalition_Blocks
     (Inst   : Instance;
      Result : Allocation;
      Mask   : Natural) return Boolean
   is
      N : constant Natural := Inst.N;
      Members : array (1 .. Max_N) of Agent_Id := [others => 1];
      Houses  : array (1 .. Max_N) of House_Id := [others => 1];
      M       : Natural := 0;
      Used_H  : array (1 .. Max_N) of Boolean := [others => False];

      function Search (Idx : Natural) return Boolean is
      begin
         if Idx > M then
            return True;
         end if;
         declare
            Ag : constant Agent_Id := Members (Idx);
            Cur_H : constant House_Id :=
              House_Id (Result.House_Of (Natural (Ag)));
         begin
            for J in 1 .. M loop
               if not Used_H (J) then
                  declare
                     Cand : constant House_Id := Houses (J);
                  begin
                     if Rank_In_List (Inst.Prefs, Ag, Cand, N)
                       < Rank_In_List (Inst.Prefs, Ag, Cur_H, N)
                     then
                        Used_H (J) := True;
                        if Search (Idx + 1) then
                           return True;
                        end if;
                        Used_H (J) := False;
                     end if;
                  end;
               end if;
            end loop;
         end;
         return False;
      end Search;
   begin
      for I in 1 .. N loop
         if ((Mask / (2 ** (I - 1))) rem 2) = 1 then
            M := M + 1;
            Members (M) := Agent_Id (I);
            Houses (M) := House_Id (Inst.Endow (Agent_Id (I)));
         end if;
      end loop;
      if M = 0 then
         return False;
      end if;
      return Search (1);
   end Coalition_Blocks;

   function Is_In_Core
     (Inst : Instance; Result : Allocation) return Boolean
   is
      N : constant Natural := Inst.N;
   begin
      Ensure_Valid (Inst);
      if N > Max_Core_Check_N then
         raise Invalid_Argument;
      end if;
      if Result.N /= N or else not Is_Bijection (Result) then
         return False;
      end if;
      if not Is_Individually_Rational (Inst, Result) then
         return False;
      end if;
      if N = 0 then
         return True;
      end if;
      for Mask in 1 .. (2 ** N) - 1 loop
         if Coalition_Blocks (Inst, Result, Mask) then
            return False;
         end if;
      end loop;
      return True;
   end Is_In_Core;

   function House_Of
     (Result : Allocation; Agent : Agent_Id) return House_Id
   is
      V : Natural;
   begin
      Raise_If_Bad_Id (Result.N, Agent);
      V := Result.House_Of (Natural (Agent));
      if V < 1 or else V > Result.N then
         raise Invalid_Argument;
      end if;
      return House_Id (V);
   end House_Of;

   function Agent_Of
     (Result : Allocation; House : House_Id) return Agent_Id
   is
      V : Natural;
   begin
      Raise_If_Bad_Id (Result.N, House);
      V := Result.Agent_Of (Natural (House));
      if V < 1 or else V > Result.N then
         raise Invalid_Argument;
      end if;
      return Agent_Id (V);
   end Agent_Of;

end Top_Trading_Cycle;

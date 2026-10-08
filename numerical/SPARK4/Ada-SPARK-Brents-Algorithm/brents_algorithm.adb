--  Brents_Algorithm body — SPARK Level 4 powers-of-two / teleport search,
--  μ recovery, naive reference, graph builders.
--  All loops are bounded `for` loops so termination is immediate.

package body Brents_Algorithm
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Map (Next : Successor_Map) return Boolean is
   begin
      if Next'Length = 0
        or else Next'First /= 1
        or else Next'Last > Max_N
      then
         return False;
      end if;
      for I in Next'Range loop
         pragma Loop_Invariant
           (for all K in Next'First .. I - 1 => Next (K) <= Next'Last);
         if Next (I) > Next'Last then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Map;

   ---------------------------------------------------------------------------
   -- Stepping (internal + public)
   ---------------------------------------------------------------------------

   function Fwd
     (Next : Successor_Map;
      X    : Node_Index) return Node_Index
   with
     Global => null,
     Pre    => Is_Valid_Map (Next)
               and then (X = Null_Index or else X <= Next'Last),
     Post   => Fwd'Result <= Next'Last
               and then (if X = Null_Index then Fwd'Result = Null_Index);

   function Fwd
     (Next : Successor_Map;
      X    : Node_Index) return Node_Index
   is
   begin
      if X = Null_Index then
         return Null_Index;
      end if;
      return Next (X);
   end Fwd;

   function Step
     (Next : Successor_Map;
      X    : Node_Index) return Node_Index
   is
   begin
      return Fwd (Next, X);
   end Step;

   function Iterate
     (Next  : Successor_Map;
      Start : Node_Id;
      Steps : Natural) return Node_Index
   is
      X : Node_Index := Start;
   begin
      for S in 1 .. Steps loop
         pragma Loop_Invariant (X <= Next'Last);
         exit when X = Null_Index;
         X := Next (X);
      end loop;
      return X;
   end Iterate;

   ---------------------------------------------------------------------------
   -- Phase 1: powers-of-two / teleport — recover λ
   ---------------------------------------------------------------------------

   procedure Phase_Lambda
     (Next    : Successor_Map;
      Start   : Node_Id;
      Meet    : out Node_Index;
      Lam_Val : out Natural)
   with
     Global => null,
     Pre    => Is_Valid_Map (Next) and then Start <= Next'Last,
     Post   => Meet <= Next'Last
               and then
                 (if Meet = Null_Index then Lam_Val = 0
                  else Lam_Val in 1 .. Next'Last);
   --  Meet = live meeting node and Lam_Val = λ, or Meet = 0 / Lam = 0.

   procedure Phase_Lambda
     (Next    : Successor_Map;
      Start   : Node_Id;
      Meet    : out Node_Index;
      Lam_Val : out Natural)
   is
      Tortoise : Node_Index := Start;
      Hare     : Node_Index := Fwd (Next, Start);
      Power    : Natural := 1;
      Lam      : Natural := 1;
      --  Brent uses O(μ+λ) steps; 4N+8 is a safe classroom bound.
      Limit    : constant Positive := 4 * Next'Length + 8;
   begin
      if Hare = Null_Index then
         Meet    := Null_Index;
         Lam_Val := 0;
         return;
      end if;

      for Guard in 1 .. Limit loop
         pragma Loop_Invariant (Tortoise in 1 .. Next'Last);
         pragma Loop_Invariant (Hare in 1 .. Next'Last);
         pragma Loop_Invariant (Power >= 1);
         pragma Loop_Invariant (Lam >= 1 or else Lam = 0);
         pragma Loop_Invariant (Lam <= Limit);
         pragma Loop_Invariant (Power <= Limit * 2);
         exit when Tortoise = Hare;

         if Power = Lam then
            Tortoise := Hare;
            if Power <= Limit then
               Power := Power * 2;
            end if;
            Lam := 0;
         end if;

         Hare := Fwd (Next, Hare);
         if Hare = Null_Index then
            Meet    := Null_Index;
            Lam_Val := 0;
            return;
         end if;

         if Lam < Limit then
            Lam := Lam + 1;
         else
            Meet    := Null_Index;
            Lam_Val := 0;
            return;
         end if;
      end loop;

      if Tortoise /= Hare
        or else Tortoise = Null_Index
        or else Lam = 0
        or else Lam > Next'Last
      then
         Meet    := Null_Index;
         Lam_Val := 0;
         return;
      end if;

      Meet    := Hare;
      Lam_Val := Lam;
   end Phase_Lambda;

   ---------------------------------------------------------------------------
   -- Detect / Find_Cycle
   ---------------------------------------------------------------------------

   function Detect
     (Next  : Successor_Map;
      Start : Node_Id) return Cycle_Result
   is
      Meet    : Node_Index;
      Lam_Val : Natural;
   begin
      Phase_Lambda (Next, Start, Meet, Lam_Val);
      if Meet = Null_Index then
         return No_Cycle;
      end if;
      return
        (Has_Cycle     => True,
         Meeting_Point => Meet,
         Start_Node    => Null_Index,
         Mu            => 0,
         Lambda        => Lam_Val);
   end Detect;

   function Find_Cycle
     (Next  : Successor_Map;
      Start : Node_Id) return Cycle_Result
   is
      Meet     : Node_Index;
      Lam_Val  : Natural;
      Tortoise : Node_Index;
      Hare     : Node_Index;
      Mu_Val   : Natural := 0;
   begin
      Phase_Lambda (Next, Start, Meet, Lam_Val);
      if Meet = Null_Index then
         return No_Cycle;
      end if;

      --  Phase 2: μ. Advance hare λ steps from x0, then walk both.
      Tortoise := Start;
      Hare     := Start;
      for I in 1 .. Lam_Val loop
         pragma Loop_Invariant (Tortoise in 1 .. Next'Last);
         pragma Loop_Invariant (Hare in 1 .. Next'Last);
         pragma Loop_Invariant (Lam_Val in 1 .. Next'Last);
         Hare := Next (Hare);
         if Hare = Null_Index then
            return No_Cycle;
         end if;
      end loop;

      for Guard in 1 .. Next'Length loop
         pragma Loop_Invariant (Tortoise in 1 .. Next'Last);
         pragma Loop_Invariant (Hare in 1 .. Next'Last);
         pragma Loop_Invariant (Mu_Val = Guard - 1);
         pragma Loop_Invariant (Mu_Val <= Next'Last);
         exit when Tortoise = Hare;
         Tortoise := Next (Tortoise);
         Hare     := Next (Hare);
         if Tortoise = Null_Index or else Hare = Null_Index then
            return No_Cycle;
         end if;
         Mu_Val := Mu_Val + 1;
      end loop;

      if Tortoise /= Hare or else Tortoise = Null_Index then
         return No_Cycle;
      end if;

      return
        (Has_Cycle     => True,
         Meeting_Point => Meet,
         Start_Node    => Tortoise,
         Mu            => Mu_Val,
         Lambda        => Lam_Val);
   end Find_Cycle;

   function Has_Cycle
     (Next  : Successor_Map;
      Start : Node_Id) return Boolean
   is
   begin
      return Detect (Next, Start).Has_Cycle;
   end Has_Cycle;

   function Cycle_Length
     (Next  : Successor_Map;
      Start : Node_Id) return Natural
   is
   begin
      return Find_Cycle (Next, Start).Lambda;
   end Cycle_Length;

   function Cycle_Start
     (Next  : Successor_Map;
      Start : Node_Id) return Node_Index
   is
   begin
      return Find_Cycle (Next, Start).Start_Node;
   end Cycle_Start;

   function Tail_Length
     (Next  : Successor_Map;
      Start : Node_Id) return Natural
   is
   begin
      return Find_Cycle (Next, Start).Mu;
   end Tail_Length;

   function Is_On_Cycle
     (Next       : Successor_Map;
      Node       : Node_Index;
      Start_Node : Node_Index;
      Lambda     : Natural) return Boolean
   is
      X : Node_Index;
   begin
      if Lambda = 0
        or else Node = Null_Index
        or else Start_Node = Null_Index
      then
         return False;
      end if;

      X := Start_Node;
      for Left in 1 .. Lambda loop
         pragma Loop_Invariant (X in 1 .. Next'Last);
         if X = Node then
            return True;
         end if;
         X := Next (X);
         if X = Null_Index then
            return False;
         end if;
      end loop;
      return False;
   end Is_On_Cycle;

   ---------------------------------------------------------------------------
   -- Naive reference (fixed bound; no heap)
   ---------------------------------------------------------------------------

   function Find_Cycle_Naive
     (Next  : Successor_Map;
      Start : Node_Id) return Cycle_Result
   is
      type Seen_Array is array (Node_Id) of Integer;
      First_Seen : Seen_Array := [others => -1];
      X          : Node_Index := Start;
      Step_I     : Natural := 0;
   begin
      for Guard in 1 .. Next'Length + 1 loop
         pragma Loop_Invariant (X <= Next'Last);
         pragma Loop_Invariant (Step_I = Guard - 1);
         pragma Loop_Invariant (Step_I <= Next'Length);
         pragma Loop_Invariant
           (for all K in Node_Id =>
              First_Seen (K) = -1
              or else
                (First_Seen (K) >= 0
                 and then First_Seen (K) < Integer (Step_I)));
         exit when X = Null_Index;

         if First_Seen (X) >= 0 then
            declare
               Prev : constant Natural := Natural (First_Seen (X));
               Lam  : constant Natural := Step_I - Prev;
            begin
               return
                 (Has_Cycle     => True,
                  Meeting_Point => X,
                  Start_Node    => X,
                  Mu            => Prev,
                  Lambda        => Lam);
            end;
         end if;

         First_Seen (X) := Integer (Step_I);
         X := Next (X);
         Step_I := Step_I + 1;
      end loop;
      return No_Cycle;
   end Find_Cycle_Naive;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Pure_Cycle (N : Node_Count) return Successor_Map is
      Next : Successor_Map (1 .. N) := [others => Null_Index];
   begin
      for I in 1 .. N - 1 loop
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => Next (K) = K + 1);
         pragma Loop_Invariant
           (for all K in I .. N => Next (K) = Null_Index);
         Next (I) := I + 1;
      end loop;
      Next (N) := 1;
      return Next;
   end Pure_Cycle;

   function Rho_Graph
     (Tail  : Natural;
      Cycle : Node_Count) return Successor_Map
   is
      N   : constant Node_Count := Tail + Cycle;
      Map : Successor_Map (1 .. N) := [others => Null_Index];
   begin
      for I in 1 .. N - 1 loop
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => Map (K) = K + 1);
         Map (I) := I + 1;
      end loop;
      Map (N) := Tail + 1;
      return Map;
   end Rho_Graph;

   function Path_To_Sink (N : Node_Count) return Successor_Map is
      Next : Successor_Map (1 .. N) := [others => Null_Index];
   begin
      for I in 1 .. N - 1 loop
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => Next (K) = K + 1);
         Next (I) := I + 1;
      end loop;
      Next (N) := Null_Index;
      return Next;
   end Path_To_Sink;

   function Self_Loop_Chain (N : Node_Count) return Successor_Map is
      Next : Successor_Map (1 .. N) := [others => Null_Index];
   begin
      for I in 1 .. N - 1 loop
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => Next (K) = K + 1);
         Next (I) := I + 1;
      end loop;
      Next (N) := N;
      return Next;
   end Self_Loop_Chain;

   function Two_Cycles return Successor_Map is
   begin
      --  1 → 2 → 3 → 1;  4 → 5 → 4;  6 → 0
      return [1 => 2, 2 => 3, 3 => 1, 4 => 5, 5 => 4, 6 => 0];
   end Two_Cycles;

   function Wikipedia_Example return Successor_Map is
   begin
      --  Ada I = wiki (I − 1). Known article edges:
      --    wiki 0→6, 1→6, 2→0, 3→1, 4→4, 6→3
      --  Classroom fill: wiki 5→3, 7→4, 8→0.
      return
        [1 => 7,   -- wiki 0 → 6
         2 => 7,   -- wiki 1 → 6
         3 => 1,   -- wiki 2 → 0
         4 => 2,   -- wiki 3 → 1
         5 => 5,   -- wiki 4 → 4
         6 => 4,   -- wiki 5 → 3
         7 => 4,   -- wiki 6 → 3
         8 => 5,   -- wiki 7 → 4
         9 => 1];  -- wiki 8 → 0
   end Wikipedia_Example;

end Brents_Algorithm;

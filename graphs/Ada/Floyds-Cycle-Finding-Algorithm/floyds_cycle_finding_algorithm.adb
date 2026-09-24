--  Floyds_Cycle_Finding_Algorithm body — tortoise / hare, μ / λ
--  recovery, naive reference, graph builders.

pragma Ada_2022;

package body Floyds_Cycle_Finding_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   function Is_Valid_Map (Next : Successor_Map) return Boolean is
   begin
      if Next'Length = 0
        or else Next'First /= 1
        or else Next'Last > Max_Nodes
      then
         return False;
      end if;
      for I in Next'Range loop
         if Next (I) > Next'Last then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Map;

   procedure Require_Map (Next : Successor_Map) is
   begin
      if not Is_Valid_Map (Next) then
         raise Invalid_Argument;
      end if;
   end Require_Map;

   procedure Require_Start
     (Next  : Successor_Map;
      Start : Positive)
   is
   begin
      Require_Map (Next);
      if Start > Next'Last then
         raise Invalid_Argument;
      end if;
   end Require_Start;

   ---------------------------------------------------------------------------
   -- Stepping
   ---------------------------------------------------------------------------

   function Step
     (Next : Successor_Map;
      X    : Node_Index) return Node_Index
   is
   begin
      if X = Null_Index then
         Require_Map (Next);
         return Null_Index;
      end if;
      Require_Map (Next);
      if X > Next'Last then
         raise Invalid_Argument;
      end if;
      return Node_Index (Next (X));
   end Step;

   function Iterate
     (Next  : Successor_Map;
      Start : Positive;
      Steps : Natural) return Node_Index
   is
      X         : Node_Index;
      Remaining : Natural;
   begin
      Require_Start (Next, Start);
      X := Node_Index (Start);
      Remaining := Steps;
      while Remaining > 0 and then X /= Null_Index loop
         X := Node_Index (Next (X));
         Remaining := Remaining - 1;
      end loop;
      return X;
   end Iterate;

   ---------------------------------------------------------------------------
   -- Internal Floyd (array map)
   ---------------------------------------------------------------------------

   --  Phase 1. Meeting_Point is the live node where tortoise = hare,
   --  or Null_Index when the walk hits the sentinel (no cycle).
   function Fwd
     (Next : Successor_Map;
      X    : Node_Index) return Node_Index
   is
   begin
      if X = Null_Index then
         return Null_Index;
      end if;
      return Node_Index (Next (X));
   end Fwd;

   function Phase_Meet
     (Next  : Successor_Map;
      Start : Positive) return Node_Index
   is
      Tortoise, Hare : Node_Index;
      Guard          : Natural := 0;
      Limit          : constant Natural := 2 * Next'Length + 4;
   begin
      Tortoise := Fwd (Next, Node_Index (Start));
      Hare     := Fwd (Next, Fwd (Next, Node_Index (Start)));

      while Tortoise /= Null_Index
        and then Hare /= Null_Index
        and then Tortoise /= Hare
      loop
         Tortoise := Fwd (Next, Tortoise);
         Hare     := Fwd (Next, Fwd (Next, Hare));
         Guard := Guard + 1;
         if Guard > Limit then
            raise Invalid_Argument;
         end if;
      end loop;

      if Tortoise = Null_Index
        or else Hare = Null_Index
        or else Tortoise /= Hare
      then
         return Null_Index;
      end if;
      return Tortoise;
   end Phase_Meet;

   function Detect
     (Next  : Successor_Map;
      Start : Positive) return Cycle_Result
   is
      Meet : Node_Index;
   begin
      Require_Start (Next, Start);
      Meet := Phase_Meet (Next, Start);
      if Meet = Null_Index then
         return No_Cycle;
      end if;
      return
        (Has_Cycle     => True,
         Meeting_Point => Meet,
         Start_Node    => Null_Index,
         Mu            => 0,
         Lambda        => 0);
   end Detect;

   function Find_Cycle
     (Next  : Successor_Map;
      Start : Positive) return Cycle_Result
   is
      Meet, Tortoise, Hare : Node_Index;
      Mu_Val, Lam_Val      : Natural;
      Guard                : Natural := 0;
      Limit                : constant Natural := 2 * Next'Length + 4;
   begin
      Require_Start (Next, Start);
      Meet := Phase_Meet (Next, Start);
      if Meet = Null_Index then
         return No_Cycle;
      end if;

      --  Phase 2: μ. Tortoise from x0, hare from the meeting point,
      --  both one step at a time. They meet at x_μ.
      Tortoise := Node_Index (Start);
      Hare     := Meet;
      Mu_Val   := 0;
      while Tortoise /= Hare loop
         Tortoise := Node_Index (Next (Tortoise));
         Hare     := Node_Index (Next (Hare));
         Mu_Val   := Mu_Val + 1;
         Guard    := Guard + 1;
         if Guard > Limit then
            raise Invalid_Argument;
         end if;
      end loop;

      --  Phase 3: λ. Freeze tortoise at x_μ; walk hare.
      Lam_Val := 1;
      Hare    := Node_Index (Next (Tortoise));
      while Tortoise /= Hare loop
         Hare  := Node_Index (Next (Hare));
         Lam_Val := Lam_Val + 1;
         if Lam_Val > Next'Length then
            raise Invalid_Argument;
         end if;
      end loop;

      return
        (Has_Cycle     => True,
         Meeting_Point => Meet,
         Start_Node    => Tortoise,
         Mu            => Mu_Val,
         Lambda        => Lam_Val);
   end Find_Cycle;

   function Has_Cycle
     (Next  : Successor_Map;
      Start : Positive) return Boolean
   is
      R : constant Cycle_Result := Detect (Next, Start);
   begin
      return R.Has_Cycle;
   end Has_Cycle;

   function Cycle_Length
     (Next  : Successor_Map;
      Start : Positive) return Natural
   is
      R : constant Cycle_Result := Find_Cycle (Next, Start);
   begin
      return R.Lambda;
   end Cycle_Length;

   function Cycle_Start
     (Next  : Successor_Map;
      Start : Positive) return Node_Index
   is
      R : constant Cycle_Result := Find_Cycle (Next, Start);
   begin
      return R.Start_Node;
   end Cycle_Start;

   function Tail_Length
     (Next  : Successor_Map;
      Start : Positive) return Natural
   is
      R : constant Cycle_Result := Find_Cycle (Next, Start);
   begin
      return R.Mu;
   end Tail_Length;

   function Is_On_Cycle
     (Next       : Successor_Map;
      Node       : Node_Index;
      Start_Node : Node_Index;
      Lambda     : Natural) return Boolean
   is
      X : Node_Index;
   begin
      Require_Map (Next);
      if Lambda = 0
        or else Node = Null_Index
        or else Start_Node = Null_Index
        or else Start_Node > Next'Last
        or else Node > Next'Last
      then
         return False;
      end if;
      X := Start_Node;
      declare
         Left : Natural := Lambda;
      begin
         while Left > 0 loop
            if X = Node then
               return True;
            end if;
            X := Node_Index (Next (X));
            if X = Null_Index then
               return False;
            end if;
            Left := Left - 1;
         end loop;
      end;
      return False;
   end Is_On_Cycle;

   ---------------------------------------------------------------------------
   -- Naive reference
   ---------------------------------------------------------------------------

   function Find_Cycle_Naive
     (Next  : Successor_Map;
      Start : Positive) return Cycle_Result
   is
      First_Seen : array (0 .. Next'Last) of Integer := [others => -1];
      X          : Node_Index;
      Step_I     : Natural := 0;
   begin
      Require_Start (Next, Start);
      X := Node_Index (Start);
      while X /= Null_Index loop
         if First_Seen (X) >= 0 then
            return
              (Has_Cycle     => True,
               Meeting_Point => X,
               Start_Node    => X,
               Mu            => Natural (First_Seen (X)),
               Lambda        => Step_I - Natural (First_Seen (X)));
         end if;
         First_Seen (X) := Integer (Step_I);
         X := Node_Index (Next (X));
         Step_I := Step_I + 1;
         if Step_I > Next'Length then
            raise Invalid_Argument;
         end if;
      end loop;
      return No_Cycle;
   end Find_Cycle_Naive;

   ---------------------------------------------------------------------------
   -- Generic callback Floyd
   ---------------------------------------------------------------------------

   function Find_Cycle_On_Function
     (Start     : Node_Index;
      Max_Steps : Positive := Max_Nodes) return Cycle_Result
   is
      Tortoise, Hare, Meet : Node_Index;
      Mu_Val, Lam_Val      : Natural;
      Guard                : Natural := 0;
   begin
      if Start = Null_Index then
         return No_Cycle;
      end if;

      Tortoise := F (Start);
      Hare     := F (F (Start));
      while Tortoise /= Null_Index
        and then Hare /= Null_Index
        and then Tortoise /= Hare
      loop
         Tortoise := F (Tortoise);
         Hare     := F (F (Hare));
         Guard    := Guard + 1;
         if Guard > Max_Steps then
            raise Invalid_Argument;
         end if;
      end loop;

      if Tortoise = Null_Index
        or else Hare = Null_Index
        or else Tortoise /= Hare
      then
         return No_Cycle;
      end if;
      Meet := Tortoise;

      Tortoise := Start;
      Hare     := Meet;
      Mu_Val   := 0;
      Guard    := 0;
      while Tortoise /= Hare loop
         Tortoise := F (Tortoise);
         Hare     := F (Hare);
         Mu_Val   := Mu_Val + 1;
         Guard    := Guard + 1;
         if Guard > Max_Steps then
            raise Invalid_Argument;
         end if;
      end loop;

      Lam_Val := 1;
      Hare    := F (Tortoise);
      while Tortoise /= Hare loop
         Hare    := F (Hare);
         Lam_Val := Lam_Val + 1;
         if Lam_Val > Max_Steps then
            raise Invalid_Argument;
         end if;
      end loop;

      return
        (Has_Cycle     => True,
         Meeting_Point => Meet,
         Start_Node    => Tortoise,
         Mu            => Mu_Val,
         Lambda        => Lam_Val);
   end Find_Cycle_On_Function;

   function Detect_On_Function
     (Start     : Node_Index;
      Max_Steps : Positive := Max_Nodes) return Cycle_Result
   is
      Tortoise, Hare : Node_Index;
      Guard          : Natural := 0;
   begin
      if Start = Null_Index then
         return No_Cycle;
      end if;

      Tortoise := F (Start);
      Hare     := F (F (Start));
      while Tortoise /= Null_Index
        and then Hare /= Null_Index
        and then Tortoise /= Hare
      loop
         Tortoise := F (Tortoise);
         Hare     := F (F (Hare));
         Guard    := Guard + 1;
         if Guard > Max_Steps then
            raise Invalid_Argument;
         end if;
      end loop;

      if Tortoise = Null_Index
        or else Hare = Null_Index
        or else Tortoise /= Hare
      then
         return No_Cycle;
      end if;
      return
        (Has_Cycle     => True,
         Meeting_Point => Tortoise,
         Start_Node    => Null_Index,
         Mu            => 0,
         Lambda        => 0);
   end Detect_On_Function;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Pure_Cycle (N : Positive) return Successor_Map is
      Next : Successor_Map (1 .. N);
   begin
      if N > Max_Nodes then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N - 1 loop
         Next (I) := I + 1;
      end loop;
      Next (N) := 1;
      return Next;
   end Pure_Cycle;

   function Rho_Graph
     (Tail  : Natural;
      Cycle : Positive) return Successor_Map
   is
      N : Natural;
   begin
      if Tail > Max_Nodes or else Cycle > Max_Nodes
        or else Tail > Max_Nodes - Cycle
      then
         raise Invalid_Argument;
      end if;
      N := Tail + Cycle;
      declare
         Map : Successor_Map (1 .. N);
      begin
         for I in 1 .. N - 1 loop
            Map (I) := I + 1;
         end loop;
         Map (N) := Tail + 1;
         return Map;
      end;
   end Rho_Graph;

   function Path_To_Sink (N : Positive) return Successor_Map is
      Next : Successor_Map (1 .. N);
   begin
      if N > Max_Nodes then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N - 1 loop
         Next (I) := I + 1;
      end loop;
      Next (N) := 0;
      return Next;
   end Path_To_Sink;

   function Self_Loop_Chain (N : Positive) return Successor_Map is
      Next : Successor_Map (1 .. N);
   begin
      if N > Max_Nodes then
         raise Invalid_Argument;
      end if;
      for I in 1 .. N - 1 loop
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
      --    (start 2, 0, 6, 3, 1, 6, …; cycles {1,6,3} and {4}).
      --  Classroom fill of 5, 7, 8 so those two cycles remain:
      --    wiki 5→3, 7→4, 8→0.
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

end Floyds_Cycle_Finding_Algorithm;

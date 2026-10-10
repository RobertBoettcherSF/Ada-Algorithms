--  Own property tests for Patience_Sort.Sort (written for this repository; see
--  tests/SOURCES.txt). No expected value is taken from the program: every
--  check is a property of a correct sort (output nondecreasing, output a
--  permutation of the input) or a comparison with the own insertion sort
--  below.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Patience_Sort; use Patience_Sort;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   --  Own reference: straight insertion sort.
   function Reference (A : Input_Array) return Input_Array is
      B : Input_Array := A;
      T : Value;
      J : Index;
   begin
      for I in Index'First + 1 .. Index'Last loop
         T := B (I);
         J := I;
         while J > Index'First and then B (J - 1) > T loop
            B (J) := B (J - 1);
            J := J - 1;
         end loop;
         B (J) := T;
      end loop;
      return B;
   end Reference;

   --  Own model of patience sort (deal / pick the smallest pile top;
   --  Aldous and Diaconis, Bull. AMS 36 (1999), section 1): each key in input order goes onto the leftmost
   --  pile whose top is >= the key, or onto a new pile on the right; then
   --  the output is built by repeatedly removing the smallest pile top
   --  (the leftmost pile on ties). Real piles (stacks of values), written
   --  from that description, not from the body. Records the pile of every
   --  key, the pile of every removal and the number of piles.
   --  Deal search (cost): the pile tops are increasing from left to right,
   --  so the leftmost pile whose top is >= the key is found by binary
   --  search over the candidates 1 .. Np + 1 (Np + 1 = new pile): while
   --  Lo < Hi, Mid := (Lo + Hi) / 2, one comparison Top (Mid) >= Key, then
   --  Hi := Mid or Lo := Mid + 1. The model counts these comparisons
   --  (Probes) and records the pile count before each deal (Before); the
   --  binary search result must also equal a plain left-to-right scan.
   type Count_Log is array (Index) of Natural;
   type Model is record
      Deal   : Pile_Log := [others => 1];
      Take   : Pile_Log := [others => 1];
      Probes : Count_Log := [others => 0];
      Before : Count_Log := [others => 0];
      Piles  : Natural := 0;
      Result : Input_Array;
      Scan_Ok : Boolean := True;
   end record;

   function Run_Model (Input : Input_Array) return Model is
      R      : Model;
      type Stack is array (Index) of Value;
      Pile   : array (Index) of Stack := [others => [others => 0]];
      Height : array (Index) of Natural := [others => 0];
      Np     : Natural := 0;
      Found  : Natural;
      Lo, Hi, Mid, Scan : Positive;
   begin
      for K in Index loop
         R.Before (K) := Np;
         Lo := 1;
         Hi := Np + 1;
         while Lo < Hi loop
            Mid := (Lo + Hi) / 2;
            R.Probes (K) := R.Probes (K) + 1;
            if Pile (Mid) (Height (Mid)) >= Input (K) then
               Hi := Mid;
            else
               Lo := Mid + 1;
            end if;
         end loop;
         Scan := Np + 1;
         for P in reverse 1 .. Np loop
            if Pile (P) (Height (P)) >= Input (K) then
               Scan := P;
            end if;
         end loop;
         if Scan /= Lo then
            R.Scan_Ok := False;
         end if;
         Found := Lo;
         if Found = Np + 1 then
            Np := Np + 1;
         end if;
         Height (Found) := Height (Found) + 1;
         Pile (Found) (Height (Found)) := Input (K);
         R.Deal (K) := Found;
      end loop;
      R.Piles := Np;
      for M in Index loop
         Found := 0;
         for P in 1 .. Np loop
            if Height (P) > 0
              and then (Found = 0 or else Pile (P) (Height (P)) < Pile (Found) (Height (Found)))
            then
               Found := P;
            end if;
         end loop;
         R.Result (M) := Pile (Found) (Height (Found));
         Height (Found) := Height (Found) - 1;
         R.Take (M) := Found;
      end loop;
      return R;
   end Run_Model;

   --  Smallest C with 2**C >= X (X >= 1): ceil (log2 (X)).
   function Ceil_Log2 (X : Positive) return Natural is
      C : Natural := 0;
   begin
      while 2 ** C < X loop
         C := C + 1;
      end loop;
      return C;
   end Ceil_Log2;

   Cost_Failures : Natural := 0;
   Max_Piles_Seen : Natural := 0;
   Trace_Failures : Natural := 0;
   procedure Check_Trace (A : Input_Array) is
      Out_A : Input_Array;
      Deal  : Pile_Log;
      Take  : Pile_Log;
      Probe : Probe_Log;
      Np    : Natural;
      M     : constant Model := Run_Model (A);
      Cost_Ok : Boolean := M.Scan_Ok;
   begin
      Sort_Traced (A, Out_A, Deal, Take, Probe, Np);
      Max_Piles_Seen := Natural'Max (Max_Piles_Seen, Np);
      --  Cost: comparisons of the deal search for key K are at most
      --  ceil (log2 (piles before K + 1)) and equal the binary-search model.
      for K in Index loop
         if Probe (K) > Ceil_Log2 (M.Before (K) + 1) or else Probe (K) /= M.Probes (K) then
            Cost_Ok := False;
         end if;
      end loop;
      if not Cost_Ok then
         Cost_Failures := Cost_Failures + 1;
         if Cost_Failures <= 5 then
            Put ("  FAIL patience deal cost: input");
            for X of A loop
               Put (X'Image);
            end loop;
            Put (" comparisons");
            for C of Probe loop
               Put (C'Image);
            end loop;
            Put (" bound");
            for K in Index loop
               Put (Ceil_Log2 (M.Before (K) + 1)'Image);
            end loop;
            New_Line;
         end if;
      end if;
      if Deal /= M.Deal or else Take /= M.Take or else Np /= M.Piles
        or else Out_A /= M.Result or else Out_A /= Sort (A)
        or else not Is_Perm (Out_A, A) or else not Is_Sorted (Out_A)
      then
         Trace_Failures := Trace_Failures + 1;
         if Trace_Failures <= 5 then
            Put ("  FAIL patience trace: input");
            for X of A loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_Trace;

   procedure Check_One (A : Input_Array; Label : String) is
      R      : constant Input_Array := Sort (A);
      type Counts is array (Value) of Natural;
      C_In   : Counts := [others => 0];
      C_Out  : Counts := [others => 0];
      Ok     : Boolean := True;
   begin
      Cases := Cases + 1;
      Check_Trace (A);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
         if I < Index'Last and then R (I) > R (I + 1) then
            Ok := False;
         end if;
      end loop;
      if C_In /= C_Out or else R /= Reference (A) then
         Ok := False;
      end if;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("  FAIL own check (" & Label & "): input");
            for X of A loop
               Put (X'Image);
            end loop;
            New_Line;
         end if;
      end if;
   end Check_One;

   A : Input_Array;
begin
   --  1. Every 0/1 input (2**8): for comparator networks this alone proves
   --     the network sorts all inputs (0-1 principle, Knuth TAOCP 5.3.4).
   for Mask in 0 .. 2 ** Index'Last - 1 loop
      for I in Index loop
         A (I) := (if (Mask / 2 ** (I - 1)) mod 2 = 1 then 1 else 0);
      end loop;
      Check_One (A, "0/1 mask" & Mask'Image);
   end loop;
   --  2. Edge shapes: all equal, ascending, descending, extremes.
   Check_One ([others => Value'First], "all First");
   Check_One ([others => Value'Last], "all Last");
   Check_One ([for I in Index => Value'First + (I - 1)], "ascending");
   Check_One ([for I in Index => Value'Last - (I - 1)], "descending");
   Check_One ([for I in Index => (if I mod 2 = 0 then Value'First else Value'Last)], "alternating extremes");
   --  3. Random inputs over the whole Value range, and with many duplicates.
   for K in 1 .. 2_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   for K in 1 .. 1_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'First + 2);
      end loop;
      Check_One (A, "duplicates" & K'Image);
   end loop;

   --  4. Random inputs, seed 20261009 (patience trace and result).
   Seed := 20_261_009;
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random 20261009" & K'Image);
   end loop;
   --  Every input over 0 .. 2 (3**8 = 6,561): ties on pile tops.
   for C in 0 .. 3 ** 8 - 1 loop
      for I in Index loop
         A (I) := (C / 3 ** (I - 1)) mod 3;
      end loop;
      Check_One (A, "ternary" & C'Image);
   end loop;
   --  Every permutation of 1 .. 8 (8! = 40,320): every pile shape.
   declare
      P : Input_Array := [for I in Index => I];
      procedure Perms (K : Index) is
         T : Value;
      begin
         if K = Index'Last then
            Check_One (P, "permutation");
            return;
         end if;
         for J in K .. Index'Last loop
            T := P (K); P (K) := P (J); P (J) := T;
            Perms (K + 1);
            T := P (K); P (K) := P (J); P (J) := T;
         end loop;
      end Perms;
   begin
      Perms (1);
   end;
   --  Many piles: every strictly ascending input builds 8 piles (key K
   --  sees K - 1 piles; the linear scan needs K - 1 comparisons, the bound
   --  is ceil (log2 (K))). All ascending runs over the Value range.
   for Start in Value'First .. Value'Last - (Index'Last - 1) loop
      for Step in 1 .. (Value'Last - Start) / (Index'Last - 1) loop
         Check_One ([for I in Index => Start + Step * (I - 1)], "ascending" & Start'Image & Step'Image);
      end loop;
   end loop;
   if Max_Piles_Seen /= Index'Last then
      Put_Line ("FAIL patience deal cost: no input built" & Index'Last'Image & " piles");
      raise Program_Error with "patience cost inputs too small";
   end if;
   if Cost_Failures > 0 then
      Put_Line ("FAIL patience deal cost:" & Cost_Failures'Image & " of" & Cases'Image);
      raise Program_Error with "patience deal cost failed";
   end if;
   Put_Line ("PASS patience deal cost <= ceil (log2 (piles + 1)) comparisons per key = binary-search model on" & Cases'Image & " inputs");

   if Trace_Failures > 0 then
      Put_Line ("FAIL patience trace:" & Trace_Failures'Image & " of" & Cases'Image);
      raise Program_Error with "patience trace failed";
   end if;
   Put_Line ("PASS patience trace = own pile model on" & Cases'Image & " inputs");

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (sorted, permutation, own reference)");
end Own_Checks;

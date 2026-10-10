--  Own property tests for Smooth_Sort.Sort (written for this repository; see
--  tests/SOURCES.txt). No expected value is taken from the program: every
--  check is a property of a correct sort (output nondecreasing, output a
--  permutation of the input) or a comparison with the own insertion sort
--  below.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Smooth_Sort; use Smooth_Sort;

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

   --  Own model of smoothsort (E. W. Dijkstra, "Smoothsort, an
   --  alternative for sorting in situ", EWD796a, 1981; the variant that
   --  restores the root order after every insertion): the prefix is a
   --  forest of Leonardo heaps ("stretches", sizes 1, 1, 3, 5, 9, ...)
   --  with roots ascending left to right. Insertion: if the last two
   --  stretches have orders k + 1 and k, they and the new key become one
   --  stretch of order k + 2, else the new key is a stretch of order 1
   --  (order 0 when the last stretch has order 1); then trinkle. Trinkle
   --  at stretch J: while J > 1 and the previous root is larger than the
   --  root of J and than both its child roots, exchange the two roots and
   --  go to J - 1; then sift J. Sift: exchange the root with its larger
   --  child root (the left one on ties) while that child is larger.
   --  Teardown: the last root is the prefix maximum and stays; a
   --  stretch of order >= 2 leaves its two children as stretches, each
   --  trinkled (left, then right). Stretches are kept as a list of orders
   --  (roots recomputed from the sizes), written from the description, not
   --  from the body. Records every exchange (X, Y) in order.
   Leo : constant array (0 .. 4) of Positive := [1, 1, 3, 5, 9];

   type Model is record
      Log    : Swap_Log := [others => (1, 1)];
      Count  : Natural := 0;
      Result : Input_Array;
   end record;

   function Run_Model (Input : Input_Array) return Model is
      R    : Model;
      A    : Input_Array := Input;
      Ords : array (1 .. 16) of Natural := [others => 0];
      M    : Natural := 0;

      procedure Exchange (X, Y : Index) is
         T : constant Value := A (X);
      begin
         A (X) := A (Y);
         A (Y) := T;
         R.Count := R.Count + 1;
         R.Log (R.Count) := (X, Y);
      end Exchange;

      function Root (J : Natural) return Natural is
         S : Natural := 0;
      begin
         for I in 1 .. J loop
            S := S + Leo (Ords (I));
         end loop;
         return S;
      end Root;

      procedure Sift (Rt : Index; K : Natural) is
         Right : Index;
         Left  : Index;
      begin
         if K < 2 then
            return;
         end if;
         Right := Rt - 1;
         Left  := Rt - 1 - Leo (K - 2);
         if A (Left) >= A (Right) then
            if A (Left) > A (Rt) then
               Exchange (Rt, Left);
               Sift (Left, K - 1);
            end if;
         elsif A (Right) > A (Rt) then
            Exchange (Rt, Right);
            Sift (Right, K - 2);
         end if;
      end Sift;

      procedure Trinkle (Start : Natural) is
         J : Natural := Start;
         P, Q : Index;
      begin
         while J > 1 loop
            P := Root (J - 1);
            Q := Root (J);
            exit when A (P) <= A (Q);
            exit when Ords (J) >= 2
              and then (A (P) <= A (Q - 1) or else A (P) <= A (Q - 1 - Leo (Ords (J) - 2)));
            Exchange (P, Q);
            J := J - 1;
         end loop;
         Sift (Root (J), Ords (J));
      end Trinkle;
   begin
      for N in Index loop
         if M >= 2 and then Ords (M - 1) = Ords (M) + 1 then
            M := M - 1;
            Ords (M) := Ords (M) + 1;
         elsif M >= 1 and then Ords (M) = 1 then
            M := M + 1;
            Ords (M) := 0;
         else
            M := M + 1;
            Ords (M) := 1;
         end if;
         Trinkle (M);
      end loop;
      for N in reverse 2 .. Index'Last loop
         if Ords (M) <= 1 then
            M := M - 1;
         else
            declare
               K : constant Natural := Ords (M);
            begin
               Ords (M) := K - 1;
               Ords (M + 1) := K - 2;
               M := M + 1;
               Trinkle (M - 1);
               Trinkle (M);
            end;
         end if;
      end loop;
      R.Result := A;
      return R;
   end Run_Model;

   Trace_Failures : Natural := 0;
   procedure Check_Trace (A : Input_Array) is
      Out_A : Input_Array;
      Log   : Swap_Log;
      Count : Natural;
      M     : constant Model := Run_Model (A);
   begin
      Sort_Traced (A, Out_A, Log, Count);
      if Count /= M.Count or else Log (1 .. Count) /= M.Log (1 .. M.Count)
        or else Out_A /= M.Result or else Out_A /= Sort (A)
        or else not Is_Perm (Out_A, A) or else not Is_Sorted (Out_A)
      then
         Trace_Failures := Trace_Failures + 1;
         if Trace_Failures <= 5 then
            Put ("  FAIL smoothsort trace: input");
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

   --  4. Random inputs, seed 20261009 (smoothsort trace and result).
   Seed := 20_261_009;
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random 20261009" & K'Image);
   end loop;
   --  Every input over 0 .. 2 (3**8 = 6,561): ties in sift / trinkle.
   for C in 0 .. 3 ** 8 - 1 loop
      for I in Index loop
         A (I) := (C / 3 ** (I - 1)) mod 3;
      end loop;
      Check_One (A, "ternary" & C'Image);
   end loop;
   --  Every permutation of 1 .. 8 (8! = 40,320).
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
   if Trace_Failures > 0 then
      Put_Line ("FAIL smoothsort trace:" & Trace_Failures'Image & " of" & Cases'Image);
      raise Program_Error with "smoothsort trace failed";
   end if;
   Put_Line ("PASS smoothsort trace = own Leonardo-forest model on" & Cases'Image & " inputs");

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (sorted, permutation, own reference)");
end Own_Checks;

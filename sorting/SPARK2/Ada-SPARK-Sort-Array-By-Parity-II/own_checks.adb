--  Own tests for Sort_Array_By_Parity_II (see tests/SOURCES.txt).
--  For inputs with 4 even and 4 odd values: Output is a permutation of Input with
--  odd values at odd positions and even values at even positions.
pragma Ada_2022;
--  the rejection checks rely on the input subtype's predicate; check it even in builds
--  without -gnata (the check is made here, at the call)
pragma Assertion_Policy (Dynamic_Predicate => Check);
with Ada.Environment_Variables;
with Ada.Text_IO;
with Ada.Assertions;
with Sort_Array_By_Parity_II; use Sort_Array_By_Parity_II;

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
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;


   procedure Check_One (A : Int_Array; Label : String) is
      type Counts is array (Value) of Natural;
      R : Int_Array;
      C_In, C_Out : Counts := [others => 0];
      Ok : Boolean := True;
   begin
      Sort_By_Parity (A, R);
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
         Ok := Ok and then R (I) mod 2 = I mod 2;
      end loop;
      Report (Ok and then C_In = C_Out, Label);
   end Check_One;
   --  an input without exactly four even values cannot be placed; it must be rejected (by the input
   --  type's predicate), not turned into an output with lost values
   procedure Check_Rejected (A : Int_Array; Label : String) is
      R : Int_Array;
   begin
      Sort_By_Parity (A, R);
      Report (False, Label & " (accepted)");
   exception
      when Ada.Assertions.Assertion_Error =>
         Report (True, Label);
   end Check_Rejected;
   A : Int_Array;
   T : Value;
   J : Index;
   Evens : Natural;
begin
   Check_Rejected ([1, 3, 5, 7, 9, 1, 3, 2], "7 odd + 1 even");
   Check_Rejected ([others => 0], "8 even");
   Check_Rejected ([others => 1], "8 odd");
   for K in 1 .. 2_000 loop
      loop
         Evens := 0;
         for I in Index loop
            A (I) := Next (0, 9);
            if A (I) mod 2 = 0 then Evens := Evens + 1; end if;
         end loop;
         exit when Evens /= 4;
      end loop;
      Check_Rejected (A, "unbalanced random" & K'Image);
   end loop;
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := (if I <= 4 then 2 * Next (0, 4) else 2 * Next (0, 4) + 1);
      end loop;
      for I in reverse 2 .. Index'Last loop
         J := Next (1, I);
         T := A (I); A (I) := A (J); A (J) := T;
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (parity positions, permutation)");
end Own_Checks;

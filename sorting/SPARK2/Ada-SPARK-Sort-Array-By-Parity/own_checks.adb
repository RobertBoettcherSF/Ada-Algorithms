--  Own property tests for Sort_Array_By_Parity.By_Parity (see tests/SOURCES.txt).
--  Expected behaviour (README): a permutation of the input with every even
--  value before every odd value.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Sort_Array_By_Parity; use Sort_Array_By_Parity;

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

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   procedure Check_One (A : Int_Array; Label : String) is
      type Counts is array (Value) of Natural;
      R        : constant Int_Array := By_Parity (A);
      C_In     : Counts := [others => 0];
      C_Out    : Counts := [others => 0];
      Seen_Odd : Boolean := False;
      Ok       : Boolean := True;
   begin
      for I in Index loop
         C_In (A (I)) := C_In (A (I)) + 1;
         C_Out (R (I)) := C_Out (R (I)) + 1;
         if R (I) mod 2 /= 0 then
            Seen_Odd := True;
         elsif Seen_Odd then
            Ok := False;
         end if;
      end loop;
      Report (Ok and then C_In = C_Out, Label);
   end Check_One;

   A : Int_Array;
begin
   Check_One ([others => 1], "all odd");
   Check_One ([others => -2], "all even");
   Check_One ([for I in Index => (if I mod 2 = 0 then 1 else 2)], "alternating");
   Check_One ([for I in Index => Value'First + 2 * (I - 1)], "extremes");
   for K in 1 .. 3_000 loop
      for I in Index loop
         A (I) := Next (Value'First, Value'Last);
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (evens first, permutation)");
end Own_Checks;

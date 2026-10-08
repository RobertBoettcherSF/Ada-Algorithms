--  Own tests for Merge_K_Sorted_Lists_Stub (see tests/SOURCES.txt).
--  Three sorted runs of four in one array; Merge_K must return them merged.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Merge_K_Sorted_Lists_Stub; use Merge_K_Sorted_Lists_Stub;

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

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;

   procedure Check_One (A : Input_Array; Label : String) is
      E : IArr (1 .. Index'Last);
      R : constant Input_Array := Merge_K (A);
      Ok : Boolean := True;
   begin
      for I in Index loop
         E (I) := A (I);
      end loop;
      Ins_Sort (E);
      for I in Index loop
         Ok := Ok and then R (I) = E (I);
      end loop;
      Report (Ok, Label);
   end Check_One;
   A : Input_Array;
   E : IArr (1 .. 4);
begin
   for K in 1 .. 3_000 loop
      for Run in 0 .. 2 loop
         for I in E'Range loop
            E (I) := Next (Value'First, (if K mod 2 = 0 then 3 else Value'Last));
         end loop;
         Ins_Sort (E);
         for I in E'Range loop
            A (4 * Run + I) := E (I);
         end loop;
      end loop;
      Check_One (A, "random" & K'Image);
   end loop;
   Check_One ([for I in Index => Value'Last - I], "descending");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own insertion-sort reference)");
end Own_Checks;

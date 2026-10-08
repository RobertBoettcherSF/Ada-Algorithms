--  Own tests for Median_Sorted_Arrays_Lite (see tests/SOURCES.txt).
--  Median of the NA + NB values: the middle value for an odd count; for an even
--  count a value between the two middle values (exactly their mean when it is an integer).
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Median_Sorted_Arrays_Lite; use Median_Sorted_Arrays_Lite;

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

   procedure Check_One (NA, NB : Length; Lo, Hi : Value; Label : String) is
      A, B : Values := [others => 0];
      XA : IArr (1 .. NA);
      XB : IArr (1 .. NB);
      E  : IArr (1 .. NA + NB);
      T  : constant Positive := NA + NB;
      M  : Integer;
      Ok : Boolean;
   begin
      for I in XA'Range loop
         XA (I) := Next (Lo, Hi);
      end loop;
      for I in XB'Range loop
         XB (I) := Next (Lo, Hi);
      end loop;
      Ins_Sort (XA);
      Ins_Sort (XB);
      for I in XA'Range loop
         A (I) := XA (I);
      end loop;
      for I in XB'Range loop
         B (I) := XB (I);
      end loop;
      E := XA & XB;
      Ins_Sort (E);
      M := Median (A, NA, B, NB);
      if T mod 2 = 1 then
         Ok := M = E ((T + 1) / 2);
      elsif (E (T / 2) + E (T / 2 + 1)) mod 2 = 0 then
         Ok := M = (E (T / 2) + E (T / 2 + 1)) / 2;
      else
         Ok := M in E (T / 2) .. E (T / 2 + 1);
      end if;
      Report (Ok, Label);
   end Check_One;
begin
   for NA in Length loop
      for NB in Length loop
         if NA + NB > 0 then
            for K in 1 .. 4 loop
               Check_One (NA, NB, Value'First, Value'Last, "random" & NA'Image & NB'Image);
               Check_One (NA, NB, -2, 2, "ties" & NA'Image & NB'Image);
            end loop;
         end if;
      end loop;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own sorted-merge median reference)");
end Own_Checks;

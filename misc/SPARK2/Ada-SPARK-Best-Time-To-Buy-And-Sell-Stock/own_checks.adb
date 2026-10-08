--  Own tests for Best_Time_To_Buy_And_Sell_Stock (see tests/SOURCES.txt).
--  Max_Profit must be the best single buy-then-sell gain (0 if none), by all pairs.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Best_Time_To_Buy_And_Sell_Stock; use Best_Time_To_Buy_And_Sell_Stock;

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

   X : Input_Array;
   function Ref return Natural is
      Best : Natural := 0;
   begin
      for I in Index loop
         for J in I + 1 .. Length loop
            Best := Natural'Max (Best, X (J) - X (I));
         end loop;
      end loop;
      return Best;
   end Ref;
begin
   for Code in 0 .. 3 ** Length - 1 loop
      declare
         C : Natural := Code;
      begin
         for I in Index loop
            X (I) := C mod 3;
            C := C / 3;
         end loop;
      end;
      Report (Max_Profit (X) = Ref, "small");
   end loop;
   for Iter in 1 .. 5_000 loop
      for I in Index loop
         X (I) := Next (0, 100);
      end loop;
      Report (Max_Profit (X) = Ref, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-pairs reference)");
end Own_Checks;

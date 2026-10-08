--  Own tests for Minimum_Limit_Of_Balls_In_A_Bag (see tests/SOURCES.txt).
--  Least L >= 1 such that splitting every bag into parts of at most L balls needs
--  at most Allowed split operations.
pragma Ada_2022;
with Ada.Text_IO;
with Minimum_Limit_Of_Balls_In_A_Bag; use Minimum_Limit_Of_Balls_In_A_Bag;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
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


   function Needed (B : Bag_Array; L : Positive) return Natural is
      S : Natural := 0;
   begin
      for I in Index loop
         S := S + (B (I) + L - 1) / L - 1;     --  parts = ceiling (B / L); splits = parts - 1
      end loop;
      return S;
   end Needed;
   B : Bag_Array;
   A : Operations;
   E : Positive;
begin
   for K in 1 .. 2_000 loop
      for I in Index loop
         B (I) := Next (1, (if K mod 2 = 0 then 1_000 else 20));
      end loop;
      A := Next (0, (if K mod 3 = 0 then 8_000 else 40));
      E := 1;
      while Needed (B, E) > A loop
         E := E + 1;
      end loop;
      Report (Minimum_Limit (B, A) = E, "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own linear-scan reference)");
end Own_Checks;

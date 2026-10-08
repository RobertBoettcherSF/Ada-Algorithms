--  Own tests for House_Robber_II.Maximum (written for this repository; see
--  tests/SOURCES.txt). Assumption: Maximum is wrong or does nothing. The
--  reference enumerates all 64 subsets of the six houses and keeps the best
--  one with no two neighbours on the circle (house 6 is next to house 1), a
--  different method from the two linear recurrences in the code.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with House_Robber_II; use House_Robber_II;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   function Reference (A : Values) return Natural is
      Best : Natural := 0;
   begin
      for Mask in 0 .. 2 ** House_Count - 1 loop
         declare
            Taken : array (House) of Boolean;
            Ok    : Boolean := True;
            Sum   : Natural := 0;
         begin
            for H in House loop
               Taken (H) := (Mask / 2 ** (H - 1)) mod 2 = 1;
            end loop;
            for H in House loop
               if Taken (H) and then Taken (if H = House'Last then House'First else H + 1) then
                  Ok := False;
               end if;
               if Taken (H) then
                  Sum := Sum + A (H);
               end if;
            end loop;
            if Ok then
               Best := Natural'Max (Best, Sum);
            end if;
         end;
      end loop;
      return Best;
   end Reference;

   procedure Check (A : Values) is
      Got  : constant Natural := Maximum (A);
      Want : constant Natural := Reference (A);
   begin
      Cases := Cases + 1;
      if Got /= Want then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put ("FAIL House_Robber_II:");
            for V of A loop
               Put (V'Image);
            end loop;
            Put_Line (" got" & Got'Image & " want" & Want'Image);
         end if;
      end if;
   end Check;

   Top : constant array (1 .. 3) of Money := [0, 19, 20];
   A : Values;
begin
   --  1. Every array over {0, 1, 2, 3}: 4**6 = 4,096 inputs, all shapes.
   for Code in 0 .. 4 ** House_Count - 1 loop
      for H in House loop
         A (H) := (Code / 4 ** (H - 1)) mod 4;
      end loop;
      Check (A);
   end loop;
   --  2. Every array over {0, 19, 20} (the top of Money): 729 inputs.
   for Code in 0 .. 3 ** House_Count - 1 loop
      for H in House loop
         A (H) := Top ((Code / 3 ** (H - 1)) mod 3 + 1);
      end loop;
      Check (A);
   end loop;
   --  3. One rich house at each position, the rest poor (the circle matters).
   for Rich in House loop
      A := [others => 1];
      A (Rich) := Money'Last;
      Check (A);
   end loop;
   --  4. Random arrays over the whole Money range.
   for K in 1 .. 5_000 loop
      for H in House loop
         A (H) := Next (Money'First, Money'Last);
      end loop;
      Check (A);
   end loop;

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " inputs (own circular subset enumeration)");
end Own_Checks;

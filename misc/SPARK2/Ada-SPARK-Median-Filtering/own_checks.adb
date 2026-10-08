--  Own tests for Median_Filtering.Filter_3x3 (written for this repository;
--  see tests/SOURCES.txt). Assumption: the filter is wrong or does nothing.
--  Reference, different from the code (clamped indices + bubble sort): the
--  window is collected by testing every pixel of the image for being within
--  one row and one column of the target, each pixel weighted by how many
--  window positions replicate it at the border; the median is the smallest
--  value v with at least five window samples <= v (a counting definition,
--  no sorting).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Median_Filtering; use Median_Filtering;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;
   --  Fixed default seed, printed at start; AA_SEED overrides it.
   subtype Seed_Range is Long_Long_Integer range 1 .. 2_147_483_646;
   Default_Seed : constant Seed_Range := 20_261_008;
   function Initial_Seed return Seed_Range is
     (if Ada.Environment_Variables.Exists ("AA_SEED")
      then Seed_Range'Value (Ada.Environment_Variables.Value ("AA_SEED"))
      else Default_Seed);
   Seed : Long_Long_Integer := Initial_Seed;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   --  How many of the three offsets -1, 0, 1 around P land on Q after
   --  replicating the border (an offset past the edge lands on the edge).
   function Hits (P, Q, Last : Integer) return Natural is
      N : Natural := 0;
   begin
      for D in -1 .. 1 loop
         if Integer'Max (1, Integer'Min (Last, P + D)) = Q then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Hits;

   function Reference (Input : Image; R : Row_Index; C : Col_Index) return Pixel is
   begin
      for V in Pixel loop
         declare
            At_Most : Natural := 0;
         begin
            for I in Row_Index loop
               for J in Col_Index loop
                  if Input (I, J) <= V then
                     At_Most := At_Most + Hits (R, I, Max_Rows) * Hits (C, J, Max_Cols);
                  end if;
               end loop;
            end loop;
            if At_Most >= 5 then
               return V;
            end if;
         end;
      end loop;
      return Pixel'Last;
   end Reference;

   procedure Check (Input : Image; What : String) is
      Got : constant Image := Filter_3x3 (Input);
   begin
      Cases := Cases + 1;
      for R in Row_Index loop
         for C in Col_Index loop
            if Got (R, C) /= Reference (Input, R, C) then
               Failures := Failures + 1;
               if Failures <= 5 then
                  Put_Line ("FAIL Median_Filtering " & What & " at" & R'Image & C'Image
                            & " got" & Got (R, C)'Image & " want" & Reference (Input, R, C)'Image);
               end if;
            end if;
         end loop;
      end loop;
   end Check;

   A : Image;
begin
   Put_Line ("own checks seed:" & Seed'Image & " (default"
             & Default_Seed'Image & "; set AA_SEED to override)");
   --  Distinct values (a permutation of 0 .. 63 scaled): every window has a unique median.
   A := [for R in Row_Index => [for C in Col_Index => ((R - 1) * Max_Cols + (C - 1)) * 4]];
   Check (A, "ramp");
   A := [for R in Row_Index => [for C in Col_Index => 255 - ((R - 1) * Max_Cols + (C - 1)) * 4]];
   Check (A, "reverse ramp");
   for K in 1 .. 300 loop
      for R in Row_Index loop
         for C in Col_Index loop
            A (R, C) := Next (Pixel'First, Pixel'Last);
         end loop;
      end loop;
      Check (A, "random" & K'Image);
   end loop;
   --  Few distinct values: many ties, and border replication decides the answer.
   for K in 1 .. 300 loop
      for R in Row_Index loop
         for C in Col_Index loop
            A (R, C) := Next (0, 2) * 100;
         end loop;
      end loop;
      Check (A, "three-valued" & K'Image);
   end loop;
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " pixels");
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image & " images (counting median, border weights)");
end Own_Checks;

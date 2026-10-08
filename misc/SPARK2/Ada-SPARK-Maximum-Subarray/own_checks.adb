--  Own tests for Maximum_Subarray (see tests/SOURCES.txt).
--  Best_Sum (A, N) must be the largest sum of a contiguous run of A (1 .. N). Whether
--  the empty run counts (all-negative input gives 0) is fixed by a one-element
--  negative input and then applied everywhere; N = 0 is not checked.
pragma Ada_2022;
with Ada.Text_IO;
with Maximum_Subarray; use Maximum_Subarray;

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

   A : Values;
   Empty_Ok : Boolean;
   function Ref (N : Positive) return Integer is
      Best : Integer := (if Empty_Ok then 0 else Integer'First);
      S : Integer;
   begin
      for I in 1 .. N loop
         S := 0;
         for J in I .. N loop
            S := S + A (J);
            Best := Integer'Max (Best, S);
         end loop;
      end loop;
      return Best;
   end Ref;
begin
   A := [others => 0];
   A (1) := -5;
   Empty_Ok := Best_Sum (A, 1) = 0;
   Report (Best_Sum (A, 1) in -5 | 0, "one negative element gives -5 or 0");
   --  every array over -3 .. 3 of length 1 .. 4
   for N in 1 .. 4 loop
      for Code in 0 .. 7 ** N - 1 loop
         declare
            C : Natural := Code;
         begin
            A := [others => 0];
            for I in 1 .. N loop
               A (I) := C mod 7 - 3;
               C := C / 7;
            end loop;
         end;
         Report (Best_Sum (A, N) = Ref (N), "small");
      end loop;
   end loop;
   for Iter in 1 .. 5_000 loop
      declare
         N : constant Positive := Next (1, 4);
      begin
         for I in 1 .. 4 loop
            A (I) := Next (-100, 100);
         end loop;
         Report (Best_Sum (A, N) = Ref (N), "random" & Iter'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-runs reference)");
end Own_Checks;

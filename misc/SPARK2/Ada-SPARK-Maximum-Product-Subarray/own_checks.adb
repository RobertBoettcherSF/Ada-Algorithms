--  Own tests for Maximum_Product_Subarray (see tests/SOURCES.txt).
--  Best_Product (A, N) must be the largest product of a contiguous run of A (1 .. N).
--  Whether the empty run (product 1) counts is fixed by one input; N = 0 is not checked.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Maximum_Product_Subarray; use Maximum_Product_Subarray;

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

   A : Values;
   Empty_Ok : Boolean;
   function Ref (N : Positive) return Integer is
      Best : Integer := (if Empty_Ok then 1 else Integer'First);
      P : Integer;
   begin
      for I in 1 .. N loop
         P := 1;
         for J in I .. N loop
            P := P * A (J);
            Best := Integer'Max (Best, P);
         end loop;
      end loop;
      return Best;
   end Ref;
begin
   A := [others => 0];
   A (1) := -5;
   Empty_Ok := Best_Product (A, 1) = 1;
   Report (Best_Product (A, 1) in -5 | 1, "one negative element gives -5 or 1");
   for N in 1 .. 4 loop                       --  every array over -3 .. 3
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
         Report (Best_Product (A, N) = Ref (N), "small");
      end loop;
   end loop;
   for Iter in 1 .. 5_000 loop
      declare
         N : constant Positive := Next (1, 4);
      begin
         for I in 1 .. 4 loop
            A (I) := Next (-10, 10);
         end loop;
         Report (Best_Product (A, N) = Ref (N), "random" & Iter'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-runs reference)");
end Own_Checks;

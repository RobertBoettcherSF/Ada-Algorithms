pragma Ada_2022;
--  Own tests for Palindrome_Partitioning (see tests/SOURCES.txt).
--  Minimum_Cuts (A, N): fewest cuts splitting A (1 .. N) into palindromes; own exhaustive reference.
with Ada.Text_IO; use Ada.Text_IO;
with Palindrome_Partitioning; use Palindrome_Partitioning;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   A : Word;
   function Pal (L, R : Positive) return Boolean is
     (for all I in 0 .. (R - L) / 2 => A (L + I) = A (R - I));
   function Best (From, N : Natural) return Natural is   --  pieces needed for A (From .. N)
      Result : Natural := Natural'Last;
   begin
      if From > N then return 0; end if;
      for To in From .. N loop
         if Pal (From, To) then Result := Natural'Min (Result, 1 + Best (To + 1, N)); end if;
      end loop;
      return Result;
   end Best;
begin
   for Code in 0 .. 3**4 - 1 loop   --  every word over a three-letter alphabet
      for I in 1 .. 4 loop A (I) := (Code / 3**(I - 1)) mod 3; end loop;
      for N in 0 .. 4 loop
         Report (Minimum_Cuts (A, N) = (if N = 0 then 0 else Best (1, N) - 1), "word" & Integer'Image (Code) & " N" & Integer'Image (N));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

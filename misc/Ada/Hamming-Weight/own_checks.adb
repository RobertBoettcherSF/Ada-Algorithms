pragma Ada_2022;
--  Own tests for Hamming_Weight (see tests/SOURCES.txt).
--  Every variant must return the number of 1 bits; own reference: repeated division by 2.
with Ada.Text_IO; use Ada.Text_IO;
with Hamming_Weight; use Hamming_Weight;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Ref (V : Word_32) return Natural is
      X : Word_32 := V;
      C : Natural := 0;
   begin
      while X /= 0 loop C := C + Natural (X mod 2); X := X / 2; end loop;
      return C;
   end Ref;
begin
   for Run in 1 .. 50000 loop
      declare
         V : Word_32;
         R : Natural;
      begin
         case Run mod 4 is
            when 0 => V := Word_32 (Next (0, 2**30)) * 4 + Word_32 (Next (0, 3));
            when 1 => V := Word_32 (Run / 4 mod 33) ;   --  small values
            when 2 => V := (if Run / 4 mod 33 = 32 then Word_32'Last else 2 ** (Run / 4 mod 33) - 1);   --  all-ones runs
            when others => V := Word_32'Last - Word_32 (Next (0, 1000));
         end case;
         R := Ref (V);
         Report (Natural (Naive_Count (V)) = R and then Natural (Kernighan_Count (V)) = R
                 and then Natural (SWAR_Count (V)) = R and then Natural (SWAR_Multiply_Count (V)) = R
                 and then Natural (Lookup_Table_Count (V)) = R, "V =" & Word_32'Image (V));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

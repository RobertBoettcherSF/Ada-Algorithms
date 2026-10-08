pragma Ada_2022;
--  Own tests for Gray_Code (see tests/SOURCES.txt).
--  Encode against the reflected-binary construction (Gray code of n bits = 0 & G(n-1), then 1 & reverse G(n-1)),
--  built as a table for 0 .. 2**12 - 1; adjacent codes differ in exactly one bit; Decode inverts Encode on
--  random 32-bit words.
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;
with Gray_Code; use Gray_Code;

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
   use type Interfaces.Unsigned_32;
   Bits : constant := 12;
   Table : array (0 .. 2 ** Bits - 1) of Word := [others => 0];
   function Ones (V : Word) return Natural is
      X : Word := V; C : Natural := 0;
   begin
      while X /= 0 loop C := C + Natural (X and 1); X := Interfaces.Shift_Right (X, 1); end loop;
      return C;
   end Ones;
begin
   --  reflected construction: G(k+1) = G(k) followed by G(k) reversed with bit k set
   for K in 0 .. Bits - 1 loop
      for I in 0 .. 2 ** K - 1 loop
         Table (2 ** (K + 1) - 1 - I) := Table (I) or Word (2 ** K);
      end loop;
   end loop;
   for I in Table'Range loop
      Report (Encode (Word (I)) = Table (I), "Encode" & I'Image);
      Report (Decode (Table (I)) = Word (I), "Decode" & I'Image);
      if I > 0 then
         Report (Ones (Encode (Word (I)) xor Encode (Word (I - 1))) = 1, "adjacent codes differ in one bit at" & I'Image);
      end if;
   end loop;
   for Run in 1 .. 20000 loop
      declare
         V : constant Word := Word (Next (0, 65535)) * 65536 + Word (Next (0, 65535));
      begin
         Report (Decode (Encode (V)) = V and then Encode (Decode (V)) = V, "round trip, run" & Run'Image);
         Report (Ones (Encode (V) xor Encode (V + 1)) = 1, "successor differs in one bit, run" & Run'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

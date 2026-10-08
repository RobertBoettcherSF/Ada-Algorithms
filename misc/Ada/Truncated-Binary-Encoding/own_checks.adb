pragma Ada_2022;
--  Own tests for Truncated_Binary (see tests/SOURCES.txt).
--  Truncated binary code for an alphabet of N symbols (own properties): every code is k or k + 1
--  bits (k = floor (log2 N)), the code is prefix-free and complete (sum of 2**-length = 1), and
--  Decode_Exact / Decode invert Encode (Decode also with trailing bits).
with Ada.Text_IO; use Ada.Text_IO;
with Truncated_Binary; use Truncated_Binary;

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
   function Log2 (N : Positive) return Natural is
      K : Natural := 0;
   begin
      while 2 ** (K + 1) <= N loop K := K + 1; end loop;
      return K;
   end Log2;
begin
   for N in 2 .. 200 loop
      declare
         type Code is record S : String (1 .. 40); L : Natural; end record;
         C : array (0 .. N - 1) of Code;
         K : constant Natural := Log2 (N);
         Kraft : Long_Long_Integer := 0;   --  in units of 2**-(K + 1)
         Ok : Boolean := True;
         Used : Natural;
      begin
         for X in 0 .. N - 1 loop
            declare
               E : constant String := Encode (Symbol_Value (X), Alphabet_Size (N));
            begin
               C (X).L := E'Length; C (X).S (1 .. E'Length) := E;
               Ok := Ok and then (E'Length = K or else E'Length = K + 1)
                 and then (for all Ch of E => Ch in '0' | '1');
               if Ok then
                  Kraft := Kraft + 2 ** (K + 1 - E'Length);
                  Ok := Ok and then Natural (Decode_Exact (E, Alphabet_Size (N))) = X;
                  Ok := Ok and then Natural (Decode (E & "0110", Alphabet_Size (N), Used)) = X and then Used = E'Length;
               end if;
            end;
         end loop;
         if Ok then
            for X in 0 .. N - 1 loop
               for Y in 0 .. N - 1 loop
                  if X /= Y and then C (X).L <= C (Y).L and then C (X).S (1 .. C (X).L) = C (Y).S (1 .. C (X).L) then
                     Ok := False;   --  a code is a prefix of another one
                  end if;
               end loop;
            end loop;
         end if;
         Report (Ok and then Kraft = 2 ** (K + 1), "N =" & Integer'Image (N));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

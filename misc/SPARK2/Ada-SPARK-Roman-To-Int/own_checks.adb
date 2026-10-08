--  Own tests for Roman_To_Int (see tests/SOURCES.txt).
--  To_Integer must decode every standard Roman numeral of up to 7 letters (padded with
--  spaces, as in the existing tests) to its value; the numerals are built by our own encoder.
pragma Ada_2022;
with Ada.Text_IO;
with Roman_To_Int; use Roman_To_Int;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

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

   X : Roman_Text;
   procedure Encode (V : Positive; Ok : out Boolean) is
      type Pair is record N : Positive; S : String (1 .. 2); L : Positive; end record;
      Tab : constant array (1 .. 13) of Pair :=
        [(1000, "M ", 1), (900, "CM", 2), (500, "D ", 1), (400, "CD", 2),
         (100, "C ", 1), (90, "XC", 2), (50, "L ", 1), (40, "XL", 2),
         (10, "X ", 1), (9, "IX", 2), (5, "V ", 1), (4, "IV", 2), (1, "I ", 1)];
      R : Natural := V;
      P : Natural := 0;
   begin
      X := [others => ' '];
      Ok := True;
      for T of Tab loop
         while R >= T.N loop
            if P + T.L > Length then Ok := False; return; end if;
            for K in 1 .. T.L loop
               X (P + K) := T.S (K);
            end loop;
            P := P + T.L;
            R := R - T.N;
         end loop;
      end loop;
   end Encode;
   Ok : Boolean;
   Tried : Natural := 0;
begin
   for V in 1 .. 3_999 loop
      Encode (V, Ok);
      if Ok then
         Tried := Tried + 1;
         Report (To_Integer (X) = V, "value" & V'Image);
      end if;
   end loop;
   Report (Tried > 1_000, "enough numerals of up to 7 letters");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own encoder round trip, exhaustive)");
end Own_Checks;

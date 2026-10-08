--  Own tests for Mean_Variance (see tests/SOURCES.txt).
--  Mean is the sample mean and Variance the population variance (README),
--  returned as integers; the README leaves the rounding open, so both are
--  checked against the exact rational value rounded down or up.
pragma Ada_2022;
with Ada.Text_IO;
with Mean_Variance; use Mean_Variance;

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

   S, Q : Integer;
   X : Sample_Array;
   M, V : Integer;
   function Floor_Div (A, B : Integer) return Integer is
     (if A >= 0 then A / B else -((-A + B - 1) / B));
   function Ceil_Div (A, B : Integer) return Integer is (-Floor_Div (-A, B));
begin
   --  every one of the 5**5 = 3,125 sample arrays over -2 .. 2
   for Code in 0 .. 5**5 - 1 loop
      declare
         C : Natural := Code;
      begin
         for I in Index loop
            X (I) := C mod 5 - 2;
            C := C / 5;
         end loop;
      end;
      S := 0; Q := 0;
      for I in Index loop
         S := S + X (I);
         Q := Q + X (I) * X (I);
      end loop;
      M := Mean (X);
      V := Variance (X);
      --  exact mean S / 5; exact population variance (5 Q - S**2) / 25
      Report (M in Floor_Div (S, 5) .. Ceil_Div (S, 5), "Mean");
      Report (V in Floor_Div (5 * Q - S * S, 25) .. Ceil_Div (5 * Q - S * S, 25), "Variance");
      --  constant samples: mean is the value, variance 0
      if Q = 5 * X (1) * X (1) and then S = 5 * X (1) then
         Report (M = X (1) and V = 0, "constant sample");
      end if;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (exhaustive, exact mean and population variance rounded down or up)");
end Own_Checks;

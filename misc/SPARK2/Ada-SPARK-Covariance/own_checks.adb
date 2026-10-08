--  Own checks (see tests/SOURCES.txt): Value (A, B) is the population covariance
--  1/3 * sum (A (I) - mean A) * (B (I) - mean B), truncated toward zero.
with Ada.Text_IO;
with Covariance; use Covariance;

procedure Own_Checks is
   Checked : Natural := 0;
   A, B : Vector;
   SA, SB, N : Integer;
begin
   --  every A, and B from a coarser grid (0, 3, 6, 9, 10 per component)
   for A1 in Component loop for A2 in Component loop for A3 in Component loop
      A := [A1, A2, A3];
      for B1 in 0 .. 4 loop for B2 in 0 .. 4 loop for B3 in 0 .. 4 loop
         B := [Integer'Min (3 * B1, 10), Integer'Min (3 * B2, 10), Integer'Min (3 * B3, 10)];
         SA := A (1) + A (2) + A (3);
         SB := B (1) + B (2) + B (3);
         --  27 * covariance = sum (3 A (I) - SA) * (3 B (I) - SB): integer deviations
         N := 0;
         for I in Index loop
            N := N + (3 * A (I) - SA) * (3 * B (I) - SB);
         end loop;
         Checked := Checked + 1;
         if Value (A, B) /= N / 27 then
            Ada.Text_IO.Put_Line ("FAIL own check: Value gave" & Integer'Image (Value (A, B))
                                  & ", covariance (truncated) is" & Integer'Image (N / 27)
                                  & " for A =" & Integer'Image (A1) & Integer'Image (A2) & Integer'Image (A3)
                                  & " B =" & Integer'Image (B (1)) & Integer'Image (B (2)) & Integer'Image (B (3)));
            raise Program_Error;
         end if;
      end loop; end loop; end loop;
   end loop; end loop; end loop;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Natural'Image (Checked) & " vector pairs (own deviation-from-mean reference)");
end Own_Checks;

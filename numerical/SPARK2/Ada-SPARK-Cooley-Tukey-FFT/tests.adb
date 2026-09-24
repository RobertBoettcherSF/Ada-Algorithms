pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Cooley_Tukey_FFT; use Cooley_Tukey_FFT;
procedure Tests is
   X : Complex_Array := [others => (0, 0)];
begin
   --  Impulse at bin 0 → flat spectrum (all Re ≈ Scale input, Im ≈ 0) unnormalized.
   X (0) := (100, 0);
   FFT (X);
   Assert (X (0).Re = 100);
   Assert (X (1).Re = 100);
   Assert (X (7).Re = 100);
   Assert (X (0).Im = 0);
   Put_Line ("PASS DC impulse → flat real spectrum");

   --  Zero input stays zero.
   X := [others => (0, 0)];
   FFT (X);
   Assert (X (3).Re = 0 and then X (3).Im = 0);
   Put_Line ("PASS zero input");

   --  Nyquist-ish: alternating +A,-A on real axis.
   X := [others => (0, 0)];
   for I in Index loop
      if I mod 2 = 0 then
         X (I) := (50, 0);
      else
         X (I) := (-50, 0);
      end if;
   end loop;
   FFT (X);
   --  Energy concentrates near bin N/2 = 4 for length-8 alternating tone.
   Assert (abs (X (4).Re) >= 100);
   Put_Line ("PASS alternating tone peaks near Nyquist bin");

   Put_Line ("All Cooley_Tukey_FFT tests passed.");
end Tests;

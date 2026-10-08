--  tests_golden.adb
--  Golden error-diffusion checks. Expected outputs come from an independent
--  model of the published kernels (Wikipedia "Dither": Floyd-Steinberg /16,
--  Atkinson /8, Jarvis-Judice-Ninke /48, Stucki /42), not from this code.
--  Inputs were chosen so that every pixel decision stays >= 0.005 away from
--  the 0.5 threshold (no Float rounding sensitivity) and so that a change to
--  any single weight, offset, divisor or error sign changes the output.

with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Command_Line;
with Dithering;      use Dithering;

procedure Tests_Golden is
   subtype Grid is Image (1 .. 5, 1 .. 6);
   Fail_Count : Natural := 0;

   procedure Check (Name : String; Got, Want : Grid);

   procedure Check (Name : String; Got, Want : Grid) is
   begin
      for Y in Got'Range (1) loop
         for X in Got'Range (2) loop
            if Got (Y, X) /= Want (Y, X) then
               Put_Line ("FAIL " & Name & " at" & Y'Image & "," & X'Image);
               Fail_Count := Fail_Count + 1;
               return;
            end if;
         end loop;
      end loop;
      Put_Line ("PASS " & Name);
   end Check;
   In_FS : constant Grid := (
        1 => (0.384, 0.119, 0.153, 0.331, 0.108, 0.279),
        2 => (0.290, 0.101, 0.337, 0.282, 0.160, 0.374),
        3 => (0.230, 0.132, 0.239, 0.119, 0.255, 0.259),
        4 => (0.305, 0.249, 0.312, 0.208, 0.089, 0.182),
        5 => (0.227, 0.096, 0.191, 0.308, 0.342, 0.243));
   Want_FS : constant Grid := (
        1 => (0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
        2 => (0.0, 0.0, 1.0, 0.0, 1.0, 0.0),
        3 => (0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
        4 => (1.0, 0.0, 1.0, 0.0, 0.0, 1.0),
        5 => (0.0, 0.0, 0.0, 1.0, 0.0, 0.0));
   In_AT : constant Grid := (
        1 => (0.620, 0.772, 0.670, 0.882, 0.871, 0.843),
        2 => (0.762, 0.871, 0.738, 0.728, 0.609, 0.643),
        3 => (0.747, 0.808, 0.640, 0.749, 0.643, 0.755),
        4 => (0.802, 0.679, 0.773, 0.809, 0.797, 0.787),
        5 => (0.703, 0.693, 0.858, 0.712, 0.750, 0.738));
   Want_AT : constant Grid := (
        1 => (1.0, 1.0, 1.0, 1.0, 1.0, 1.0),
        2 => (1.0, 1.0, 1.0, 1.0, 0.0, 1.0),
        3 => (1.0, 1.0, 0.0, 1.0, 1.0, 1.0),
        4 => (1.0, 1.0, 1.0, 1.0, 1.0, 1.0),
        5 => (1.0, 0.0, 1.0, 1.0, 0.0, 1.0));
   In_JJN : constant Grid := (
        1 => (0.351, 0.231, 0.200, 0.195, 0.217, 0.441),
        2 => (0.298, 0.349, 0.288, 0.398, 0.380, 0.195),
        3 => (0.400, 0.213, 0.197, 0.286, 0.422, 0.253),
        4 => (0.430, 0.429, 0.209, 0.199, 0.331, 0.342),
        5 => (0.263, 0.277, 0.288, 0.186, 0.328, 0.161));
   Want_JJN : constant Grid := (
        1 => (0.0, 0.0, 0.0, 0.0, 0.0, 1.0),
        2 => (0.0, 1.0, 0.0, 0.0, 1.0, 0.0),
        3 => (0.0, 0.0, 0.0, 0.0, 1.0, 0.0),
        4 => (1.0, 1.0, 0.0, 0.0, 0.0, 0.0),
        5 => (0.0, 0.0, 1.0, 0.0, 1.0, 0.0));
   In_ST : constant Grid := (
        1 => (0.288, 0.398, 0.416, 0.373, 0.356, 0.378),
        2 => (0.367, 0.356, 0.300, 0.286, 0.212, 0.313),
        3 => (0.433, 0.468, 0.367, 0.228, 0.365, 0.380),
        4 => (0.397, 0.353, 0.459, 0.407, 0.252, 0.469),
        5 => (0.437, 0.288, 0.323, 0.249, 0.216, 0.263));
   Want_ST : constant Grid := (
        1 => (0.0, 0.0, 1.0, 0.0, 0.0, 0.0),
        2 => (0.0, 1.0, 0.0, 0.0, 0.0, 1.0),
        3 => (1.0, 0.0, 0.0, 1.0, 0.0, 0.0),
        4 => (0.0, 0.0, 1.0, 0.0, 0.0, 1.0),
        5 => (1.0, 0.0, 0.0, 1.0, 0.0, 0.0));
   G : Grid;
begin
   G := In_FS;
   Floyd_Steinberg_Dither (G);
   Check ("Floyd_Steinberg_Dither", G, Want_FS);
   G := In_AT;
   Atkinson_Dither (G);
   Check ("Atkinson_Dither", G, Want_AT);
   G := In_JJN;
   Jarvis_Judice_Ninke_Dither (G);
   Check ("Jarvis_Judice_Ninke_Dither", G, Want_JJN);
   G := In_ST;
   Stucki_Dither (G);
   Check ("Stucki_Dither", G, Want_ST);
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests_Golden;

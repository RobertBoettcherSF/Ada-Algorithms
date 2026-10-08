--  Film bins. Primary samples: 0, the edge 1/5, and the maximum 1.
--  Floor puts 1/5 in bin 1. The maximum is the last bin, 4, not 5.
--  Bidirectional pixels: seed 1, 4000 proposals, X in 0 .. 9, expected
--  400 each, df = 9, threshold 21.666 (p = 0.01).

pragma Ada_2022;

with Ada.Text_IO;
with Metropolis_Light_Transport;

procedure Own_Checks (Fail_Count : out Natural) is
   use Metropolis_Light_Transport;
   package Txt renames Ada.Text_IO;

   Checks : Natural := 0;
   Fails  : Natural := 0;

   procedure Note (OK : Boolean; Label : String) is
   begin
      Checks := Checks + 1;
      if not OK then
         Fails := Fails + 1;
         Txt.Put_Line ("  FAIL -- " & Label);
      end if;
   end Note;

   function Path_At (X : Unit_Real) return Light_Path is
      Samples : Primary_Sample_State;
   begin
      Samples.Dimension := 4;
      Samples.Values := [others => 0.0];
      Samples.Values (1) := X;
      return Evaluate_Primary_Sample_Path (Samples);
   end Path_At;

   RNG : RNG_State := Create_RNG (1);
   Blank : Light_Path;
   Count : array (0 .. 9) of Natural := [others => 0];
   Stat : Long_Float := 0.0;
begin
   Fail_Count := 0;
   Txt.Put_Line ("own checks: primary samples 0, 0.2, 1;"
     & " bidirectional seed 1, 4000 pixels, threshold 21.666");
   Note (Path_At (0.0).Pixel.X = 0, "sample 0 is the first pixel");
   Note (Path_At (0.2).Pixel.X = 1, "sample 1/5 is the next pixel");
   Note (Path_At (1.0).Pixel.X = 4, "the maximum sample is the last pixel");

   for I in 1 .. 4000 loop
      declare
         Got : constant Light_Path :=
           Generate_Bidirectional_Proposal (Blank, RNG);
      begin
         if Got.Pixel.X <= 9 then
            Count (Got.Pixel.X) := Count (Got.Pixel.X) + 1;
         else
            Count (0) := Count (0) + 4000;
         end if;
      end;
   end loop;
   for P in Count'Range loop
      declare
         Diff : constant Long_Float := Long_Float (Count (P)) - 400.0;
      begin
         Stat := Stat + Diff * Diff / 400.0;
      end;
   end loop;
   Note (Stat < 21.666, "bidirectional pixels, seed 1, 4000 draws");

   Txt.Put_Line ("own checks:" & Natural'Image (Checks)
     & "  failed:" & Natural'Image (Fails));
   Fail_Count := Fails;
end Own_Checks;

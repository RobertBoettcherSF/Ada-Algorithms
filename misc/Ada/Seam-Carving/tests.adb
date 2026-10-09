--  tests.adb
--  13+ Tests for Verification & Validation of Seam Carving code.
--  Philosophy: Tests assume failure and attempt to disprove it by verifying correctness.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Seam_Carving; use Seam_Carving;
with Ada.Command_Line;

procedure Tests is
   Img_3x3 : constant Image (1 .. 3, 1 .. 3) :=
     (1 => (1 => (10, 10, 10), 2 => (20, 20, 20), 3 => (10, 10, 10)),
      2 => (1 => (90, 90, 90), 2 => (10, 10, 10), 3 => (90, 90, 90)),
      3 => (1 => (10, 10, 10), 2 => (20, 20, 20), 3 => (10, 10, 10)));
   
   Img_1x3 : constant Image (1 .. 1, 1 .. 3) := (others => (others => (0, 0, 0)));
   Img_3x1 : constant Image (1 .. 3, 1 .. 1) := (others => (others => (0, 0, 0)));
   
   S : Seam (1 .. 3);
   Img_Res : Image (1 .. 2, 1 .. 3);
   Img_Ins : Image (1 .. 4, 1 .. 3);

   Total_Tests : Natural := 0;
   Passed_Tests : Natural := 0;

   procedure Run_Test (Name : String; Logic : access procedure) is
   begin
      Total_Tests := Total_Tests + 1;
      Put_Line ("-----------------------------------------");
      Put_Line ("TEST " & Total_Tests'Image & " - " & Name);
      Logic.all;
      Put_Line ("     => PASS (Assumption of failure disproven)");
      Passed_Tests := Passed_Tests + 1;
   exception
      when others =>
         Put_Line ("     => FAIL: Exception raised or assertion failed");
   end Run_Test;

   -- Test logic definitions
   procedure T1 is begin
      S := Find_Seam (Img_3x3, Vertical, Backward_Energy);
      Assert (S'Length = 3, "Seam length mismatch");
      Assert (S (1) = 2 and S (2) = 2 and S (3) = 2, "Failed to find optimal vertical backward seam");
   end T1;

   procedure T2 is begin
      S := Find_Seam (Img_3x3, Horizontal, Backward_Energy);
      Assert (S'Length = 3, "Seam length mismatch");
   end T2;

   procedure T3 is begin
      S := Find_Seam (Img_3x3, Vertical, Forward_Energy);
      Assert (S'Length = 3, "Forward energy map size error");
   end T3;

   procedure T4 is begin
      S := Find_Seam (Img_3x3, Horizontal, Forward_Energy);
      Assert (S'Length = 3, "Forward energy horizontal seam error");
   end T4;

   procedure T5 is begin
      S := (2, 2, 2);
      Img_Res := Remove_Seam (Img_3x3, S, Vertical);
      Assert (Img_Res'Length (1) = 2, "Width not reduced");
      Assert (Img_Res'Length (2) = 3, "Height altered incorrectly");
   end T5;

   procedure T6 is begin
      S := (2, 2, 2);
      declare
         Res_Horiz : constant Image := Remove_Seam (Img_3x3, S, Horizontal);
      begin
         Assert (Res_Horiz'Length (1) = 3, "Width altered incorrectly");
         Assert (Res_Horiz'Length (2) = 2, "Height not reduced");
      end;
   end T6;

   procedure T7 is begin
      S := (2, 2, 2);
      Img_Ins := Insert_Seam (Img_3x3, S, Vertical);
      Assert (Img_Ins'Length (1) = 4, "Width not increased");
      Assert (Img_Ins'Length (2) = 3, "Height altered incorrectly");
   end T7;

   procedure T8 is begin
      S := (2, 2, 2);
      declare
         Ins_Horiz : constant Image := Insert_Seam (Img_3x3, S, Horizontal);
      begin
         Assert (Ins_Horiz'Length (1) = 3, "Width altered incorrectly");
         Assert (Ins_Horiz'Length (2) = 4, "Height not increased");
      end;
   end T8;

   procedure T9 is begin
      S := (1, 1, 1);
      declare
         Res : constant Image := Remove_Seam (Img_3x3, S, Vertical);
      begin
         Assert (Res (1, 1).R = 90, "Data integrity: right pixels not shifted properly");
      end;
   end T9;

   procedure T10 is begin
      S := (3, 3, 3);
      declare
         Res : constant Image := Remove_Seam (Img_3x3, S, Vertical);
      begin
         Assert (Res (1, 1).R = 10, "Data integrity: left pixels mutated incorrectly");
      end;
   end T10;

   procedure T11 is begin
      S := (1, 1, 1);
      declare
         Res : constant Image := Remove_Seam (Img_1x3, S, Vertical);
      begin
         pragma Unreferenced (Res);
         Assert (False, "Should have raised Image_Too_Small");
      end;
   exception
      when Image_Too_Small => null; -- PASS
   end T11;

   procedure T12 is begin
      S := (1, 1, 1);
      declare
         Res : constant Image := Remove_Seam (Img_3x1, S, Horizontal);
      begin
         pragma Unreferenced (Res);
         Assert (False, "Should have raised Image_Too_Small");
      end;
   exception
      when Image_Too_Small => null; -- PASS
   end T12;

   procedure T13 is begin
      S := (2, 2, 2);
      declare
         Res : constant Image := Insert_Seam (Img_3x3, S, Vertical);
      begin
         Assert (Res (3, 1).R = 50, "Averaged inserted pixel is calculated incorrectly");
      end;
   end T13;

   procedure T14 is begin
      declare
         Uniform : constant Image (1 .. 2, 1 .. 2) := (others => (others => (5, 5, 5)));
         Test_S  : constant Seam := Find_Seam (Uniform, Vertical, Backward_Energy);
      begin
         Assert (Test_S (1) = 1, "Uniform image should default to leftmost seam");
      end;
   end T14;

   --  Brute-force reference (T15, T16). Seam values are column positions
   --  counted from 1 (index Y counted from 1), as returned by Find_Seam.
   Seed  : constant := 20261009;
   State : Long_Long_Integer := Seed;
   function Next (M : Positive) return Natural is
   begin
      State := (State * 1103515245 + 12345) mod 2**31;
      return Natural (State / 65536 mod Long_Long_Integer (M));
   end Next;

   function Diff (A, B : Pixel) return Integer is
     (abs (A.R - B.R) + abs (A.G - B.G) + abs (A.B - B.B));

   --  Pixel at 1-based column X, row Y, clamped to the image
   function At_1 (Img : Image; X, Y : Integer) return Pixel is
      CX : constant Integer := Integer'Max (1, Integer'Min (Img'Length (1), X));
      CY : constant Integer := Integer'Max (1, Integer'Min (Img'Length (2), Y));
   begin
      return Img (Img'First (1) + CX - 1, Img'First (2) + CY - 1);
   end At_1;

   --  Cost of a vertical seam under the package's two energy definitions:
   --  backward = sum of dual-gradient energies of its pixels; forward = sum
   --  over rows 2 .. H of the edge cost created by the step into the row
   --  (CU straight down, CL from the upper left, CR from the upper right).
   function Cost (Img : Image; S : Seam; E : Energy_Function_Type) return Integer is
      Total : Integer := 0;
   begin
      for Y in 1 .. Img'Length (2) loop
         declare
            X : constant Integer := S (S'First + Y - 1);
         begin
            if E = Backward_Energy then
               Total := Total + Diff (At_1 (Img, X + 1, Y), At_1 (Img, X - 1, Y))
                              + Diff (At_1 (Img, X, Y + 1), At_1 (Img, X, Y - 1));
            elsif Y > 1 then
               declare
                  Prev : constant Integer := S (S'First + Y - 2);
                  CU   : constant Integer := Diff (At_1 (Img, X + 1, Y), At_1 (Img, X - 1, Y));
               begin
                  Total := Total + CU;
                  if Prev = X - 1 then
                     Total := Total + Diff (At_1 (Img, X, Y - 1), At_1 (Img, X - 1, Y));
                  elsif Prev = X + 1 then
                     Total := Total + Diff (At_1 (Img, X, Y - 1), At_1 (Img, X + 1, Y));
                  end if;
               end;
            end if;
         end;
      end loop;
      return Total;
   end Cost;

   --  Minimum cost over every connected vertical seam (exhaustive)
   function Best_Cost (Img : Image; E : Energy_Function_Type) return Integer is
      W    : constant Positive := Img'Length (1);
      H    : constant Positive := Img'Length (2);
      S    : Seam (1 .. H);
      Best : Integer := Integer'Last;
      procedure Extend (Y : Positive) is
      begin
         for X in 1 .. W loop
            if Y = 1 or else abs (X - S (Y - 1)) <= 1 then
               S (Y) := X;
               if Y = H then
                  Best := Integer'Min (Best, Cost (Img, S, E));
               else
                  Extend (Y + 1);
               end if;
            end if;
         end loop;
      end Extend;
   begin
      Extend (1);
      return Best;
   end Best_Cost;

   function Valid (Img : Image; S : Seam) return Boolean is
   begin
      if S'Length /= Img'Length (2) then
         return False;
      end if;
      for K in S'Range loop
         if S (K) > Img'Length (1)
           or else (K > S'First and then abs (S (K) - S (K - 1)) > 1)
         then
            return False;
         end if;
      end loop;
      return True;
   end Valid;

   function Transposed (Img : Image) return Image is
      R : Image (Img'Range (2), Img'Range (1));
   begin
      for X in Img'Range (1) loop
         for Y in Img'Range (2) loop
            R (Y, X) := Img (X, Y);
         end loop;
      end loop;
      return R;
   end Transposed;

   --  T15: on 3,000 seeded random images (seed 20261009, 1..4 x 1..5,
   --  lower bounds 1 or 5) every returned seam is connected and costs
   --  exactly the exhaustive minimum, for both energies and directions.
   procedure T15 is
      Bad : Natural := 0;
   begin
      for K in 1 .. 3_000 loop
         declare
            W   : constant Positive := 1 + Next (4);
            H   : constant Positive := 1 + Next (5);
            FX  : constant Positive := (if Next (2) = 0 then 1 else 5);
            FY  : constant Positive := (if Next (2) = 0 then 1 else 5);
            Lev : constant Positive := (if Next (2) = 0 then 4 else 256);
            Img : Image (FX .. FX + W - 1, FY .. FY + H - 1);
         begin
            for X in Img'Range (1) loop
               for Y in Img'Range (2) loop
                  Img (X, Y) := (Next (Lev), Next (Lev), Next (Lev));
               end loop;
            end loop;
            for E in Energy_Function_Type loop
               declare
                  SV : constant Seam := Find_Seam (Img, Vertical, E);
                  SH : constant Seam := Find_Seam (Img, Horizontal, E);
                  T  : constant Image := Transposed (Img);
               begin
                  if not Valid (Img, SV) or else Cost (Img, SV, E) /= Best_Cost (Img, E) then
                     Bad := Bad + 1;
                  end if;
                  if not Valid (T, SH) or else Cost (T, SH, E) /= Best_Cost (T, E) then
                     Bad := Bad + 1;
                  end if;
               end;
            end loop;
         end;
      end loop;
      Put_Line ("     seams not optimal or not connected:" & Bad'Image & " of 12000");
      Assert (Bad = 0, "Find_Seam returned a non-optimal seam");
   end T15;

   --  T16: Remove_Seam / Insert_Seam on an image whose bounds start at 5
   --  give the same pixels as on the same image at bounds 1.
   procedure T16 is
      A : Image (1 .. 3, 1 .. 2);
      B : Image (5 .. 7, 5 .. 6);
   begin
      for X in 1 .. 3 loop
         for Y in 1 .. 2 loop
            A (X, Y) := (10 * X + Y, 0, 0);
            B (X + 4, Y + 4) := A (X, Y);
         end loop;
      end loop;
      declare
         S  : constant Seam := (1 => 2, 2 => 3);
         RA : constant Image := Remove_Seam (A, S, Vertical);
         RB : constant Image := Remove_Seam (B, S, Vertical);
         IA : constant Image := Insert_Seam (A, S, Vertical);
         IB : constant Image := Insert_Seam (B, S, Vertical);
      begin
         Assert (RA = RB, "Remove_Seam depends on the image lower bound");
         Assert (IA = IB, "Insert_Seam depends on the image lower bound");
         Assert (RA (2, 1).R = 31 and then RA (2, 2).R = 22, "Remove_Seam removed the wrong pixels");
      end;
      Assert (Cost (B, Find_Seam (B, Vertical, Forward_Energy), Forward_Energy)
              = Best_Cost (B, Forward_Energy), "forward seam at lower bound 5");
   end T16;

begin
   Put_Line ("Starting Seam Carving Test Suite...");
   
   Run_Test ("Vertical Seam - Backward Energy", T1'Access);
   Run_Test ("Horizontal Seam - Backward Energy", T2'Access);
   Run_Test ("Vertical Seam - Forward Energy", T3'Access);
   Run_Test ("Horizontal Seam - Forward Energy", T4'Access);
   Run_Test ("Remove Vertical Seam (Dimensions)", T5'Access);
   Run_Test ("Remove Horizontal Seam (Dimensions)", T6'Access);
   Run_Test ("Insert Vertical Seam (Dimensions)", T7'Access);
   Run_Test ("Insert Horizontal Seam (Dimensions)", T8'Access);
   Run_Test ("Remove Seam - Shift Data Integrity", T9'Access);
   Run_Test ("Remove Seam - Preserve Left Data", T10'Access);
   Run_Test ("Edge Case - Remove Vertical from 1xN", T11'Access);
   Run_Test ("Edge Case - Remove Horizontal from Nx1", T12'Access);
   Run_Test ("Insert Seam - Interpolation Correctness", T13'Access);
   Run_Test ("Uniform Image Pathfinding Fallback", T14'Access);
   Run_Test ("Seams optimal vs exhaustive search (seed 20261009)", T15'Access);
   Run_Test ("Remove/Insert independent of image lower bounds", T16'Access);

   Put_Line ("=========================================");
   Put_Line ("Tests Passed: " & Passed_Tests'Image & " / " & Total_Tests'Image);
   if Passed_Tests /= Total_Tests then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

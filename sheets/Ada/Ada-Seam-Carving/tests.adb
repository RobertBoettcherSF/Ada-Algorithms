--  tests.adb
--  13+ Tests for Verification & Validation of Seam Carving code.
--  Philosophy: Tests assume failure and attempt to disprove it by verifying correctness.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Seam_Carving; use Seam_Carving;

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

   Put_Line ("=========================================");
   Put_Line ("Tests Passed: " & Passed_Tests'Image & " / " & Total_Tests'Image);
end Tests;

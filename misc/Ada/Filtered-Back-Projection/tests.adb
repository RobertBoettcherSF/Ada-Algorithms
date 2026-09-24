--  Standalone test suite for Filtered_Back_Projection (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Text_IO;
with Filtered_Back_Projection; use Filtered_Back_Projection;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Ada.Text_IO.Put_Line ("Filtered_Back_Projection test suite");
   Ada.Text_IO.Put_Line ("===================================");

   ---------------------------------------------------------------------
   Section ("1. Near / validation helpers");
   ---------------------------------------------------------------------
   declare
      Z  : constant Image_2D := Make_Empty_Image (8);
      S0 : constant Sinogram := Make_Empty_Sinogram (8, 8);
      Bad_I : Image_2D;
      Bad_S : Sinogram;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Near (1.0, 1.0 + Near_Tol / 2.0), "Near within tol");
      Check (Is_Valid_Image (Z), "Valid empty image");
      Check (Is_Valid_Sinogram (S0), "Valid empty sinogram");
      Check (not Is_Valid_Image (Bad_I), "Invalid image");
      Check (not Is_Valid_Sinogram (Bad_S), "Invalid sinogram");
      Check (Large_Enough_Image (Z), "Large enough 8");
      Check (not Large_Enough_Image (Make_Empty_Image (3)),
             "Reject image N=3");
      Check (Large_Enough_Sinogram (S0), "Large enough sino 8x8");
      Check (not Large_Enough_Sinogram (Make_Empty_Sinogram (3, 8)),
             "Reject angles=3");
      Check (not Large_Enough_Sinogram (Make_Empty_Sinogram (8, 3)),
             "Reject bins=3");
      Check (Approx (Image_Sum (Z), 0.0), "Zero image sum");
      Check (Approx (Sinogram_Angle_Sum (S0, 0), 0.0),
             "Zero sino angle sum");
   end;

   ---------------------------------------------------------------------
   Section ("2. Get / Set accessors");
   ---------------------------------------------------------------------
   declare
      Img : Image_2D := Make_Empty_Image (4);
      S   : Sinogram := Make_Empty_Sinogram (4, 4);
   begin
      Set (Img, 1, 2, 3.5);
      Check (Approx (Get (Img, 1, 2), 3.5), "Image Get/Set");
      Set (S, 2, 1, -1.25);
      Check (Approx (Get (S, 2, 1), -1.25), "Sinogram Get/Set");
      Check (Approx (Image_Sum (Img), 3.5), "Image sum after set");
      Check (Approx (Sinogram_Angle_Sum (S, 2), -1.25),
             "Angle sum after set");
   end;

   ---------------------------------------------------------------------
   Section ("3. Zero image → zero sinogram");
   ---------------------------------------------------------------------
   declare
      Z   : constant Image_2D := Make_Empty_Image (16);
      Fwd : constant Sinogram_Result := Forward_Project (Z, 24, 16);
      Max_Abs : Float := 0.0;
   begin
      Check (Fwd.Success, "Forward zero Success");
      Check (Fwd.Stat = Ok, "Forward zero Ok");
      Check (Fwd.Sino.N_Angles = 24, "Forward angles");
      Check (Fwd.Sino.N_Bins = 16, "Forward bins");
      for A in 0 .. Fwd.Sino.N_Angles - 1 loop
         for B in 0 .. Fwd.Sino.N_Bins - 1 loop
            if abs (Fwd.Sino.Values (A, B)) > Max_Abs then
               Max_Abs := abs (Fwd.Sino.Values (A, B));
            end if;
         end loop;
      end loop;
      Check (Max_Abs = 0.0, "Zero image yields zero sinogram");
   end;

   ---------------------------------------------------------------------
   Section ("4. Disk phantom");
   ---------------------------------------------------------------------
   declare
      D   : constant Image_Result :=
              Make_Disk_Phantom (16, Float (16) / 5.0);
      Mid : constant Axis_Index := 8;
      Corn_Sum : Float := 0.0;
   begin
      Check (D.Success, "Disk Success");
      Check (D.Stat = Ok, "Disk Ok");
      Check (D.Image.N = 16, "Disk N");
      Check (Approx (Get (D.Image, Mid, Mid), 1.0), "Disk center 1");
      Check (Approx (Get (D.Image, 0, 0), 0.0), "Disk corner 0");
      Check (Image_Sum (D.Image) > 10.0, "Disk mass positive");
      for I in 0 .. 1 loop
         for J in 0 .. 1 loop
            Corn_Sum := Corn_Sum + Get (D.Image, I, J);
         end loop;
      end loop;
      Check (Approx (Corn_Sum, 0.0), "Disk corner block zero");
   end;

   ---------------------------------------------------------------------
   Section ("5. Shepp-lite phantom");
   ---------------------------------------------------------------------
   declare
      Sh : constant Image_Result := Make_Shepp_Lite (20);
   begin
      Check (Sh.Success, "Shepp Success");
      Check (Sh.Stat = Ok, "Shepp Ok");
      Check (Sh.Image.N = 20, "Shepp N");
      Check (Image_Sum (Sh.Image) > 0.0, "Shepp mass > 0");
      Check (Get (Sh.Image, 10, 10) > 0.0, "Shepp center bright");
   end;

   ---------------------------------------------------------------------
   Section ("6. Projection mass conservation-ish");
   ---------------------------------------------------------------------
   declare
      D    : constant Image_Result :=
               Make_Disk_Phantom (24, Float (24) / 5.0);
      Mass : constant Float := Image_Sum (D.Image);
      Fwd  : constant Sinogram_Result :=
               Forward_Project (D.Image, 36, 24);
      Ratio : Float;
      Ok_Angles : Natural := 0;
   begin
      Check (Fwd.Success, "Mass Fwd Success");
      Check (Mass > 0.0, "Phantom mass > 0");
      for A in 0 .. Fwd.Sino.N_Angles - 1 loop
         Ratio := Sinogram_Angle_Sum (Fwd.Sino, A) / Mass;
         if Ratio > 0.85 and then Ratio < 1.15 then
            Ok_Angles := Ok_Angles + 1;
         end if;
      end loop;
      Check (Ok_Angles >= Fwd.Sino.N_Angles * 3 / 4,
             "Most angles conserve mass ±15%");
      --  Mean ratio near 1
      declare
         Acc : Float := 0.0;
      begin
         for A in 0 .. Fwd.Sino.N_Angles - 1 loop
            Acc := Acc + Sinogram_Angle_Sum (Fwd.Sino, A);
         end loop;
         Acc := Acc / Float (Fwd.Sino.N_Angles);
         Check (Approx (Acc / Mass, 1.0, 0.08),
                "Mean angle sum ≈ image mass");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Ram-Lak kernel values");
   ---------------------------------------------------------------------
   declare
      use Ada.Numerics;
      Pi_F : constant Float := Float (Pi);
   begin
      Check (Approx (Ram_Lak_Kernel_Value (0), 0.25), "h[0]=1/4");
      Check (Approx (Ram_Lak_Kernel_Value (2), 0.0), "h[2]=0 even");
      Check (Approx (Ram_Lak_Kernel_Value (-4), 0.0), "h[-4]=0 even");
      Check (Approx (Ram_Lak_Kernel_Value (1),
                     -1.0 / (Pi_F * Pi_F)), "h[1]=-1/pi^2");
      Check (Approx (Ram_Lak_Kernel_Value (-1),
                     -1.0 / (Pi_F * Pi_F)), "h[-1] symmetric");
      Check (Approx (Ram_Lak_Kernel_Value (3),
                     -1.0 / (Pi_F * Pi_F * 9.0)), "h[3]=-1/(9 pi^2)");
      Check (Ram_Lak_Kernel_Value (5) < 0.0, "h[5] negative");
      Check (Ram_Lak_Kernel_Value (0) > Ram_Lak_Kernel_Value (1),
             "h[0] > h[1]");
   end;

   ---------------------------------------------------------------------
   Section ("8. Filter length / structure");
   ---------------------------------------------------------------------
   declare
      Z    : constant Image_2D := Make_Empty_Image (12);
      --  Impulse projection
      S    : Sinogram := Make_Empty_Sinogram (8, 16);
      Filt : Sinogram_Result;
      Mid  : constant Bin_Index := 8;
   begin
      Set (S, 0, Mid, 1.0);
      Filt := Filter_Ram_Lak (S);
      Check (Filt.Success, "Filter impulse Success");
      Check (Filt.Stat = Ok, "Filter impulse Ok");
      Check (Filt.Sino.N_Angles = 8, "Filter preserves angles");
      Check (Filt.Sino.N_Bins = 16, "Filter preserves bins");
      Check (Approx (Get (Filt.Sino, 0, Mid), 0.25, 1.0E-5),
             "Impulse → h[0] at center");
      Check (Get (Filt.Sino, 0, Mid) >
             Get (Filt.Sino, 0, Mid + 1),
             "Peak at impulse bin");
      Check (Get (Filt.Sino, 0, Mid + 1) < 0.0,
             "Odd neighbor negative (Ram-Lak)");
      --  Zero input stays zero
      declare
         Fz : constant Sinogram_Result :=
                Filter_Ram_Lak (Make_Empty_Sinogram (8, 12));
         M  : Float := 0.0;
      begin
         Check (Fz.Success, "Filter zero Success");
         for A in 0 .. Fz.Sino.N_Angles - 1 loop
            for B in 0 .. Fz.Sino.N_Bins - 1 loop
               if abs (Fz.Sino.Values (A, B)) > M then
                  M := abs (Fz.Sino.Values (A, B));
               end if;
            end loop;
         end loop;
         Check (M = 0.0, "Filter zero → zero");
      end;
      pragma Unreferenced (Z);
   end;

   ---------------------------------------------------------------------
   Section ("9. FBP recovers disk roughly");
   ---------------------------------------------------------------------
   declare
      N    : constant Axis_Size := 16;
      D    : constant Image_Result :=
               Make_Disk_Phantom (N, Float (N) / 5.0);
      Rec  : constant Image_Result :=
               Reconstruct_FBP (D.Image, 32, 16);
      Mid  : constant Axis_Index := Axis_Index (N / 2);
      Cen  : Float;
      Bg   : Float;
      Corr : Correlation_Result;
   begin
      Check (Rec.Success, "Reconstruct Success");
      Check (Rec.Stat = Ok, "Reconstruct Ok");
      Check (Rec.Image.N = N, "Reconstruct size");
      Cen := Get (Rec.Image, Mid, Mid);
      Bg := (Get (Rec.Image, 0, 0)
           + Get (Rec.Image, 0, 1)
           + Get (Rec.Image, 1, 0)
           + Get (Rec.Image, 1, 1)) / 4.0;
      Check (Cen > Bg + 0.2, "Center brighter than background");
      Check (Cen > 0.4, "Center reasonably bright");
      Corr := Correlation (D.Image, Rec.Image);
      Check (Corr.Success, "Correlation Success");
      Check (Corr.Value > 0.85, "Correlation > 0.85 vs phantom");
      Ada.Text_IO.Put_Line
        ("    (center=" & Cen'Image
         & " bg=" & Bg'Image
         & " corr=" & Corr.Value'Image & ")");
   end;

   ---------------------------------------------------------------------
   Section ("10. Larger disk FBP (N=24)");
   ---------------------------------------------------------------------
   declare
      N    : constant Axis_Size := 24;
      D    : constant Image_Result :=
               Make_Disk_Phantom (N, Float (N) / 5.0);
      Rec  : constant Image_Result :=
               Reconstruct_FBP (D.Image, 36, 24);
      Mid  : constant Axis_Index := Axis_Index (N / 2);
      Corr : Correlation_Result;
   begin
      Check (Rec.Success, "N24 Reconstruct Success");
      Check (Get (Rec.Image, Mid, Mid) >
             Get (Rec.Image, 1, 1) + 0.2,
             "N24 center > background");
      Corr := Correlation (D.Image, Rec.Image);
      Check (Corr.Success and then Corr.Value > 0.9,
             "N24 correlation > 0.9");
   end;

   ---------------------------------------------------------------------
   Section ("11. Pipeline stages separately");
   ---------------------------------------------------------------------
   declare
      D    : constant Image_Result :=
               Make_Disk_Phantom (16, 3.0);
      Fwd  : constant Sinogram_Result :=
               Forward_Project (D.Image, 24, 16);
      Filt : Sinogram_Result;
      Back : Image_Result;
   begin
      Check (Fwd.Success, "Stage Fwd");
      Filt := Filter_Ram_Lak (Fwd.Sino);
      Check (Filt.Success, "Stage Filter");
      Back := Back_Project (Filt.Sino, 16);
      Check (Back.Success, "Stage Back");
      Check (Get (Back.Image, 8, 8) > Get (Back.Image, 0, 0),
             "Staged FBP center > corner");
   end;

   ---------------------------------------------------------------------
   Section ("12. Bad dimensions / Too_Small / Ill_Started");
   ---------------------------------------------------------------------
   declare
      Bad_I : Image_2D;
      Tiny  : constant Image_2D := Make_Empty_Image (3);
      Ok_I  : constant Image_2D := Make_Empty_Image (8);
      R1    : Image_Result;
      R2    : Sinogram_Result;
      R3    : Image_Result;
      R4    : Image_Result;
      R5    : Sinogram_Result;
      R6    : Correlation_Result;
      Small_S : constant Sinogram := Make_Empty_Sinogram (3, 8);
   begin
      R1 := Make_Disk_Phantom (0, 1.0);
      Check (R1.Stat = Ill_Started and then not R1.Success,
             "Disk N=0 Ill_Started");
      R1 := Make_Disk_Phantom (8, -1.0);
      Check (R1.Stat = Ill_Started, "Disk neg radius Ill_Started");
      R1 := Make_Disk_Phantom (3, 1.0);
      Check (R1.Stat = Too_Small, "Disk N=3 Too_Small");

      R1 := Make_Shepp_Lite (0);
      Check (R1.Stat = Ill_Started, "Shepp N=0 Ill_Started");
      R1 := Make_Shepp_Lite (2);
      Check (R1.Stat = Too_Small, "Shepp N=2 Too_Small");

      R2 := Forward_Project (Bad_I, 8, 8);
      Check (R2.Stat = Ill_Started, "Fwd invalid Ill_Started");
      R2 := Forward_Project (Ok_I, 0, 8);
      Check (R2.Stat = Ill_Started, "Fwd angles=0 Ill_Started");
      R2 := Forward_Project (Tiny, 8, 8);
      Check (R2.Stat = Too_Small, "Fwd tiny image Too_Small");
      R2 := Forward_Project (Ok_I, 3, 8);
      Check (R2.Stat = Too_Small, "Fwd few angles Too_Small");
      R2 := Forward_Project (Ok_I, 8, 3);
      Check (R2.Stat = Too_Small, "Fwd few bins Too_Small");

      R5 := Filter_Ram_Lak (Sinogram'(others => <>));
      Check (R5.Stat = Ill_Started, "Filter invalid Ill_Started");
      R5 := Filter_Ram_Lak (Small_S);
      Check (R5.Stat = Too_Small, "Filter small Too_Small");

      R3 := Back_Project (Make_Empty_Sinogram (8, 8), 0);
      Check (R3.Stat = Ill_Started, "Back N=0 Ill_Started");
      R3 := Back_Project (Small_S, 8);
      Check (R3.Stat = Too_Small, "Back small sino Too_Small");
      R3 := Back_Project (Make_Empty_Sinogram (8, 8), 16);
      Check (R3.Stat = Dimension_Error,
             "Back bins < N Dimension_Error");

      R4 := Reconstruct_FBP (Bad_I, 8, 8);
      Check (R4.Stat = Ill_Started, "Recon invalid Ill_Started");
      R4 := Reconstruct_FBP (Ok_I, 8, 4);
      Check (R4.Stat = Dimension_Error or else R4.Stat = Too_Small,
             "Recon bins < N rejected");
      R4 := Reconstruct_FBP (Tiny, 8, 8);
      Check (R4.Stat = Too_Small, "Recon tiny Too_Small");
      R4 := Reconstruct_FBP (Ok_I, 0, 8);
      Check (R4.Stat = Ill_Started, "Recon angles=0 Ill_Started");

      R6 := Correlation (Bad_I, Ok_I);
      Check (R6.Stat = Ill_Started, "Corr invalid Ill_Started");
      R6 := Correlation (Make_Empty_Image (8), Make_Empty_Image (10));
      Check (R6.Stat = Dimension_Error, "Corr size mismatch");
      R6 := Correlation (Make_Empty_Image (1), Make_Empty_Image (1));
      Check (R6.Stat = Too_Small, "Corr N=1 Too_Small");
   end;

   ---------------------------------------------------------------------
   Section ("13. Correlation metric");
   ---------------------------------------------------------------------
   declare
      A : Image_2D := Make_Empty_Image (6);
      B : Image_2D := Make_Empty_Image (6);
      C : Correlation_Result;
   begin
      for I in 0 .. 5 loop
         for J in 0 .. 5 loop
            Set (A, I, J, Float (I + J));
            Set (B, I, J, Float (I + J));
         end loop;
      end loop;
      C := Correlation (A, B);
      Check (C.Success and then Approx (C.Value, 1.0, 1.0E-5),
             "Identical images corr=1");
      for I in 0 .. 5 loop
         for J in 0 .. 5 loop
            Set (B, I, J, -Float (I + J));
         end loop;
      end loop;
      C := Correlation (A, B);
      Check (C.Success and then Approx (C.Value, -1.0, 1.0E-5),
             "Negated images corr=-1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Constants / caps (via builders)");
   ---------------------------------------------------------------------
   declare
      Big_I : constant Image_2D := Make_Empty_Image (Max_N);
      Big_S : constant Sinogram :=
                Make_Empty_Sinogram (Max_Angles, Max_Bins);
      Edge  : constant Image_Result :=
                Make_Disk_Phantom (Min_N, 1.0);
      Tiny  : constant Image_Result :=
                Make_Disk_Phantom (Min_N - 1, 1.0);
   begin
      Check (Big_I.N = Max_N and then Big_I.Valid, "Empty at Max_N");
      Check (Big_S.N_Angles = Max_Angles, "Empty sino Max_Angles");
      Check (Big_S.N_Bins = Max_Bins, "Empty sino Max_Bins");
      Check (Edge.Success and then Edge.Image.N = Min_N,
             "Disk at Min_N ok");
      Check (Tiny.Stat = Too_Small, "Disk below Min_N rejected");
      Check (Large_Enough_Sinogram
                (Make_Empty_Sinogram (Min_Angles, Min_Bins)),
             "Sino at Min_Angles x Min_Bins large enough");
      Check (not Large_Enough_Sinogram
                (Make_Empty_Sinogram (Min_Angles - 1, Min_Bins)),
             "Sino below Min_Angles rejected by helper");
   end;

   ---------------------------------------------------------------------
   Section ("15. Filtered zero reconstructs near zero");
   ---------------------------------------------------------------------
   declare
      Z   : constant Image_2D := Make_Empty_Image (12);
      Rec : constant Image_Result := Reconstruct_FBP (Z, 16, 12);
      M   : Float := 0.0;
   begin
      Check (Rec.Success, "Zero recon Success");
      for I in 0 .. Rec.Image.N - 1 loop
         for J in 0 .. Rec.Image.N - 1 loop
            if abs (Rec.Image.Values (I, J)) > M then
               M := abs (Rec.Image.Values (I, J));
            end if;
         end loop;
      end loop;
      Check (M < 1.0E-5, "Zero → near-zero reconstruction");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;

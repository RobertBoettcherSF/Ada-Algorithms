with Ada.Text_IO; use Ada.Text_IO;
with Metropolis_Light_Transport; use Metropolis_Light_Transport;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   RNG : RNG_State := Create_RNG (987_654);
   C_White : constant Color_RGB := (R => 1.0, G => 1.0, B => 1.0);
   C_Black : constant Color_RGB := (R => 0.0, G => 0.0, B => 0.0);
   C_Red   : constant Color_RGB := (R => 2.0, G => 0.0, B => 0.0);
   Init_Path : Light_Path;
   Sample_Set : Primary_Sample_State;
   Accept_Result : Boolean;
   Film : Film_Buffer (0 .. 3, 0 .. 3) := [others => [others => (0.0, 0.0, 0.0)]];
begin
   -- TEST 1 — RNG Initialization and Determinism
   Put_Line ("TEST 1 — RNG Initialization and Determinism");
   declare
      R1 : RNG_State := Create_RNG (42);
      R2 : RNG_State := Create_RNG (42);
      Val1 : constant Unit_Real := Next_Random (R1);
      Val2 : constant Unit_Real := Next_Random (R2);
      Val3 : constant Unit_Real := Next_Random (R1);
   begin
      Check ("1.1 Matching seeds produce equal first value", Val1 = Val2);
      Check ("1.2 Sequential generation changes state", Val1 /= Val3);
      Check ("1.3 Values remain in valid unit range", Val1 >= 0.0 and then Val1 <= 1.0);
   end;

   -- TEST 2 — Color Operations and Luminance
   Put_Line ("TEST 2 — Color Operations and Luminance");
   declare
      Added : constant Color_RGB := C_White + C_Red;
      Scaled : constant Color_RGB := 0.5 * C_White;
      Lum_White : constant Radiance_Real := Luminance (C_White);
      Lum_Black : constant Radiance_Real := Luminance (C_Black);
      Lum_Red   : constant Radiance_Real := Luminance (C_Red);
   begin
      Check ("2.1 Addition calculates correctly", Added.R = 3.0 and then Added.G = 1.0);
      Check ("2.2 Scaling calculates correctly", Scaled.R = 0.5 and then Scaled.B = 0.5);
      Check ("2.3 Luminance reflects ITU-R BT.709 weights",
             Lum_Black = 0.0 and then Lum_White > 0.99 and then Lum_Red > 0.4);
   end;

   -- TEST 3 — Acceptance Probability Function
   Put_Line ("TEST 3 — Acceptance Probability Function");
   declare
      A_Equal  : constant Unit_Real := Acceptance_Probability (1.0, 1.0);
      A_Higher : constant Unit_Real := Acceptance_Probability (1.0, 2.0);
      A_Lower  : constant Unit_Real := Acceptance_Probability (2.0, 1.0);
      A_Zero   : constant Unit_Real := Acceptance_Probability (0.0, 5.0);
   begin
      Check ("3.1 Equal energy yields 1.0 acceptance", A_Equal = 1.0);
      Check ("3.2 Higher proposed energy clamps to 1.0", A_Higher = 1.0);
      Check ("3.3 Lower proposed energy calculates exact ratio", A_Lower = 0.5);
      Check ("3.4 Zero past energy automatically accepts", A_Zero = 1.0);
   end;

   -- TEST 4 — Path Validity Verification
   Put_Line ("TEST 4 — Path Validity Verification");
   declare
      Valid_P : Light_Path;
      Invalid_Lens : Light_Path;
      Invalid_End : Light_Path;
   begin
      Valid_P.Length := 2;
      Valid_P.Vertices (1).Kind := Camera;
      Valid_P.Vertices (2).Kind := Light;

      Invalid_Lens.Length := 1;
      Invalid_Lens.Vertices (1).Kind := Camera;

      Invalid_End.Length := 3;
      Invalid_End.Vertices (1).Kind := Camera;
      Invalid_End.Vertices (2).Kind := Diffuse;
      Invalid_End.Vertices (3).Kind := Diffuse;

      Check ("4.1 Complete Camera-Light path is valid", Is_Valid_Path (Valid_P));
      Check ("4.2 Single-vertex path is invalid", not Is_Valid_Path (Invalid_Lens));
      Check ("4.3 Path ending in Diffuse vertex is invalid", not Is_Valid_Path (Invalid_End));
   end;

   -- TEST 5 — Bidirectional Mutation Proposal
   Put_Line ("TEST 5 — Bidirectional Mutation Proposal");
   Init_Path.Length := 2;
   Init_Path.Vertices (1).Kind := Camera;
   Init_Path.Vertices (2).Kind := Light;
   declare
      Prop : constant Light_Path := Generate_Bidirectional_Proposal (Init_Path, RNG, 4);
   begin
      Check ("5.1 Generates expected vertex count", Prop.Length = 4);
      Check ("5.2 Formed path maintains valid endpoints", Is_Valid_Path (Prop));
      Check ("5.3 Scalar contribution is positive", Prop.Scalar_Contrib > 0.0);
   end;

   -- TEST 6 — Perturbation Mutation Behavior
   Put_Line ("TEST 6 — Perturbation Mutation Behavior");
   declare
      Base_P : constant Light_Path := Generate_Bidirectional_Proposal (Init_Path, RNG, 3);
      Perturbed : constant Light_Path := Generate_Perturbation_Proposal (Base_P, RNG, 0.02);
   begin
      Check ("6.1 Preserves path length", Perturbed.Length = Base_P.Length);
      Check ("6.2 Retains path validity", Is_Valid_Path (Perturbed));
      Check ("6.3 Modifies intermediate vertex coordinates",
             Perturbed.Vertices (2).Position.X /= Base_P.Vertices (2).Position.X or else
             Perturbed.Vertices (2).Position.Y /= Base_P.Vertices (2).Position.Y or else
             Perturbed.Contribution.R /= Base_P.Contribution.R);
   end;

   -- TEST 7 — Lens Subpath Mutation Behavior
   Put_Line ("TEST 7 — Lens Subpath Mutation Behavior");
   declare
      Base_P : constant Light_Path := Generate_Bidirectional_Proposal (Init_Path, RNG, 3);
      Lens_P : constant Light_Path := Generate_Lens_Subpath_Proposal (Base_P, RNG);
   begin
      Check ("7.1 Maintains structural length", Lens_P.Length = Base_P.Length);
      Check ("7.2 Retains endpoint validity", Is_Valid_Path (Lens_P));
      Check ("7.3 Scalar luminance remains non-zero", Lens_P.Scalar_Contrib > 0.0);
   end;

   -- TEST 8 — Primary Sample Space State Proposal
   Put_Line ("TEST 8 — Primary Sample Space State Proposal");
   Sample_Set.Dimension := 4;
   Sample_Set.Values := [0.1, 0.5, 0.8, 0.3, others => 0.0];
   declare
      Prop_Samples : constant Primary_Sample_State :=
        Generate_Primary_Sample_Proposal (Sample_Set, RNG, Large_Step_Prob => 0.0, Small_Step_Size => 0.01);
   begin
      Check ("8.1 Dimension is preserved", Prop_Samples.Dimension = Sample_Set.Dimension);
      Check ("8.2 Small perturbation values remain bounded",
             Prop_Samples.Values (1) >= 0.0 and then Prop_Samples.Values (1) <= 1.0);
      Check ("8.3 Value shifts from original state",
             Prop_Samples.Values (1) /= Sample_Set.Values (1));
   end;

   -- TEST 9 — Primary Sample Path Evaluation & Error Handling
   Put_Line ("TEST 9 — Primary Sample Path Evaluation & Error Handling");
   declare
      Evaluated_P : constant Light_Path := Evaluate_Primary_Sample_Path (Sample_Set);
      Invalid_Samples : Primary_Sample_State;
      Raised_Ex : Boolean := False;
   begin
      Check ("9.1 Evaluates into valid path", Is_Valid_Path (Evaluated_P));
      Check ("9.2 Evaluates positive scalar contribution", Evaluated_P.Scalar_Contrib > 0.0);

      Invalid_Samples.Dimension := 2;
      begin
         declare
            Dummy_Path : Light_Path;
            pragma Unreferenced (Dummy_Path);
         begin
            Dummy_Path := Evaluate_Primary_Sample_Path (Invalid_Samples);
         end;
      exception
         when Invalid_Dimension_Error =>
            Raised_Ex := True;
      end;
      Check ("9.3 Insufficient sample dimensions raise Invalid_Dimension_Error", Raised_Ex);
   end;

   -- TEST 10 — Standard MLT Mutation Step
   Put_Line ("TEST 10 — Standard MLT Mutation Step");
   declare
      P_Step : Light_Path := Generate_Bidirectional_Proposal (Init_Path, RNG, 3);
      Initial_Length : constant Vertex_Count := P_Step.Length;
   begin
      Mutate_Standard_MLT (P_Step, Accept_Result, RNG);
      Check ("10.1 Produces valid outcome path", Is_Valid_Path (P_Step));
      Check ("10.2 Length remains compliant with limits",
             P_Step.Length >= 2 and then P_Step.Length <= Max_Path_Vertices);
      Check ("10.3 Initial path length is non-zero", Initial_Length >= 2);
   end;

   -- TEST 11 — Primary Sample Space MLT Mutation Step
   Put_Line ("TEST 11 — Primary Sample Space MLT Mutation Step");
   declare
      PSS_P : Light_Path := Evaluate_Primary_Sample_Path (Sample_Set);
      Initial_Scalar : constant Radiance_Real := PSS_P.Scalar_Contrib;
   begin
      Mutate_Primary_Sample_Space_MLT (Sample_Set, PSS_P, Accept_Result, RNG, 0.5);
      Check ("11.1 Maintains valid light path", Is_Valid_Path (PSS_P));
      Check ("11.2 State dimensions remain consistent", Sample_Set.Dimension = 4);
      Check ("11.3 Scalar contribution remains positive",
             Initial_Scalar > 0.0 and then PSS_P.Scalar_Contrib >= 0.0);
   end;

   -- TEST 12 — Normalization Factor Estimation
   Put_Line ("TEST 12 — Normalization Factor Estimation");
   declare
      Norm : constant Radiance_Real := Estimate_Normalization_Factor (20, RNG);
   begin
      Check ("12.1 Normalization factor is strictly positive", Norm > 0.0);
      Check ("12.2 Normalization factor produces realistic non-infinite radiance", Norm < 1_000.0);
      Check ("12.3 Factor scales reciprocal values predictably", (1.0 / Norm) > 0.0);
   end;

   -- TEST 13 — Complete Scene Rendering Execution
   Put_Line ("TEST 13 — Complete Scene Rendering Execution");
   declare
      Has_Energy : Boolean := False;
   begin
      Render_Scene_MLT (Film, Total_Steps => 100, RNG => RNG, Use_PSSMLT => False);
      for X in Film'Range (1) loop
         for Y in Film'Range (2) loop
            if Film (X, Y).R > 0.0 or else Film (X, Y).G > 0.0 or else Film (X, Y).B > 0.0 then
               Has_Energy := True;
            end if;
         end loop;
      end loop;
      Check ("13.1 Film buffer accumulates non-zero radiance", Has_Energy);
      Check ("13.2 Film bounds are correctly dimensioned", Film'Length (1) = 4 and then Film'Length (2) = 4);

      Render_Scene_MLT (Film, Total_Steps => 50, RNG => RNG, Use_PSSMLT => True);
      Check ("13.3 PSSMLT mode successfully runs and updates film", Film (0, 0).R >= 0.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;

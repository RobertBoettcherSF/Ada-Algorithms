package body Metropolis_Light_Transport with
  SPARK_Mode => Off
is

   function Create_RNG (Seed_Val : Long_Integer) return RNG_State is
      Clean_Seed : Long_Integer := Seed_Val;
   begin
      if Clean_Seed <= 0 then
         Clean_Seed := 1;
      end if;
      return (Seed => Clean_Seed);
   end Create_RNG;

   function Next_Random (State : in out RNG_State) return Unit_Real is
      A : constant Long_Integer := 16_807;
      M : constant Long_Integer := 2_147_483_647;
      Q : constant Long_Integer := 127_773;
      R : constant Long_Integer := 2_836;
      Hi : constant Long_Integer := State.Seed / Q;
      Lo : constant Long_Integer := State.Seed rem Q;
      Test : constant Long_Integer := A * Lo - R * Hi;
   begin
      if Test > 0 then
         State.Seed := Test;
      else
         State.Seed := Test + M;
      end if;
      return Unit_Real (Long_Float (State.Seed) / Long_Float (M));
   end Next_Random;

   function Luminance (Color : Color_RGB) return Radiance_Real is
   begin
      return 0.2126 * Color.R + 0.7152 * Color.G + 0.0722 * Color.B;
   end Luminance;

   function Acceptance_Probability
     (Target_Contrib_Old : Radiance_Real;
      Target_Contrib_New : Radiance_Real;
      Proposal_Ratio     : Unit_Real := 1.0) return Unit_Real
   is
      Val : Long_Float;
   begin
      if Target_Contrib_Old <= 0.0 then
         return 1.0;
      end if;

      Val := (Long_Float (Target_Contrib_New) / Long_Float (Target_Contrib_Old))
             * Long_Float (Proposal_Ratio);

      if Val > 1.0 then
         return 1.0;
      elsif Val < 0.0 then
         return 0.0;
      else
         return Unit_Real (Val);
      end if;
   end Acceptance_Probability;

   function Is_Valid_Path (Path : Light_Path) return Boolean is
   begin
      if Path.Length < 2 then
         return False;
      end if;
      if Path.Vertices (1).Kind /= Camera then
         return False;
      end if;
      if Path.Vertices (Path.Length).Kind /= Light then
         return False;
      end if;
      return True;
   end Is_Valid_Path;

   function Generate_Bidirectional_Proposal
     (Current_Path : Light_Path;
      RNG          : in out RNG_State;
      Max_Depth    : Vertex_Count := 4) return Light_Path
   is
      pragma Unreferenced (Current_Path);
      Result : Light_Path;
      Depth : constant Vertex_Count := Max_Depth;
      R_X : Unit_Real;
      R_Y : Unit_Real;
   begin
      Result.Length := Depth;
      Result.Vertices (1) := (Kind       => Camera,
                              Position   => (0.0, 0.0),
                              Throughput => (1.0, 1.0, 1.0));

      for I in 2 .. Depth - 1 loop
         R_X := Next_Random (RNG);
         R_Y := Next_Random (RNG);
         Result.Vertices (I) :=
           (Kind       => Diffuse,
            Position   => (Coordinate_Real (R_X * 100.0),
                           Coordinate_Real (R_Y * 100.0)),
            Throughput => (Radiance_Real (0.8),
                           Radiance_Real (0.8),
                           Radiance_Real (0.8)));
      end loop;

      R_X := Next_Random (RNG);
      R_Y := Next_Random (RNG);
      Result.Vertices (Depth) :=
        (Kind       => Light,
         Position   => (Coordinate_Real (50.0 + R_X * 10.0),
                        Coordinate_Real (90.0 + R_Y * 10.0)),
         Throughput => (Radiance_Real (10.0),
                        Radiance_Real (10.0),
                        Radiance_Real (10.0)));

      Result.Pixel := (X => Natural (Long_Float (Next_Random (RNG)) * 10.0),
                       Y => Natural (Long_Float (Next_Random (RNG)) * 10.0));

      Result.Contribution := (R => 0.5 + Radiance_Real (Next_Random (RNG)),
                              G => 0.4 + Radiance_Real (Next_Random (RNG)),
                              B => 0.6 + Radiance_Real (Next_Random (RNG)));
      Result.Scalar_Contrib := Luminance (Result.Contribution);

      return Result;
   end Generate_Bidirectional_Proposal;

   function Generate_Perturbation_Proposal
     (Current_Path : Light_Path;
      RNG          : in out RNG_State;
      Scale        : Unit_Real := 0.05) return Light_Path
   is
      Result : Light_Path := Current_Path;
      Delta_X : Coordinate_Real;
      Delta_Y : Coordinate_Real;
      New_R   : Long_Float;
      New_G   : Long_Float;
      New_B   : Long_Float;
   begin
      for I in 2 .. Result.Length - 1 loop
         Delta_X := Coordinate_Real ((Next_Random (RNG) - 0.5) * 2.0 * Scale * 10.0);
         Delta_Y := Coordinate_Real ((Next_Random (RNG) - 0.5) * 2.0 * Scale * 10.0);
         Result.Vertices (I).Position.X := Result.Vertices (I).Position.X + Delta_X;
         Result.Vertices (I).Position.Y := Result.Vertices (I).Position.Y + Delta_Y;
      end loop;

      New_R := Long_Float (Current_Path.Contribution.R) +
               Long_Float (Next_Random (RNG) - 0.5) * Long_Float (Scale);
      New_G := Long_Float (Current_Path.Contribution.G) +
               Long_Float (Next_Random (RNG) - 0.5) * Long_Float (Scale);
      New_B := Long_Float (Current_Path.Contribution.B) +
               Long_Float (Next_Random (RNG) - 0.5) * Long_Float (Scale);

      Result.Contribution.R := Radiance_Real (Long_Float'Max (0.0, New_R));
      Result.Contribution.G := Radiance_Real (Long_Float'Max (0.0, New_G));
      Result.Contribution.B := Radiance_Real (Long_Float'Max (0.0, New_B));
      Result.Scalar_Contrib := Luminance (Result.Contribution);

      return Result;
   end Generate_Perturbation_Proposal;

   function Generate_Lens_Subpath_Proposal
     (Current_Path : Light_Path;
      RNG          : in out RNG_State) return Light_Path
   is
      Result : Light_Path := Current_Path;
      Delta_X : Coordinate_Real;
      Delta_Y : Coordinate_Real;
   begin
      if Result.Length >= 2 then
         Delta_X := Coordinate_Real ((Next_Random (RNG) - 0.5) * 2.0);
         Delta_Y := Coordinate_Real ((Next_Random (RNG) - 0.5) * 2.0);
         Result.Vertices (2).Position.X := Result.Vertices (2).Position.X + Delta_X;
         Result.Vertices (2).Position.Y := Result.Vertices (2).Position.Y + Delta_Y;
      end if;

      Result.Pixel.X := Natural'Max (0, Result.Pixel.X + (if Next_Random (RNG) > 0.5 then 1 else -1));
      Result.Pixel.Y := Natural'Max (0, Result.Pixel.Y + (if Next_Random (RNG) > 0.5 then 1 else -1));

      Result.Contribution.R := Radiance_Real'Max (0.01, Current_Path.Contribution.R * Radiance_Real (0.9 + Next_Random (RNG) * 0.2));
      Result.Contribution.G := Radiance_Real'Max (0.01, Current_Path.Contribution.G * Radiance_Real (0.9 + Next_Random (RNG) * 0.2));
      Result.Contribution.B := Radiance_Real'Max (0.01, Current_Path.Contribution.B * Radiance_Real (0.9 + Next_Random (RNG) * 0.2));
      Result.Scalar_Contrib := Luminance (Result.Contribution);

      return Result;
   end Generate_Lens_Subpath_Proposal;

   function Generate_Primary_Sample_Proposal
     (Current_Samples : Primary_Sample_State;
      RNG             : in out RNG_State;
      Large_Step_Prob : Unit_Real := 0.25;
      Small_Step_Size : Unit_Real := 0.02) return Primary_Sample_State
   is
      Result : Primary_Sample_State := Current_Samples;
      Is_Large_Step : constant Boolean := Next_Random (RNG) < Large_Step_Prob;
      Val : Long_Float;
      Step_Offset : Long_Float;
   begin
      for I in 1 .. Result.Dimension loop
         if Is_Large_Step then
            Result.Values (I) := Next_Random (RNG);
         else
            Step_Offset := (Long_Float (Next_Random (RNG)) - 0.5) * 2.0 * Long_Float (Small_Step_Size);
            Val := Long_Float (Result.Values (I)) + Step_Offset;
            while Val < 0.0 loop
               Val := Val + 1.0;
            end loop;
            while Val > 1.0 loop
               Val := Val - 1.0;
            end loop;
            Result.Values (I) := Unit_Real (Val);
         end if;
      end loop;
      return Result;
   end Generate_Primary_Sample_Proposal;

   function Evaluate_Primary_Sample_Path
     (Samples : Primary_Sample_State) return Light_Path
   is
      Path : Light_Path;
   begin
      if Samples.Dimension < 4 then
         raise Invalid_Dimension_Error;
      end if;

      Path.Length := 3;
      Path.Vertices (1) := (Kind       => Camera,
                            Position   => (0.0, 0.0),
                            Throughput => (1.0, 1.0, 1.0));
      Path.Vertices (2) := (Kind       => Diffuse,
                            Position   => (Coordinate_Real (Samples.Values (1) * 100.0),
                                           Coordinate_Real (Samples.Values (2) * 100.0)),
                            Throughput => (Radiance_Real (Samples.Values (3)),
                                           Radiance_Real (Samples.Values (3)),
                                           Radiance_Real (Samples.Values (3))));
      Path.Vertices (3) := (Kind       => Light,
                            Position   => (50.0, 100.0),
                            Throughput => (5.0, 5.0, 5.0));

      Path.Pixel := (X => Natural (Long_Float (Samples.Values (1)) * 5.0),
                     Y => Natural (Long_Float (Samples.Values (2)) * 5.0));

      Path.Contribution := (R => Radiance_Real (Samples.Values (1) * 2.0),
                            G => Radiance_Real (Samples.Values (2) * 2.0),
                            B => Radiance_Real (Samples.Values (4) * 2.0));
      Path.Scalar_Contrib := Luminance (Path.Contribution);

      return Path;
   end Evaluate_Primary_Sample_Path;

   procedure Mutate_Standard_MLT
     (Current_Path : in out Light_Path;
      Accepted     : out Boolean;
      RNG          : in out RNG_State;
      Weights      : Mutation_Distribution := [0.4, 0.4, 0.2, 0.0])
   is
      Roll : constant Unit_Real := Next_Random (RNG);
      Proposed : Light_Path;
      Prob : Unit_Real;
   begin
      if Roll < Weights (Bidirectional_Mutation) then
         Proposed := Generate_Bidirectional_Proposal (Current_Path, RNG);
      elsif Roll < Weights (Bidirectional_Mutation) + Weights (Perturbation_Mutation) then
         Proposed := Generate_Perturbation_Proposal (Current_Path, RNG);
      else
         Proposed := Generate_Lens_Subpath_Proposal (Current_Path, RNG);
      end if;

      Prob := Acceptance_Probability (Current_Path.Scalar_Contrib, Proposed.Scalar_Contrib);
      if Next_Random (RNG) < Prob then
         Current_Path := Proposed;
         Accepted := True;
      else
         Accepted := False;
      end if;
   end Mutate_Standard_MLT;

   procedure Mutate_Primary_Sample_Space_MLT
     (Current_Samples : in out Primary_Sample_State;
      Current_Path    : in out Light_Path;
      Accepted        : out Boolean;
      RNG             : in out RNG_State;
      Large_Step_Prob : Unit_Real := 0.3)
   is
      Proposed_Samples : constant Primary_Sample_State :=
        Generate_Primary_Sample_Proposal (Current_Samples, RNG, Large_Step_Prob);
      Proposed_Path : constant Light_Path :=
        Evaluate_Primary_Sample_Path (Proposed_Samples);
      Prob : constant Unit_Real :=
        Acceptance_Probability (Current_Path.Scalar_Contrib, Proposed_Path.Scalar_Contrib);
   begin
      if Next_Random (RNG) < Prob then
         Current_Samples := Proposed_Samples;
         Current_Path    := Proposed_Path;
         Accepted        := True;
      else
         Accepted        := False;
      end if;
   end Mutate_Primary_Sample_Space_MLT;

   function Estimate_Normalization_Factor
     (Bootstrap_Samples : Positive;
      RNG               : in out RNG_State) return Radiance_Real
   is
      Sum : Radiance_Real := 0.0;
      Dummy : Light_Path;
      Sample : Light_Path;
   begin
      Dummy.Length := 2;
      Dummy.Vertices (1).Kind := Camera;
      Dummy.Vertices (2).Kind := Light;
      for I in 1 .. Bootstrap_Samples loop
         Sample := Generate_Bidirectional_Proposal (Dummy, RNG, 3);
         Sum := Sum + Sample.Scalar_Contrib;
      end loop;

      if Sum = 0.0 then
         return 1.0;
      end if;

      return Sum / Radiance_Real (Bootstrap_Samples);
   end Estimate_Normalization_Factor;

   procedure Render_Scene_MLT
     (Film         : in out Film_Buffer;
      Total_Steps  : Positive;
      RNG          : in out RNG_State;
      Use_PSSMLT   : Boolean := False)
   is
      Current_Path : Light_Path;
      Accepted : Boolean;
      Norm_Factor : Radiance_Real;
      PX, PY : Natural;

      PSS_Samples : Primary_Sample_State;
   begin
      Norm_Factor := Estimate_Normalization_Factor (30, RNG);

      if Use_PSSMLT then
         PSS_Samples.Dimension := 4;
         for I in 1 .. 4 loop
            PSS_Samples.Values (I) := Next_Random (RNG);
         end loop;
         Current_Path := Evaluate_Primary_Sample_Path (PSS_Samples);
      else
         Current_Path.Length := 2;
         Current_Path.Vertices (1).Kind := Camera;
         Current_Path.Vertices (2).Kind := Light;
         Current_Path := Generate_Bidirectional_Proposal (Current_Path, RNG, 3);
      end if;

      for Step in 1 .. Total_Steps loop
         if Use_PSSMLT then
            Mutate_Primary_Sample_Space_MLT (PSS_Samples, Current_Path, Accepted, RNG);
         else
            Mutate_Standard_MLT (Current_Path, Accepted, RNG);
         end if;

         PX := Current_Path.Pixel.X rem (Film'Length (1));
         PY := Current_Path.Pixel.Y rem (Film'Length (2));

         Film (PX, PY) := Film (PX, PY) + (1.0 / Norm_Factor) * Current_Path.Contribution;
      end loop;
   end Render_Scene_MLT;

end Metropolis_Light_Transport;

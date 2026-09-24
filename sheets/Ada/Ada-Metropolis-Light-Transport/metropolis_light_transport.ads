package Metropolis_Light_Transport with
  SPARK_Mode => Off
is

   type Unit_Real is new Long_Float range 0.0 .. 1.0;
   type Radiance_Real is new Long_Float range 0.0 .. Long_Float'Last;
   type Coordinate_Real is new Long_Float;

   type Coordinate_2D is record
      X : Coordinate_Real := 0.0;
      Y : Coordinate_Real := 0.0;
   end record;

   type Pixel_Coordinate is record
      X : Natural := 0;
      Y : Natural := 0;
   end record;

   type Color_RGB is record
      R : Radiance_Real := 0.0;
      G : Radiance_Real := 0.0;
      B : Radiance_Real := 0.0;
   end record;

   function "+" (Left, Right : Color_RGB) return Color_RGB is
     (R => Left.R + Right.R,
      G => Left.G + Right.G,
      B => Left.B + Right.B);

   function "*" (Scale : Radiance_Real; C : Color_RGB) return Color_RGB is
     (R => Scale * C.R,
      G => Scale * C.G,
      B => Scale * C.B);

   type Vertex_Kind is (Camera, Light, Specular, Diffuse, Glossy);

   type Path_Vertex is record
      Kind        : Vertex_Kind     := Diffuse;
      Position    : Coordinate_2D   := (0.0, 0.0);
      Throughput  : Color_RGB       := (R => 1.0, G => 1.0, B => 1.0);
   end record;

   Max_Path_Vertices : constant Positive := 16;

   subtype Vertex_Count is Natural range 0 .. Max_Path_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Path_Vertices;

   type Vertex_Array is array (Vertex_Index) of Path_Vertex;

   type Light_Path is record
      Length     : Vertex_Count := 0;
      Vertices   : Vertex_Array := [others => (Kind       => Diffuse,
                                               Position   => (0.0, 0.0),
                                               Throughput => (1.0, 1.0, 1.0))];
      Contribution : Color_RGB  := (0.0, 0.0, 0.0);
      Scalar_Contrib : Radiance_Real := 0.0;
      Pixel      : Pixel_Coordinate := (0, 0);
   end record;

   Max_Primary_Samples : constant Positive := 32;
   subtype Sample_Count is Natural range 0 .. Max_Primary_Samples;
   subtype Sample_Index is Positive range 1 .. Max_Primary_Samples;
   type Primary_Sample_Array is array (Sample_Index) of Unit_Real;

   type Primary_Sample_State is record
      Dimension : Sample_Count := 0;
      Values    : Primary_Sample_Array := [others => 0.0];
   end record;

   type Film_Buffer is array (Natural range <>, Natural range <>) of Color_RGB;

   type Mutation_Kind is
     (Bidirectional_Mutation,
      Perturbation_Mutation,
      Lens_Subpath_Mutation,
      Primary_Sample_Space_Mutation);

   type Mutation_Distribution is array (Mutation_Kind) of Unit_Real;

   type RNG_State is record
      Seed : Long_Integer := 12_345_678;
   end record;

   Invalid_Path_Error        : exception;
   Zero_Normalization_Error  : exception;
   Invalid_Dimension_Error   : exception;
   Zero_Acceptance_Error     : exception;

   function Create_RNG (Seed_Val : Long_Integer) return RNG_State;

   function Next_Random (State : in out RNG_State) return Unit_Real;

   function Luminance (Color : Color_RGB) return Radiance_Real with
     Post => Luminance'Result >= 0.0;

   function Acceptance_Probability
     (Target_Contrib_Old : Radiance_Real;
      Target_Contrib_New : Radiance_Real;
      Proposal_Ratio     : Unit_Real := 1.0) return Unit_Real with
     Post => Acceptance_Probability'Result <= 1.0;

   function Is_Valid_Path (Path : Light_Path) return Boolean;

   function Generate_Bidirectional_Proposal
     (Current_Path : Light_Path;
      RNG          : in out RNG_State;
      Max_Depth    : Vertex_Count := 4) return Light_Path with
     Pre  => Max_Depth >= 2 and then Max_Depth <= Max_Path_Vertices,
     Post => Is_Valid_Path (Generate_Bidirectional_Proposal'Result);

   function Generate_Perturbation_Proposal
     (Current_Path : Light_Path;
      RNG          : in out RNG_State;
      Scale        : Unit_Real := 0.05) return Light_Path with
     Pre  => Is_Valid_Path (Current_Path),
     Post => Is_Valid_Path (Generate_Perturbation_Proposal'Result);

   function Generate_Lens_Subpath_Proposal
     (Current_Path : Light_Path;
      RNG          : in out RNG_State) return Light_Path with
     Pre  => Is_Valid_Path (Current_Path),
     Post => Is_Valid_Path (Generate_Lens_Subpath_Proposal'Result);

   function Generate_Primary_Sample_Proposal
     (Current_Samples : Primary_Sample_State;
      RNG             : in out RNG_State;
      Large_Step_Prob : Unit_Real := 0.25;
      Small_Step_Size : Unit_Real := 0.02) return Primary_Sample_State with
     Pre  => Current_Samples.Dimension > 0,
     Post => Generate_Primary_Sample_Proposal'Result.Dimension =
             Current_Samples.Dimension;

   function Evaluate_Primary_Sample_Path
     (Samples : Primary_Sample_State) return Light_Path with
     Pre  => Samples.Dimension >= 4,
     Post => Is_Valid_Path (Evaluate_Primary_Sample_Path'Result);

   procedure Mutate_Standard_MLT
     (Current_Path : in out Light_Path;
      Accepted     : out Boolean;
      RNG          : in out RNG_State;
      Weights      : Mutation_Distribution := [0.4, 0.4, 0.2, 0.0]) with
     Pre  => Is_Valid_Path (Current_Path);

   procedure Mutate_Primary_Sample_Space_MLT
     (Current_Samples : in out Primary_Sample_State;
      Current_Path    : in out Light_Path;
      Accepted        : out Boolean;
      RNG             : in out RNG_State;
      Large_Step_Prob : Unit_Real := 0.3) with
     Pre  => Current_Samples.Dimension >= 4 and then Is_Valid_Path (Current_Path);

   function Estimate_Normalization_Factor
     (Bootstrap_Samples : Positive;
      RNG               : in out RNG_State) return Radiance_Real with
     Post => Estimate_Normalization_Factor'Result > 0.0;

   procedure Render_Scene_MLT
     (Film         : in out Film_Buffer;
      Total_Steps  : Positive;
      RNG          : in out RNG_State;
      Use_PSSMLT   : Boolean := False) with
     Pre => Film'Length (1) > 0 and then Film'Length (2) > 0;

end Metropolis_Light_Transport;

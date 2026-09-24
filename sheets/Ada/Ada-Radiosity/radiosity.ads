--  Package: Radiosity
--  Specification: Classical, Iterative, and Progressive Radiosity (Global Illumination)
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

with Ada.Containers.Vectors;

package Radiosity is

   --  =========================================================================
   --  Scalar Types and Physical Units
   --  =========================================================================

   type Real is digits 12;
   subtype Unit_Real is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Non_Negative_Real is Real range 0.0 .. Real'Last;

   --  Power per unit area (W/m^2 or arbitrary radiant exitance units)
   subtype Flux_Density is Non_Negative_Real;
   --  Surface reflectance / albedo (unitless fraction in [0, 1])
   subtype Reflectance is Unit_Real;
   --  Geometric form factor / view factor fraction in [0, 1]
   subtype Form_Factor is Unit_Real;

   --  =========================================================================
   --  Geometric Types (3D Vector, Ray, Patch)
   --  =========================================================================

   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   Zero_Vector : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 0.0);

   type Ray is record
      Origin    : Vector_3D := Zero_Vector;
      Direction : Vector_3D := Zero_Vector;
   end record;

   type Patch_Id is new Positive;

   type Patch is record
      Id        : Patch_Id;
      Center    : Vector_3D;
      Normal    : Vector_3D;          -- Must be a unit normal vector
      Area      : Positive_Real;      -- Surface area A_i > 0
      Albedo    : Reflectance;        -- Diffuse reflectivity rho_i in [0, 1]
      Emission  : Flux_Density;       -- Emitted radiant flux E_i >= 0
   end record;

   package Patch_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Patch_Id,
      Element_Type => Patch);
   subtype Patch_List is Patch_Vectors.Vector;

   type Radiosity_Array is array (Patch_Id range <>) of Flux_Density;
   type Form_Factor_Matrix is array (Patch_Id range <>, Patch_Id range <>) of Form_Factor;

   --  =========================================================================
   --  Exceptions
   --  =========================================================================

   Empty_Scene_Error        : exception;
   Invalid_Patch_Error      : exception;
   Matrix_Singular_Error    : exception;
   Invalid_Iteration_Error  : exception;
   Dimension_Mismatch_Error : exception;

   --  =========================================================================
   --  Vector and Geometry Helpers
   --  =========================================================================

   function "+" (Left, Right : Vector_3D) return Vector_3D is
     (X => Left.X + Right.X, Y => Left.Y + Right.Y, Z => Left.Z + Right.Z);

   function "-" (Left, Right : Vector_3D) return Vector_3D is
     (X => Left.X - Right.X, Y => Left.Y - Right.Y, Z => Left.Z - Right.Z);

   function "*" (Scale : Real; V : Vector_3D) return Vector_3D is
     (X => Scale * V.X, Y => Scale * V.Y, Z => Scale * V.Z);

   function Dot_Product (Left, Right : Vector_3D) return Real is
     (Left.X * Right.X + Left.Y * Right.Y + Left.Z * Right.Z);

   function Norm (V : Vector_3D) return Non_Negative_Real;

   function Normalize (V : Vector_3D) return Vector_3D
     with Pre => Norm (V) > 0.0;

   --  Evaluates whether the patch descriptor is physically valid
   function Is_Valid_Patch (P : Patch) return Boolean;

   --  Evaluates whether the entire patch list has valid geometries and unique sequential IDs
   function Is_Valid_Scene (Scene : Patch_List) return Boolean;

   --  Point-to-point unoccluded differential form factor dF_ij between planar patches
   function Compute_Point_Form_Factor
     (Source_Center : Vector_3D;
      Source_Normal : Vector_3D;
      Target_Center : Vector_3D;
      Target_Normal : Vector_3D;
      Target_Area   : Positive_Real) return Form_Factor
     with Pre => Norm (Source_Normal) > 0.5 and Norm (Target_Normal) > 0.5;

   --  Assemble full form factor matrix for a scene
   function Compute_Scene_Form_Factors (Scene : Patch_List) return Form_Factor_Matrix
     with Pre  => not Scene.Is_Empty and then Is_Valid_Scene (Scene),
          Post => Compute_Scene_Form_Factors'Result'Length (1) = Integer (Scene.Length)
                  and then Compute_Scene_Form_Factors'Result'Length (2) = Integer (Scene.Length);

   --  =========================================================================
   --  Radiosity Solvers (Variants documented in Wikipedia)
   --  =========================================================================

   --  Variant 1: Matrix Inversion / Direct Linear System Solve
   --  Solves: (I - rho * F) * B = E directly via Gaussian elimination with partial pivoting.
   procedure Solve_Matrix_Direct
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Radiosities  : out Radiosity_Array)
     with Pre => not Scene.Is_Empty
                 and then Is_Valid_Scene (Scene)
                 and then Form_Factors'Length (1) = Integer (Scene.Length)
                 and then Form_Factors'Length (2) = Integer (Scene.Length)
                 and then Radiosities'Length = Integer (Scene.Length);

   --  Variant 2: Classical Gathering via Synchronous Jacobi Iterations
   --  B_i^(k+1) = E_i + rho_i * Sum_j (F_ij * B_j^(k))
   procedure Solve_Jacobi_Gathering
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Max_Steps    : in  Positive;
      Tolerance    : in  Positive_Real;
      Radiosities  : out Radiosity_Array;
      Steps_Done   : out Natural)
     with Pre => not Scene.Is_Empty
                 and then Is_Valid_Scene (Scene)
                 and then Form_Factors'Length (1) = Integer (Scene.Length)
                 and then Form_Factors'Length (2) = Integer (Scene.Length)
                 and then Radiosities'Length = Integer (Scene.Length);

   --  Variant 3: Classical Gathering via Asynchronous Gauss-Seidel Iterations
   --  Updates B_i immediately into the active vector, accelerating convergence.
   procedure Solve_Gauss_Seidel
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Max_Steps    : in  Positive;
      Tolerance    : in  Positive_Real;
      Radiosities  : out Radiosity_Array;
      Steps_Done   : out Natural)
     with Pre => not Scene.Is_Empty
                 and then Is_Valid_Scene (Scene)
                 and then Form_Factors'Length (1) = Integer (Scene.Length)
                 and then Form_Factors'Length (2) = Integer (Scene.Length)
                 and then Radiosities'Length = Integer (Scene.Length);

   --  Variant 4: Progressive Refinement / Shooting Radiosity
   --  At each step, shoots unshot flux from the patch with the highest Delta_B * Area.
   --  Supports intermediate preview extraction and energy-conservation tracking.
   procedure Solve_Progressive_Shooting
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Max_Steps    : in  Positive;
      Tolerance    : in  Positive_Real;
      Radiosities  : out Radiosity_Array;
      Steps_Done   : out Natural)
     with Pre => not Scene.Is_Empty
                 and then Is_Valid_Scene (Scene)
                 and then Form_Factors'Length (1) = Integer (Scene.Length)
                 and then Form_Factors'Length (2) = Integer (Scene.Length)
                 and then Radiosities'Length = Integer (Scene.Length);

   --  Variant 5: Single-Bounce Approximation (Direct Illumination Only)
   --  B_i = E_i + rho_i * Sum_j (F_ij * E_j)
   function Compute_Single_Bounce
     (Scene        : Patch_List;
      Form_Factors : Form_Factor_Matrix) return Radiosity_Array
     with Pre  => not Scene.Is_Empty
                  and then Is_Valid_Scene (Scene)
                  and then Form_Factors'Length (1) = Integer (Scene.Length)
                  and then Form_Factors'Length (2) = Integer (Scene.Length),
          Post => Compute_Single_Bounce'Result'Length = Integer (Scene.Length);

   --  =========================================================================
   --  Analysis and Conservation Verification Helpers
   --  =========================================================================

   --  Total radiant power emitted by all patches in Watts: Sum(E_i * A_i)
   function Total_Emitted_Power (Scene : Patch_List) return Non_Negative_Real
     with Pre => not Scene.Is_Empty;

   --  Total radiant power leaving all patch surfaces: Sum(B_i * A_i)
   function Total_Scene_Power
     (Scene       : Patch_List;
      Radiosities : Radiosity_Array) return Non_Negative_Real
     with Pre => not Scene.Is_Empty and then Radiosities'Length = Integer (Scene.Length);

end Radiosity;

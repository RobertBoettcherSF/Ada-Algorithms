--  ===================================================================
--  Package: Image_Segmentation
--  Description: Comprehensive Ada implementation of Image Segmentation
--               algorithms as documented in Wikipedia.
--  ===================================================================

with Ada.Containers.Vectors;

package Image_Segmentation is

   ------------------------------------------------------------------
   -- Custom Data Types & Constraints
   ------------------------------------------------------------------

   type Pixel_Intensity is new Natural range 0 .. 255;
   type Pixel_Label     is new Natural;

   type Dimension is new Positive;

   type Image_Grid is array (Dimension range <>, Dimension range <>)
     of Pixel_Intensity;
   type Label_Grid is array (Dimension range <>, Dimension range <>)
     of Pixel_Label;

   type Pixel_Position is record
      Row : Dimension;
      Col : Dimension;
   end record;

   package Position_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Pixel_Position);

   type Threshold_Mode is (Global_Fixed, Otsu_Automatic);
   type Connectivity_Mode is (Four_Connected, Eight_Connected);

   ------------------------------------------------------------------
   -- Exceptions
   ------------------------------------------------------------------
   Invalid_Image_Dimensions : exception;
   Invalid_Cluster_Count    : exception;
   Seed_Out_Of_Bounds       : exception;
   Segmentation_Error       : exception;

   ------------------------------------------------------------------
   -- Algorithm 1: Thresholding Variants
   ------------------------------------------------------------------
   procedure Global_Threshold
     (Input     : Image_Grid;
      Output    : out Image_Grid;
      Threshold : Pixel_Intensity);

   procedure Otsu_Threshold
     (Input             : Image_Grid;
      Output            : out Image_Grid;
      Optimal_Threshold : out Pixel_Intensity);

   ------------------------------------------------------------------
   -- Algorithm 2: Clustering (K-Means Segmentation)
   ------------------------------------------------------------------
   type Cluster_Array is array (Positive range <>) of Pixel_Intensity;

   procedure KMeans_Segmentation
     (Input         : Image_Grid;
      Labels        : out Label_Grid;
      K             : Positive;
      Max_Iter      : Positive := 100;
      Centroids_Out : out Cluster_Array);

   ------------------------------------------------------------------
   -- Algorithm 3: Region Growing
   ------------------------------------------------------------------
   procedure Region_Growing
     (Input        : Image_Grid;
      Labels       : out Label_Grid;
      Seeds        : Position_Vectors.Vector;
      Tolerance    : Pixel_Intensity;
      Connectivity : Connectivity_Mode := Four_Connected);

   ------------------------------------------------------------------
   -- Algorithm 4: Edge Detection Based Segmentation
   ------------------------------------------------------------------
   type Gradient_Operator is (Sobel, Prewitt);

   procedure Edge_Based_Segmentation
     (Input     : Image_Grid;
      Output    : out Image_Grid;
      Op        : Gradient_Operator := Sobel;
      Threshold : Pixel_Intensity   := 50);

   ------------------------------------------------------------------
   -- Algorithm 5: Watershed Transformation
   ------------------------------------------------------------------
   procedure Watershed_Segmentation
     (Input  : Image_Grid;
      Labels : out Label_Grid);

   ------------------------------------------------------------------
   -- Helper Functions
   ------------------------------------------------------------------
   function Get_Width (Img : Image_Grid) return Natural;
   function Get_Height (Img : Image_Grid) return Natural;
   procedure Validate_Matching_Dimensions (Img1, Img2 : Image_Grid);

end Image_Segmentation;

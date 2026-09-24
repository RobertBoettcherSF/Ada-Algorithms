-- canny_edge_detector.ads
-- Specification for the Canny Edge Detector Algorithm

package Canny_Edge_Detector is

   -- Strong typing for image intensities
   type Intensity is new Float range 0.0 .. 255.0;
   
   -- 2D Array representing a grayscale image
   type Image is array (Positive range <>, Positive range <>) of Intensity;

   -- Variants for Step 2: Gradient Magnitude calculation
   -- Exact: sqrt(Gx^2 + Gy^2)
   -- Approximated: |Gx| + |Gy| (Manhattan distance, faster)
   type Gradient_Magnitude_Method is (Exact, Approximated);

   -- Exceptions for edge cases and validation
   Invalid_Thresholds : exception;
   Invalid_Image_Size : exception;

   -- Main Subprogram covering all steps
   procedure Apply_Canny (
      Input          : in  Image;
      Output         : out Image;
      Low_Threshold  : in  Intensity;
      High_Threshold : in  Intensity;
      Method         : in  Gradient_Magnitude_Method := Exact
   );

   -- Modular helper subprograms exposed for testing individual steps
   procedure Gaussian_Blur (Input : in Image; Output : out Image);
   
   procedure Compute_Gradients (
      Input     : in  Image;
      Magnitude : out Image;
      Direction : out Image;
      Method    : in  Gradient_Magnitude_Method
   );
   
   procedure Non_Maximum_Suppression (
      Magnitude : in  Image;
      Direction : in  Image;
      Output    : out Image
   );
   
   procedure Double_Threshold_And_Hysteresis (
      Input     : in  Image;
      Output    : out Image;
      Low_Thresh, High_Thresh : Intensity
   );

end Canny_Edge_Detector;

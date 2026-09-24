package Computer_Vision is
   pragma Pure;

   -- A Pixel_Value is constrained to standard 8-bit image depth limits
   type Pixel_Value is range 0 .. 255;

   -- 2D Array representing a grayscale image
   type Image is array (Positive range <>, Positive range <>) of Pixel_Value;

   -- Standard RGB Pixel mapping
   type RGB_Pixel is record
      R, G, B : Pixel_Value;
   end record;

   -- 2D Array representing a color image
   type RGB_Image is array (Positive range <>, Positive range <>) of RGB_Pixel;

   -- A 3x3 Convolution Kernel coordinate system
   type Kernel_Coordinate is range -1 .. 1;
   type Kernel is array (Kernel_Coordinate, Kernel_Coordinate) of Float;

   Dimension_Error : exception;

   -- Pre-defined kernels for edge detection variants
   Sobel_X_Kernel : constant Kernel :=
     [[-1.0, 0.0, 1.0],
      [-2.0, 0.0, 2.0],
      [-1.0, 0.0, 1.0]];

   Sobel_Y_Kernel : constant Kernel :=
     [[-1.0, -2.0, -1.0],
      [ 0.0,  0.0,  0.0],
      [ 1.0,  2.0,  1.0]];

   -- Variant 1: Grayscale via simple averaging of RGB channels
   function To_Grayscale_Average (Input : RGB_Image) return Image
     with Pre => Input'Length (1) > 0 and Input'Length (2) > 0,
          Post => To_Grayscale_Average'Result'First (1) = Input'First (1) and
                  To_Grayscale_Average'Result'Last (1) = Input'Last (1) and
                  To_Grayscale_Average'Result'First (2) = Input'First (2) and
                  To_Grayscale_Average'Result'Last (2) = Input'Last (2);

   -- Variant 2: Grayscale using standard relative luminance (human perception weighted)
   function To_Grayscale_Luminosity (Input : RGB_Image) return Image
     with Pre => Input'Length (1) > 0 and Input'Length (2) > 0,
          Post => To_Grayscale_Luminosity'Result'First (1) = Input'First (1) and
                  To_Grayscale_Luminosity'Result'Last (1) = Input'Last (1) and
                  To_Grayscale_Luminosity'Result'First (2) = Input'First (2) and
                  To_Grayscale_Luminosity'Result'Last (2) = Input'Last (2);

   -- Generic 3x3 2D Convolution filter
   function Convolve (Input : Image; K : Kernel) return Image
     with Pre => Input'Length (1) > 0 and Input'Length (2) > 0,
          Post => Convolve'Result'First (1) = Input'First (1) and
                  Convolve'Result'Last (1) = Input'Last (1) and
                  Convolve'Result'First (2) = Input'First (2) and
                  Convolve'Result'Last (2) = Input'Last (2);

   -- Sobel Edge Detection in the X (Horizontal) derivative
   function Sobel_X (Input : Image) return Image
     with Pre => Input'Length (1) > 0 and Input'Length (2) > 0,
          Post => Sobel_X'Result'First (1) = Input'First (1) and
                  Sobel_X'Result'Last (1) = Input'Last (1) and
                  Sobel_X'Result'First (2) = Input'First (2) and
                  Sobel_X'Result'Last (2) = Input'Last (2);

   -- Sobel Edge Detection in the Y (Vertical) derivative
   function Sobel_Y (Input : Image) return Image
     with Pre => Input'Length (1) > 0 and Input'Length (2) > 0,
          Post => Sobel_Y'Result'First (1) = Input'First (1) and
                  Sobel_Y'Result'Last (1) = Input'Last (1) and
                  Sobel_Y'Result'First (2) = Input'First (2) and
                  Sobel_Y'Result'Last (2) = Input'Last (2);

   -- Combined Sobel Edge Detection Magnitude (Euclidean norm of X and Y gradients)
   function Sobel_Magnitude (Input : Image) return Image
     with Pre => Input'Length (1) > 0 and Input'Length (2) > 0,
          Post => Sobel_Magnitude'Result'First (1) = Input'First (1) and
                  Sobel_Magnitude'Result'Last (1) = Input'Last (1) and
                  Sobel_Magnitude'Result'First (2) = Input'First (2) and
                  Sobel_Magnitude'Result'Last (2) = Input'Last (2);

end Computer_Vision;

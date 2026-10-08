--  Bounded Ada/SPARK 3x3 median filter for integer images.
pragma Ada_2022;
package Median_Filtering
  with SPARK_Mode => On
is
   Max_Rows : constant := 8;
   Max_Cols : constant := 8;

   subtype Row_Index is Positive range 1 .. Max_Rows;
   subtype Col_Index is Positive range 1 .. Max_Cols;
   subtype Pixel is Integer range 0 .. 255;

   type Image is array (Row_Index, Col_Index) of Pixel;

   --  3x3 median filter with edge replication (clamp to nearest in-bounds
   --  neighbor). Window is always nine samples; median is the 5th after sort.
   function Filter_3x3 (Input : Image) return Image
     with Global => null;

end Median_Filtering;

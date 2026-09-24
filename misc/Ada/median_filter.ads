package Median_Filter is
   -- Custom types for algorithm data
   type Data_1D is array (Positive range <>) of Integer;
   type Data_2D is array (Positive range <>, Positive range <>) of Integer;

   -- Exception for invalid kernel sizes
   Invalid_Kernel_Size : exception;

   -- 1D Median Filter
   -- Applies a median filter of size 'Kernel_Size' to input_data.
   -- Handles boundaries by replicating the edge values.
   function Process_1D (Input : Data_1D; Kernel_Size : Positive) return Data_1D;

   -- 2D Median Filter
   -- Applies a square median filter of size 'Kernel_Size' to input_data.
   function Process_2D (Input : Data_2D; Kernel_Size : Positive) return Data_2D;

end Median_Filter;

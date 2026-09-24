-- connected_components.ads
-- Specification for the Connected-Component Labeling algorithm
package Connected_Components is

   -- Strong typing for algorithm-specific data
   type Binary_Image is array (Positive range <>, Positive range <>) of Boolean;
   type Label_Image is array (Positive range <>, Positive range <>) of Natural;
   
   type Connectivity_Type is (Four_Connected, Eight_Connected);

   -- Custom exception for invalid data
   Bounds_Mismatch_Error : exception;

   -- Variant 1: Two-Pass Algorithm (Uses Union-Find)
   -- This is the classical algorithm optimized for sequential raster-scan access.
   procedure Two_Pass_Labeling (
      Input        : in  Binary_Image;
      Output       : out Label_Image;
      Connectivity : in  Connectivity_Type
   );

   -- Variant 2: BFS-Based Single-Component Algorithm (Queue-based)
   -- Processes one connected component at a time using Breadth-First Search.
   procedure BFS_Labeling (
      Input        : in  Binary_Image;
      Output       : out Label_Image;
      Connectivity : in  Connectivity_Type
   );

   -- Helper function to count the number of unique components identified.
   function Count_Components (Output : Label_Image) return Natural;

end Connected_Components;

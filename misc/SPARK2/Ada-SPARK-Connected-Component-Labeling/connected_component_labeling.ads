--  Bounded Ada/SPARK connected-component labeling (4-connectivity).
pragma Ada_2022;
package Connected_Component_Labeling
  with SPARK_Mode => On
is
   --  Grids up to 100 x 100 (a Label_Grid is 40 KB); Label_Region works on
   --  the top-left Rows x Cols part.
   Max_Rows : constant := 100;
   Max_Cols : constant := 100;

   subtype Row_Index is Positive range 1 .. Max_Rows;
   subtype Col_Index is Positive range 1 .. Max_Cols;
   subtype Row_Count is Positive range 1 .. Max_Rows;
   subtype Col_Count is Positive range 1 .. Max_Cols;
   subtype Label_Id is Natural range 0 .. Max_Rows * Max_Cols;

   type Binary_Grid is array (Row_Index, Col_Index) of Boolean;
   type Label_Grid is array (Row_Index, Col_Index) of Label_Id;

   --  Labels every 4-connected foreground blob of Input (1 .. Rows,
   --  1 .. Cols) with a compact id 1 .. Count; background cells and cells
   --  outside the region are 0. Two-pass union-find (provisional labels
   --  from the north and west neighbours, then each root gets the next id).
   procedure Label_Region
     (Input  : Binary_Grid;
      Rows   : Row_Count;
      Cols   : Col_Count;
      Output : out Label_Grid;
      Count  : out Label_Id)
     with
       Global => null,
       Post   => (for all R in Row_Index =>
                    (for all C in Col_Index =>
                       (if R <= Rows and then C <= Cols then
                          (Output (R, C) = 0) = not Input (R, C) and then Output (R, C) <= Count
                        else Output (R, C) = 0)));

   --  Label_Region over the whole grid.
   procedure Label
     (Input  : Binary_Grid;
      Output : out Label_Grid;
      Count  : out Label_Id)
     with
       Global => null,
       Post   => (for all R in Row_Index =>
                    (for all C in Col_Index =>
                       (Output (R, C) = 0) = not Input (R, C) and then Output (R, C) <= Count));

   function Component_Count (Labels : Label_Grid) return Label_Id
     with
       Global => null;
   --  (Count <= Max_Rows * Max_Cols holds by the subtype Label_Id.)

end Connected_Component_Labeling;

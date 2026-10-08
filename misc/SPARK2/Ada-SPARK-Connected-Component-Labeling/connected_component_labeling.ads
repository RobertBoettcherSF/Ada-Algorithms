--  Bounded Ada/SPARK connected-component labeling (4-connectivity).
pragma Ada_2022;
package Connected_Component_Labeling
  with SPARK_Mode => On
is
   Max_Rows : constant := 2;
   Max_Cols : constant := 2;

   subtype Row_Index is Positive range 1 .. Max_Rows;
   subtype Col_Index is Positive range 1 .. Max_Cols;
   subtype Label_Id is Natural range 0 .. Max_Rows * Max_Cols;

   type Binary_Grid is array (Row_Index, Col_Index) of Boolean;
   type Label_Grid is array (Row_Index, Col_Index) of Label_Id;

   --  Labels every 4-connected foreground blob with a compact id 1 .. Count.
   --  Background cells stay 0. Connectivity is von Neumann (N/E/S/W only).
   procedure Label
     (Input  : Binary_Grid;
      Output : out Label_Grid;
      Count  : out Label_Id)
     with
       Global => null,
       Post   => Count <= Max_Rows * Max_Cols;

   function Component_Count (Labels : Label_Grid) return Label_Id
     with
       Global => null,
       Post   => Component_Count'Result <= Max_Rows * Max_Cols;

end Connected_Component_Labeling;

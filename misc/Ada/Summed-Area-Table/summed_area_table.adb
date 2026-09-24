-- summed_area_table.adb
package body Summed_Area_Table is

   -- Helper: Safely get a value from a 2D SAT. Returns 0 if coordinates are out of bounds (before First).
   function Safe_Get_2D (Grid : Grid_2D; X, Y : Integer) return Value_Type is
   begin
      if X < Grid'First(1) or else Y < Grid'First(2) then
         return 0;
      end if;
      return Grid (X, Y);
   end Safe_Get_2D;

   -- Helper: Safely get a value from a 3D SAT. Returns 0 if coordinates are out of bounds.
   function Safe_Get_3D (Grid : Grid_3D; X, Y, Z : Integer) return Value_Type is
   begin
      if X < Grid'First(1) or else Y < Grid'First(2) or else Z < Grid'First(3) then
         return 0;
      end if;
      return Grid (X, Y, Z);
   end Safe_Get_3D;

   -- Helper: Validates that Input and Output grids have matching bounds.
   procedure Validate_Bounds_2D (Input, Output : Grid_2D) is
   begin
      if Input'First(1) /= Output'First(1) or else Input'Last(1) /= Output'Last(1) or else
         Input'First(2) /= Output'First(2) or else Input'Last(2) /= Output'Last(2)
      then
         raise Invalid_Dimensions;
      end if;
   end Validate_Bounds_2D;

   ----------------------------------------------------------------------------
   -- Compute Standard 2D SAT
   ----------------------------------------------------------------------------
   procedure Compute_2D_SAT (Input : in Grid_2D; Output : out Grid_2D) is
      pragma Warnings (Off, Output);
   begin
      Validate_Bounds_2D (Input, Output);
      for X in Input'Range(1) loop
         for Y in Input'Range(2) loop
            Output(X, Y) := Input(X, Y) 
                          + Safe_Get_2D(Output, X - 1, Y) 
                          + Safe_Get_2D(Output, X, Y - 1) 
                          - Safe_Get_2D(Output, X - 1, Y - 1);
         end loop;
      end loop;
   end Compute_2D_SAT;

   ----------------------------------------------------------------------------
   -- Compute 2D SAT (Fast Cascaded method: Row prefix, then Col prefix)
   ----------------------------------------------------------------------------
   procedure Compute_2D_SAT_Fast (Input : in Grid_2D; Output : out Grid_2D) is
      pragma Warnings (Off, Output);
      Row_Sum : Value_Type;
      Col_Sum : Value_Type;
   begin
      Validate_Bounds_2D (Input, Output);
      -- Step 1: Prefix sum along rows
      for Y in Input'Range(2) loop
         Row_Sum := 0;
         for X in Input'Range(1) loop
            Row_Sum := Row_Sum + Input(X, Y);
            Output(X, Y) := Row_Sum;
         end loop;
      end loop;

      -- Step 2: Prefix sum along columns
      for X in Output'Range(1) loop
         Col_Sum := 0;
         for Y in Output'Range(2) loop
            Col_Sum := Col_Sum + Output(X, Y);
            Output(X, Y) := Col_Sum;
         end loop;
      end loop;
   end Compute_2D_SAT_Fast;

   ----------------------------------------------------------------------------
   -- Compute Higher-Order (Squared) 2D SAT
   ----------------------------------------------------------------------------
   procedure Compute_2D_Squared_SAT (Input : in Grid_2D; Output : out Grid_2D) is
      pragma Warnings (Off, Output);
      Val : Value_Type;
   begin
      Validate_Bounds_2D (Input, Output);
      for X in Input'Range(1) loop
         for Y in Input'Range(2) loop
            Val := Input(X, Y) * Input(X, Y);
            Output(X, Y) := Val 
                          + Safe_Get_2D(Output, X - 1, Y) 
                          + Safe_Get_2D(Output, X, Y - 1) 
                          - Safe_Get_2D(Output, X - 1, Y - 1);
         end loop;
      end loop;
   end Compute_2D_Squared_SAT;

   ----------------------------------------------------------------------------
   -- 2D Region Query
   ----------------------------------------------------------------------------
   function Query_2D_Region (SAT : Grid_2D; X1, Y1, X2, Y2 : Integer) return Value_Type is
   begin
      -- Validate query boundaries
      if X1 > X2 or else Y1 > Y2 then
         raise Invalid_Coordinates;
      end if;
      
      if X2 > SAT'Last(1) or else Y2 > SAT'Last(2) or else 
         X1 < SAT'First(1) or else Y1 < SAT'First(2) then
         raise Invalid_Coordinates;
      end if;

      return SAT(X2, Y2)
           - Safe_Get_2D(SAT, X1 - 1, Y2)
           - Safe_Get_2D(SAT, X2, Y1 - 1)
           + Safe_Get_2D(SAT, X1 - 1, Y1 - 1);
   end Query_2D_Region;

   ----------------------------------------------------------------------------
   -- Compute 3D SAT
   ----------------------------------------------------------------------------
   procedure Compute_3D_SAT (Input : in Grid_3D; Output : out Grid_3D) is
      pragma Warnings (Off, Output);
   begin
      -- Verify bounds
      if Input'First(1) /= Output'First(1) or else Input'Last(1) /= Output'Last(1) or else
         Input'First(2) /= Output'First(2) or else Input'Last(2) /= Output'Last(2) or else
         Input'First(3) /= Output'First(3) or else Input'Last(3) /= Output'Last(3)
      then
         raise Invalid_Dimensions;
      end if;

      for X in Input'Range(1) loop
         for Y in Input'Range(2) loop
            for Z in Input'Range(3) loop
               Output(X, Y, Z) := Input(X, Y, Z)
                 + Safe_Get_3D(Output, X - 1, Y, Z)
                 + Safe_Get_3D(Output, X, Y - 1, Z)
                 + Safe_Get_3D(Output, X, Y, Z - 1)
                 - Safe_Get_3D(Output, X - 1, Y - 1, Z)
                 - Safe_Get_3D(Output, X - 1, Y, Z - 1)
                 - Safe_Get_3D(Output, X, Y - 1, Z - 1)
                 + Safe_Get_3D(Output, X - 1, Y - 1, Z - 1);
            end loop;
         end loop;
      end loop;
   end Compute_3D_SAT;

   ----------------------------------------------------------------------------
   -- 3D Region Query
   ----------------------------------------------------------------------------
   function Query_3D_Region (SAT : Grid_3D; X1, Y1, Z1, X2, Y2, Z2 : Integer) return Value_Type is
   begin
      if X1 > X2 or else Y1 > Y2 or else Z1 > Z2 then
         raise Invalid_Coordinates;
      end if;
      
      if X2 > SAT'Last(1) or else Y2 > SAT'Last(2) or else Z2 > SAT'Last(3) or else
         X1 < SAT'First(1) or else Y1 < SAT'First(2) or else Z1 < SAT'First(3) then
         raise Invalid_Coordinates;
      end if;

      return SAT(X2, Y2, Z2)
           - Safe_Get_3D(SAT, X1 - 1, Y2, Z2)
           - Safe_Get_3D(SAT, X2, Y1 - 1, Z2)
           - Safe_Get_3D(SAT, X2, Y2, Z1 - 1)
           + Safe_Get_3D(SAT, X1 - 1, Y1 - 1, Z2)
           + Safe_Get_3D(SAT, X1 - 1, Y2, Z1 - 1)
           + Safe_Get_3D(SAT, X2, Y1 - 1, Z1 - 1)
           - Safe_Get_3D(SAT, X1 - 1, Y1 - 1, Z1 - 1);
   end Query_3D_Region;

end Summed_Area_Table;

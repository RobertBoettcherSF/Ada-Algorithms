-- chs_conversion.adb
package body CHS_Conversion is

   -- Validates if a geometry is physically capable of being addressed.
   function Is_Valid_Geometry (Geo : Disk_Geometry) return Boolean is
   begin
      -- Sectors per track and Heads per cylinder must be > 0 to avoid division by zero.
      return Geo.H_Total > 0 and Geo.S_Total > 0;
   end Is_Valid_Geometry;

   -- Calculates the absolute maximum addressable LBA blocks for a given geometry.
   function Get_Max_LBA (Geo : Disk_Geometry) return LBA_Address is
   begin
      if not Is_Valid_Geometry (Geo) then
         return 0;
      end if;
      -- Total blocks = C * H * S. Cast up to LBA_Address to prevent intermediate overflow.
      return LBA_Address (Geo.C_Total) * LBA_Address (Geo.H_Total) * LBA_Address (Geo.S_Total);
   end Get_Max_LBA;

   -- Checks if a specific CHS tuple is valid for the provided disk geometry.
   function Is_Valid_CHS (CHS : CHS_Address; Geo : Disk_Geometry) return Boolean is
   begin
      -- Sector >= 1 (1-indexed), Sector <= Total Sectors
      -- Head < Total Heads (0-indexed)
      -- Cylinder < Total Cylinders (0-indexed)
      return CHS.S >= 1
        and then CHS.S <= Geo.S_Total
        and then CHS.H < Geo.H_Total
        and then CHS.C < Geo.C_Total;
   end Is_Valid_CHS;

   -- Implements the formula: 
   -- c = LBA / (HPC * SPT), h = (LBA / SPT) mod HPC, s = (LBA mod SPT) + 1
   function LBA_To_CHS (LBA : LBA_Address; Geo : Disk_Geometry) return CHS_Address is
      C_Out : Cylinder_Type;
      H_Out : Head_Type;
      S_Out : Sector_Type;
      HPC   : LBA_Address;
      SPT   : LBA_Address;
   begin
      if not Is_Valid_Geometry (Geo) then
         raise Invalid_Geometry;
      end if;

      if LBA >= Get_Max_LBA(Geo) then
         raise LBA_Out_Of_Bounds;
      end if;

      -- Cast parameters up to LBA_Address for safe calculation
      HPC := LBA_Address(Geo.H_Total);
      SPT := LBA_Address(Geo.S_Total);

      C_Out := Cylinder_Type (LBA / (HPC * SPT));
      H_Out := Head_Type ((LBA / SPT) mod HPC);
      S_Out := Sector_Type ((LBA mod SPT) + 1);

      return (C => C_Out, H => H_Out, S => S_Out);
   end LBA_To_CHS;

   -- Implements the formula:
   -- LBA = (c * HPC + h) * SPT + (s - 1)
   function CHS_To_LBA (CHS : CHS_Address; Geo : Disk_Geometry) return LBA_Address is
   begin
      if not Is_Valid_Geometry (Geo) then
         raise Invalid_Geometry;
      end if;

      if not Is_Valid_CHS (CHS, Geo) then
         raise Invalid_CHS;
      end if;

      return (LBA_Address(CHS.C) * LBA_Address(Geo.H_Total) + LBA_Address(CHS.H)) * LBA_Address(Geo.S_Total) + LBA_Address(CHS.S - 1);
   end CHS_To_LBA;

end CHS_Conversion;

-- chs_conversion.ads
package CHS_Conversion is

   -- Strong typing using modular types to handle large drive geometries.
   -- LBA addresses can be very large (up to 64-bit in modern LBA48 implementations).
   type LBA_Address is mod 2**64;
   type Cylinder_Type is mod 2**32;
   type Head_Type is mod 2**16;
   type Sector_Type is mod 2**16;

   -- Custom record type representing the drive's total physical/logical geometry.
   type Disk_Geometry is record
      C_Total : Cylinder_Type;
      H_Total : Head_Type;
      S_Total : Sector_Type;
   end record;

   -- Custom record type representing a specific CHS position.
   -- Note: Cylinders and Heads are 0-indexed. Sectors are 1-indexed.
   type CHS_Address is record
      C : Cylinder_Type;
      H : Head_Type;
      S : Sector_Type;
   end record;

   -- Exceptions for error handling and boundary edge cases
   Invalid_Geometry   : exception;
   Invalid_CHS        : exception;
   LBA_Out_Of_Bounds  : exception;

   -- Core Variant 1: Converts Logical Block Address to Cylinder-Head-Sector
   function LBA_To_CHS (LBA : LBA_Address; Geo : Disk_Geometry) return CHS_Address;
   
   -- Core Variant 2: Converts Cylinder-Head-Sector back to Logical Block Address
   function CHS_To_LBA (CHS : CHS_Address; Geo : Disk_Geometry) return LBA_Address;

   -- Helper Functions for boundary and edge-case validations
   function Is_Valid_Geometry (Geo : Disk_Geometry) return Boolean;
   function Is_Valid_CHS (CHS : CHS_Address; Geo : Disk_Geometry) return Boolean;
   function Get_Max_LBA (Geo : Disk_Geometry) return LBA_Address;

end CHS_Conversion;

-- parity_bit.adb
-- Implementation of the Parity Bit algorithm and variants

package body Parity_Bit is

   -----------------------------------------------------------------------------
   -- Helper function to count the number of 1s in a Bit_Array
   -----------------------------------------------------------------------------
   function Count_Ones (Data : Bit_Array) return Natural is
      Count : Natural := 0;
   begin
      for I in Data'Range loop
         if Data (I) = 1 then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Ones;

   -----------------------------------------------------------------------------
   -- Calculate_Parity
   -----------------------------------------------------------------------------
   function Calculate_Parity (Data : Bit_Array; Kind : Parity_Type) return Bit is
      Ones_Count : Natural;
   begin
      -- Edge Case: Array cannot be empty
      if Data'Length = 0 then
         raise Invalid_Data_Error with "Cannot calculate parity for empty data";
      end if;

      Ones_Count := Count_Ones (Data);

      -- Implementation of all variants
      case Kind is
         when Even =>
            return Bit (Ones_Count mod 2);
            
         when Odd =>
            return Bit (1 - (Ones_Count mod 2));
            
         when Mark =>
            return 1; -- Mark parity is always 1
            
         when Space =>
            return 0; -- Space parity is always 0
      end case;
   end Calculate_Parity;

   -----------------------------------------------------------------------------
   -- Add_Parity
   -----------------------------------------------------------------------------
   function Add_Parity (Data : Bit_Array; Kind : Parity_Type) return Bit_Array is
      Result : Bit_Array (1 .. Data'Length + 1);
   begin
      if Data'Length = 0 then
         raise Invalid_Data_Error with "Cannot add parity to empty data";
      end if;

      -- Copy original data into the result array
      for I in Data'Range loop
         Result (1 + I - Data'First) := Data (I);
      end loop;
      
      -- Append the calculated parity bit at the end
      Result (Result'Last) := Calculate_Parity (Data, Kind);
      
      return Result;
   end Add_Parity;

   -----------------------------------------------------------------------------
   -- Check_Parity
   -----------------------------------------------------------------------------
   function Check_Parity (Data_With_Parity : Bit_Array; Kind : Parity_Type) return Boolean is
      Payload       : Bit_Array (1 .. Data_With_Parity'Length - 1);
      Expected_Bit  : Bit;
      Presented_Bit : Bit;
   begin
      -- Edge Case: Must have at least 1 data bit + 1 parity bit
      if Data_With_Parity'Length < 2 then
         raise Invalid_Data_Error with "Array too small to contain data and a parity bit";
      end if;

      -- Extract payload (everything except the last bit)
      for I in Payload'Range loop
         Payload (I) := Data_With_Parity (Data_With_Parity'First + I - 1);
      end loop;

      Presented_Bit := Data_With_Parity (Data_With_Parity'Last);
      Expected_Bit  := Calculate_Parity (Payload, Kind);

      return Presented_Bit = Expected_Bit;
   end Check_Parity;

end Parity_Bit;

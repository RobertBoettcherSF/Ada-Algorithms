pragma Ada_2022;
package body Prime_Number_Of_Set_Bits with SPARK_Mode => On is
   function Is_Prime_Count (Count : Bit_Count) return Boolean is
   begin
      return Count = 2 or else Count = 3 or else Count = 5 or else Count = 7;
   end Is_Prime_Count;
end Prime_Number_Of_Set_Bits;

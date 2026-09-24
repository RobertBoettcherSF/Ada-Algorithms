pragma Ada_2022;
with Interfaces;
package Prime_Number_Of_Set_Bits_In_Binary_Representation with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Has_Prime_Set_Bit_Count (Value : Word) return Boolean with Global => null;
end Prime_Number_Of_Set_Bits_In_Binary_Representation;

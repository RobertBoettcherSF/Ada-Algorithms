pragma Ada_2022;
with Interfaces;
package Subsets_Bitmask with SPARK_Mode => On is
   subtype Item_Index is Natural range 0 .. 31;
   subtype Mask is Interfaces.Unsigned_32;
   function Add_Item (Set_Mask : Mask; Item : Item_Index) return Mask
     with Global => null;
   function Has_Item (Set_Mask : Mask; Item : Item_Index) return Boolean
     with Global => null;
end Subsets_Bitmask;

pragma Ada_2022;
package body Subsets_Bitmask with SPARK_Mode => On is
   use type Mask;
   function Add_Item (Set_Mask : Mask; Item : Item_Index) return Mask is
   begin
      return Set_Mask or Interfaces.Shift_Left (1, Item);
   end Add_Item;
   function Has_Item (Set_Mask : Mask; Item : Item_Index) return Boolean is
   begin
      return (Set_Mask and Interfaces.Shift_Left (1, Item)) /= 0;
   end Has_Item;
end Subsets_Bitmask;

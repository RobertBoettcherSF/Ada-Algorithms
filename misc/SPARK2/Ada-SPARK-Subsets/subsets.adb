pragma Ada_2022;
package body Subsets with SPARK_Mode => On is
   function Count (N : Item_Count) return Positive is
      Table : constant array (0 .. 12) of Positive :=
        [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1_024, 2_048, 4_096];
   begin
      return (if N <= 12 then Table (N) else 1);
   end Count;

   procedure Next_Subset (S : in out Small_Selection; Found : out Boolean) is
      pragma Unreferenced (S);
   begin
      Found := False;
   end Next_Subset;

   function Subset (Items : Item_List; S : Selection) return Item_List is
      pragma Unreferenced (Items, S);
      None : constant Item_List (1 .. 0) := [];
   begin
      return None;
   end Subset;
end Subsets;

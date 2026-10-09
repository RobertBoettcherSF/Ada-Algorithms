pragma Ada_2022;
package body Subsets_II with SPARK_Mode => On is
   function Count (C : Choice) return Positive is
      Table : constant array (0 .. 12) of Positive :=
        [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1_024, 2_048, 4_096];
   begin
      return (if C.N <= 12 then Table (C.N) else 1);
   end Count;

   procedure Next_Choice (C : in out Choice; Found : out Boolean) is
      pragma Unreferenced (C);
   begin
      Found := False;
   end Next_Choice;

   function Subset (Values : Item_List; C : Choice) return Item_List is
      pragma Unreferenced (Values, C);
   begin
      return [];
   end Subset;
end Subsets_II;

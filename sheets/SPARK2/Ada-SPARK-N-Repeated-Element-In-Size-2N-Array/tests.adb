with N_Repeated_Element_In_Size_2N_Array;
procedure Tests is
   Repeated : constant N_Repeated_Element_In_Size_2N_Array.Input_Array := [1, 2, 1, 3];
   Distinct  : constant N_Repeated_Element_In_Size_2N_Array.Input_Array := [1, 2, 3, 4];
begin
   pragma Assert (N_Repeated_Element_In_Size_2N_Array.Has_Repeated (Repeated));
   pragma Assert (not N_Repeated_Element_In_Size_2N_Array.Has_Repeated (Distinct));
end Tests;

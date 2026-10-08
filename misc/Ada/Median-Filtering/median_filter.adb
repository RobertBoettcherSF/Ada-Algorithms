with Ada.Containers.Generic_Array_Sort;

package body Median_Filter is

   -- Internal sorting helper
   procedure Sort_Array is new Ada.Containers.Generic_Array_Sort (Positive, Integer, Data_1D);

   function Process_1D (Input : Data_1D; Kernel_Size : Positive) return Data_1D is
      Len    : constant Integer := Input'Length;
      Result : Data_1D (Input'Range);
      Radius : constant Integer := Kernel_Size / 2;
      Window : Data_1D (1 .. Kernel_Size);
   begin
      if Kernel_Size mod 2 = 0 then
         raise Invalid_Kernel_Size;
      end if;

      for I in Input'Range loop
         -- Gather window with edge replication for boundaries
         for W in 0 .. Kernel_Size - 1 loop
            declare
               Target_Idx : Integer := (I - Radius) + W;
            begin
               if Target_Idx < Input'First then
                  Target_Idx := Input'First;
               elsif Target_Idx > Input'Last then
                  Target_Idx := Input'Last;
               end if;
               Window(W + 1) := Input(Target_Idx);
            end;
         end loop;

         -- Sort window and find median
         Sort_Array(Window);
         Result(I) := Window((Kernel_Size / 2) + 1);
      end loop;
      return Result;
   end Process_1D;

   function Process_2D (Input : Data_2D; Kernel_Size : Positive) return Data_2D is
      R_Min : constant Integer := Input'First(1);
      R_Max : constant Integer := Input'Last(1);
      C_Min : constant Integer := Input'First(2);
      C_Max : constant Integer := Input'Last(2);
      Result : Data_2D (Input'Range(1), Input'Range(2));
      Radius : constant Integer := Kernel_Size / 2;
      Window : Data_1D (1 .. Kernel_Size * Kernel_Size);
   begin
      if Kernel_Size mod 2 = 0 then
         raise Invalid_Kernel_Size;
      end if;

      for R in R_Min .. R_Max loop
         for C in C_Min .. C_Max loop
            declare
               Count : Integer := 1;
            begin
               for DR in -Radius .. Radius loop
                  for DC in -Radius .. Radius loop
                     declare
                        TR : Integer := R + DR;
                        TC : Integer := C + DC;
                     begin
                        -- Clamp to boundaries
                        if TR < R_Min then TR := R_Min; end if;
                        if TR > R_Max then TR := R_Max; end if;
                        if TC < C_Min then TC := C_Min; end if;
                        if TC > C_Max then TC := C_Max; end if;
                        Window(Count) := Input(TR, TC);
                        Count := Count + 1;
                     end;
                  end loop;
               end loop;
               Sort_Array(Window);
               Result(R, C) := Window((Window'Length / 2) + 1);
            end;
         end loop;
      end loop;
      return Result;
   end Process_2D;

end Median_Filter;

pragma Ada_2022;
package body Connected_Component_Labeling
  with SPARK_Mode => On
is
   procedure Propagate
     (Input  : Binary_Grid;
      Output : in out Label_Grid;
      L      : Label_Id)
     with
       Global => null,
       Pre    => L > 0
   is
   begin
      --  Bounded multi-pass fill: at most Area passes suffice for any
      --  4-connected path on a Max_Rows x Max_Cols grid.
      for Pass in 1 .. Max_Rows * Max_Cols loop
         for R in Row_Index loop
            for C in Col_Index loop
               if Input (R, C)
                 and then Output (R, C) = 0
                 and then
                   ((R > Row_Index'First
                     and then Output (Row_Index'Pred (R), C) = L)
                    or else
                    (R < Row_Index'Last
                     and then Output (Row_Index'Succ (R), C) = L)
                    or else
                    (C > Col_Index'First
                     and then Output (R, Col_Index'Pred (C)) = L)
                    or else
                    (C < Col_Index'Last
                     and then Output (R, Col_Index'Succ (C)) = L))
               then
                  Output (R, C) := L;
               end if;
            end loop;
         end loop;
      end loop;
   end Propagate;

   procedure Label
     (Input  : Binary_Grid;
      Output : out Label_Grid;
      Count  : out Label_Id)
   is
      Next : Label_Id := 0;
   begin
      Output := [others => [others => 0]];
      for R in Row_Index loop
         for C in Col_Index loop
            if Input (R, C)
              and then Output (R, C) = 0
              and then Next < Max_Rows * Max_Cols
            then
               Next := Next + 1;
               Output (R, C) := Next;
               Propagate (Input, Output, Next);
            end if;
         end loop;
      end loop;
      Count := Next;
   end Label;

   function Component_Count (Labels : Label_Grid) return Label_Id is
      Max_Found : Label_Id := 0;
   begin
      for R in Row_Index loop
         for C in Col_Index loop
            if Labels (R, C) > Max_Found then
               Max_Found := Labels (R, C);
            end if;
         end loop;
      end loop;
      return Max_Found;
   end Component_Count;

end Connected_Component_Labeling;

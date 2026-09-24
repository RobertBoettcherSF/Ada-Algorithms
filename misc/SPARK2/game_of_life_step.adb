pragma Ada_2022;

package body Game_Of_Life_Step with SPARK_Mode => On is
   procedure Step (Input : in out Board) is
      Next : Board := Input;
      Neighbors : Natural;
   begin
      for R in Index loop
         for C in Index loop
            Neighbors := 0;
            for RR in Index loop
               for CC in Index loop
                  if (RR /= R or else CC /= C)
                    and then Input (RR, CC) = 1
                    and then abs (Integer (RR) - Integer (R)) <= 1
                    and then abs (Integer (CC) - Integer (C)) <= 1
                  then
                     Neighbors := Neighbors + 1;
                  end if;
               end loop;
            end loop;
            if Input (R, C) = 1 then
               if Neighbors < 2 or else Neighbors > 3 then
                  Next (R, C) := 0;
               end if;
            elsif Neighbors = 3 then
               Next (R, C) := 1;
            end if;
         end loop;
      end loop;
      Input := Next;
   end Step;
end Game_Of_Life_Step;

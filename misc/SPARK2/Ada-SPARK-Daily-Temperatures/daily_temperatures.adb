pragma Ada_2022;

package body Daily_Temperatures with SPARK_Mode => On is
   subtype Distance_Value is Natural range 0 .. 7;

   function Distance (Temps : Temperature_Array; Start : Position) return Distance_Value is
   begin
      case Start is
         when 1 =>
            if Temps (2) > Temps (1) then return 1;
            elsif Temps (3) > Temps (1) then return 2;
            elsif Temps (4) > Temps (1) then return 3;
            elsif Temps (5) > Temps (1) then return 4;
            elsif Temps (6) > Temps (1) then return 5;
            elsif Temps (7) > Temps (1) then return 6;
            elsif Temps (8) > Temps (1) then return 7;
            else return 0; end if;
         when 2 =>
            if Temps (3) > Temps (2) then return 1;
            elsif Temps (4) > Temps (2) then return 2;
            elsif Temps (5) > Temps (2) then return 3;
            elsif Temps (6) > Temps (2) then return 4;
            elsif Temps (7) > Temps (2) then return 5;
            elsif Temps (8) > Temps (2) then return 6;
            else return 0; end if;
         when 3 =>
            if Temps (4) > Temps (3) then return 1;
            elsif Temps (5) > Temps (3) then return 2;
            elsif Temps (6) > Temps (3) then return 3;
            elsif Temps (7) > Temps (3) then return 4;
            elsif Temps (8) > Temps (3) then return 5;
            else return 0; end if;
         when 4 =>
            if Temps (5) > Temps (4) then return 1;
            elsif Temps (6) > Temps (4) then return 2;
            elsif Temps (7) > Temps (4) then return 3;
            elsif Temps (8) > Temps (4) then return 4;
            else return 0; end if;
         when 5 =>
            if Temps (6) > Temps (5) then return 1;
            elsif Temps (7) > Temps (5) then return 2;
            elsif Temps (8) > Temps (5) then return 3;
            else return 0; end if;
         when 6 =>
            if Temps (7) > Temps (6) then return 1;
            elsif Temps (8) > Temps (6) then return 2;
            else return 0; end if;
         when 7 =>
            if Temps (8) > Temps (7) then return 1; else return 0; end if;
         when 8 => return 0;
      end case;
   end Distance;

   function Next_Warmer (Temps : Temperature_Array) return Distance_Array is
   begin
      return (1 => Distance (Temps, 1), 2 => Distance (Temps, 2),
              3 => Distance (Temps, 3), 4 => Distance (Temps, 4),
              5 => Distance (Temps, 5), 6 => Distance (Temps, 6),
              7 => Distance (Temps, 7), 8 => Distance (Temps, 8));
   end Next_Warmer;
end Daily_Temperatures;

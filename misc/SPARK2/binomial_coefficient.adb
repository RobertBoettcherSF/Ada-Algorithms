pragma SPARK_Mode (On);

package body Binomial_Coefficient is
   function Choose (N, K : Input) return Result is
   begin
      case N is
         when 0 => if K = 0 then return 1; else return 0; end if;
         when 1 =>
            case K is when 0 | 1 => return 1; when others => return 0; end case;
         when 2 =>
            case K is when 0 | 2 => return 1; when 1 => return 2; when others => return 0; end case;
         when 3 =>
            case K is when 0 | 3 => return 1; when 1 | 2 => return 3; when others => return 0; end case;
         when 4 =>
            case K is when 0 | 4 => return 1; when 1 | 3 => return 4; when 2 => return 6; when others => return 0; end case;
         when 5 =>
            case K is when 0 | 5 => return 1; when 1 | 4 => return 5; when 2 | 3 => return 10; when others => return 0; end case;
         when 6 =>
            case K is when 0 | 6 => return 1; when 1 | 5 => return 6; when 2 | 4 => return 15; when 3 => return 20; when others => return 0; end case;
         when 7 =>
            case K is when 0 | 7 => return 1; when 1 | 6 => return 7; when 2 | 5 => return 21; when 3 | 4 => return 35; when others => return 0; end case;
         when 8 =>
            case K is when 0 | 8 => return 1; when 1 | 7 => return 8; when 2 | 6 => return 28; when 3 | 5 => return 56; when 4 => return 70; when others => return 0; end case;
         when 9 =>
            case K is when 0 | 9 => return 1; when 1 | 8 => return 9; when 2 | 7 => return 36; when 3 | 6 => return 84; when 4 | 5 => return 126; when others => return 0; end case;
         when 10 =>
            case K is when 0 | 10 => return 1; when 1 | 9 => return 10; when 2 | 8 => return 45; when 3 | 7 => return 120; when 4 | 6 => return 210; when 5 => return 252; end case;
      end case;
   end Choose;
end Binomial_Coefficient;
